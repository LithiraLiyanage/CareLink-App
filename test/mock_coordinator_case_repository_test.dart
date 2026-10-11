import 'package:carelink_app/features/coordinator/models/case_audit_event.dart';
import 'package:carelink_app/features/coordinator/models/case_outcome.dart';
import 'package:carelink_app/features/coordinator/models/elder_consent_context.dart';
import 'package:carelink_app/features/coordinator/models/safety_case.dart';
import 'package:carelink_app/features/coordinator/services/coordinator_case_repository.dart';
import 'package:carelink_app/features/coordinator/services/mock_coordinator_case_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedNow = DateTime(2026, 9, 30, 10, 55);
  late MockCoordinatorCaseRepository repository;

  setUp(() => repository = MockCoordinatorCaseRepository(now: () => fixedNow));
  tearDown(() => repository.dispose());

  test('is a mock CoordinatorCaseRepository', () {
    expect(repository, isA<CoordinatorCaseRepository>());
    expect(repository.usesMockData, isTrue);
  });

  test('seeds the case-list examples with mock ids, in screen order', () async {
    final cases = await repository.watchCases().first;

    expect(cases.map((c) => c.elderDisplayName), [
      'Mrs. Silva',
      'Mr. Perera',
      'Ms. Fernando',
      'Ms. Jayasinghe',
    ]);
    expect(cases.map((c) => c.status), [
      SafetyCaseStatus.pendingReview,
      SafetyCaseStatus.retryRequested,
      SafetyCaseStatus.rescheduled,
      SafetyCaseStatus.contactFollowUp,
    ]);
    for (final safetyCase in cases) {
      expect(safetyCase.id, startsWith('mock_'));
      expect(safetyCase.elderId, startsWith('mock_'));
    }

    final silva = cases.first;
    expect(silva.caseLabel, 'Case #001');
    expect(silva.elderReference, 'EL001');
    expect(silva.elderRelationship, 'Mother');
    expect(silva.scheduledAt, DateTime(2026, 9, 30, 10, 30));
    expect(silva.previousAttempts, 1);
  });

  test('filter counts derive from the mock data', () async {
    final counts = SafetyCaseCounts.fromCases(
      await repository.watchCases().first,
    );
    expect(counts.all, MockCoordinatorCaseRepository.mockCases.length);
    expect(counts.pending, 4);
    expect(counts.closed, 0);
  });

  test('getCase returns a case or null', () async {
    expect(
      (await repository.getCase('mock_case_002'))?.elderDisplayName,
      'Mr. Perera',
    );
    expect(await repository.getCase('missing'), isNull);
  });

  group('consent context', () {
    test(
      'Mrs. Silva has the mock consent shown on the consent screen',
      () async {
        final context = await repository.getConsentContext('mock_case_001');

        expect(context, isNotNull);
        expect(context!.isMock, isTrue);
        expect(context.familySharing, ConsentSharingStatus.approved);
        expect(context.approvedContact?.displayLabel, 'Jane Silva (Daughter)');
        expect(context.validFrom, DateTime(2026, 1, 1));
        expect(context.lastUpdatedAt, DateTime(2026, 9, 15));
        expect(context.allowedInformation, [
          'Check-in status',
          'Schedule information',
          'General wellbeing status',
        ]);
        expect(context.restrictedInformation, ['Private conversation content']);
        expect(context.canContactApprovedPerson, isTrue);
      },
    );

    test('other elders have no consent invented for them', () async {
      for (final id in ['mock_case_002', 'mock_case_003', 'mock_case_004']) {
        final context = await repository.getConsentContext(id);
        expect(context!.familySharing, ConsentSharingStatus.notRecorded);
        expect(context.approvedContact, isNull);
        expect(context.canContactApprovedPerson, isFalse);
        expect(context.isMock, isTrue);
      }
    });

    test('unknown case has no consent context', () async {
      expect(await repository.getConsentContext('missing'), isNull);
    });
  });

  group('recordCaseAction', () {
    test('retry updates status, attempts, cases stream and audit', () async {
      final caseUpdates = repository.watchCases().take(2).toList();
      final auditUpdates = repository
          .watchAuditEvents('mock_case_001')
          .take(2)
          .toList();
      await Future<void>.delayed(Duration.zero);

      final updated = await repository.recordCaseAction(
        caseId: 'mock_case_001',
        action: CaseAction.retryCheckIn,
        note: '  Called again  ',
      );

      expect(updated.status, SafetyCaseStatus.retryRequested);
      expect(updated.previousAttempts, 2);

      final cases = await caseUpdates;
      expect(cases.first.first.status, SafetyCaseStatus.pendingReview);
      expect(cases.last.first.status, SafetyCaseStatus.retryRequested);

      final timeline = (await auditUpdates).last;
      expect(timeline.map((e) => e.type), [
        CaseAuditEventType.checkInMissed,
        CaseAuditEventType.retryRequested,
      ]);
      expect(timeline.first.actor, CaseAuditActor.system);
      expect(timeline.last.actor, CaseAuditActor.coordinator);
      expect(timeline.last.occurredAt, fixedNow);
      expect(timeline.last.note, 'Called again');
      expect(timeline.last.id, startsWith('mock_audit_'));
    });

    test('review and consent check keep the status', () async {
      await repository.recordCaseAction(
        caseId: 'mock_case_001',
        action: CaseAction.reviewCase,
      );
      final updated = await repository.recordCaseAction(
        caseId: 'mock_case_001',
        action: CaseAction.checkConsent,
      );
      expect(updated.status, SafetyCaseStatus.pendingReview);
      expect(updated.previousAttempts, 1);
    });

    test('contact action moves an approved case to follow-up', () async {
      final updated = await repository.recordCaseAction(
        caseId: 'mock_case_001',
        action: CaseAction.callApprovedContact,
      );
      expect(updated.status, SafetyCaseStatus.contactFollowUp);
    });

    test('contact action is refused without an approved contact', () async {
      await expectLater(
        repository.recordCaseAction(
          caseId: 'mock_case_002',
          action: CaseAction.callApprovedContact,
        ),
        throwsStateError,
      );
      expect(
        (await repository.getCase('mock_case_002'))!.status,
        SafetyCaseStatus.retryRequested,
      );
      final timeline = await repository.watchAuditEvents('mock_case_002').first;
      expect(timeline, hasLength(1));
    });

    test('unknown case is refused', () async {
      await expectLater(
        repository.recordCaseAction(
          caseId: 'missing',
          action: CaseAction.reviewCase,
        ),
        throwsStateError,
      );
    });

    test('audit events only notify the affected case', () async {
      final otherCase = repository.watchAuditEvents('mock_case_003');
      final emissions = <List<CaseAuditEvent>>[];
      final subscription = otherCase.listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      await repository.recordCaseAction(
        caseId: 'mock_case_001',
        action: CaseAction.reviewCase,
      );
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emissions, hasLength(1));
    });
  });

  group('closeCase', () {
    test('closes with an outcome and updates counts and audit', () async {
      await repository.recordCaseAction(
        caseId: 'mock_case_001',
        action: CaseAction.callApprovedContact,
      );
      final closed = await repository.closeCase(
        caseId: 'mock_case_001',
        actionTaken: CaseActionTaken.contactedApprovedPerson,
        result: CaseOutcomeResult.elderContactedSuccessfully,
        closureReason: CaseClosureReason.safetyConfirmed,
        notes: ' Spoke with daughter. Elder is safe and well. ',
      );

      expect(closed.isClosed, isTrue);
      expect(closed.closedAt, fixedNow);
      expect(
        closed.outcome!.actionTaken,
        CaseActionTaken.contactedApprovedPerson,
      );
      expect(
        closed.outcome!.result,
        CaseOutcomeResult.elderContactedSuccessfully,
      );
      expect(
        closed.outcome!.notes,
        'Spoke with daughter. Elder is safe and well.',
      );
      expect(closed.outcome!.recordedAt, fixedNow);

      final counts = SafetyCaseCounts.fromCases(
        await repository.watchCases().first,
      );
      expect(counts.all, 4);
      expect(counts.pending, 3);
      expect(counts.closed, 1);

      final timeline = await repository.watchAuditEvents('mock_case_001').first;
      expect(timeline.map((e) => e.type), [
        CaseAuditEventType.checkInMissed,
        CaseAuditEventType.approvedContactCalled,
        CaseAuditEventType.caseClosed,
      ]);
      expect(
        timeline.last.note,
        'Spoke with daughter. Elder is safe and well.',
      );
    });

    test('closed case refuses further actions and re-closing', () async {
      await repository.closeCase(
        caseId: 'mock_case_003',
        actionTaken: CaseActionTaken.rescheduledCheckIn,
        result: CaseOutcomeResult.checkInRescheduled,
        closureReason: CaseClosureReason.followUpScheduled,
      );

      await expectLater(
        repository.recordCaseAction(
          caseId: 'mock_case_003',
          action: CaseAction.reviewCase,
        ),
        throwsStateError,
      );
      await expectLater(
        repository.closeCase(
          caseId: 'mock_case_003',
          actionTaken: CaseActionTaken.rescheduledCheckIn,
          result: CaseOutcomeResult.checkInRescheduled,
          closureReason: CaseClosureReason.followUpScheduled,
        ),
        throwsStateError,
      );
    });

    test('audit entries record actor and result', () async {
      await repository.recordCaseAction(
        caseId: 'mock_case_002',
        action: CaseAction.reviewCase,
        note: ' Checked schedule. ',
      );
      await repository.recordCaseAction(
        caseId: 'mock_case_002',
        action: CaseAction.rescheduleCheckIn,
      );

      final timeline = await repository.watchAuditEvents('mock_case_002').first;
      expect(timeline.map((e) => e.actor.label), [
        'System',
        'Coordinator',
        'Coordinator',
      ]);
      expect(timeline.map((e) => e.result), [
        'Safety case opened',
        'Status unchanged (Retry Requested)',
        'Status set to Rescheduled',
      ]);
      expect(timeline[1].note, 'Checked schedule.');
      expect(timeline[1].occurredAt, fixedNow);
    });

    test('an unresolved outcome is recorded as unresolved', () async {
      final closed = await repository.closeCase(
        caseId: 'mock_case_002',
        actionTaken: CaseActionTaken.retriedCheckIn,
        result: CaseOutcomeResult.elderNotReached,
        closureReason: CaseClosureReason.noFurtherActionAvailable,
        notes: 'No answer after two retries.',
      );

      expect(closed.isClosed, isTrue);
      expect(closed.outcome!.isResolved, isFalse);
      expect(closed.outcome!.resolutionLabel, 'Unresolved');
      expect(
        closed.outcome!.closureReason,
        CaseClosureReason.noFurtherActionAvailable,
      );

      final timeline = await repository.watchAuditEvents('mock_case_002').first;
      expect(timeline.last.type, CaseAuditEventType.caseClosed);
      expect(
        timeline.last.result,
        'Unresolved: Elder could not be reached. '
        'Reason: No further coordinator action available.',
      );
      expect(timeline.last.note, 'No answer after two retries.');
    });

    test('safety cannot be cited as confirmed for an unresolved outcome',
        () async {
      await expectLater(
        repository.closeCase(
          caseId: 'mock_case_002',
          actionTaken: CaseActionTaken.retriedCheckIn,
          result: CaseOutcomeResult.elderNotReached,
          closureReason: CaseClosureReason.safetyConfirmed,
        ),
        throwsStateError,
      );
      expect((await repository.getCase('mock_case_002'))!.isClosed, isFalse);
    });

    test('an unresolved outcome is refused without notes', () async {
      await expectLater(
        repository.closeCase(
          caseId: 'mock_case_002',
          actionTaken: CaseActionTaken.retriedCheckIn,
          result: CaseOutcomeResult.elderNotReached,
          closureReason: CaseClosureReason.noFurtherActionAvailable,
        ),
        throwsStateError,
      );
      expect((await repository.getCase('mock_case_002'))!.isClosed, isFalse);
    });

    test('an unresolved outcome is refused with whitespace-only notes',
        () async {
      await expectLater(
        repository.closeCase(
          caseId: 'mock_case_002',
          actionTaken: CaseActionTaken.retriedCheckIn,
          result: CaseOutcomeResult.elderNotReached,
          closureReason: CaseClosureReason.noFurtherActionAvailable,
          notes: '   \n\t ',
        ),
        throwsStateError,
      );
      expect((await repository.getCase('mock_case_002'))!.isClosed, isFalse);
    });

    test('approved-contact outcomes require consent', () async {
      await expectLater(
        repository.closeCase(
          caseId: 'mock_case_002',
          actionTaken: CaseActionTaken.retriedCheckIn,
          result: CaseOutcomeResult.approvedContactNotReached,
          closureReason: CaseClosureReason.noFurtherActionAvailable,
        ),
        throwsStateError,
      );
      expect((await repository.getCase('mock_case_002'))!.isClosed, isFalse);
    });

    test('closing via approved contact requires consent', () async {
      await expectLater(
        repository.closeCase(
          caseId: 'mock_case_002',
          actionTaken: CaseActionTaken.contactedApprovedPerson,
          result: CaseOutcomeResult.safetyConfirmedByApprovedContact,
          closureReason: CaseClosureReason.safetyConfirmed,
        ),
        throwsStateError,
      );
      expect((await repository.getCase('mock_case_002'))!.isClosed, isFalse);
    });
  });

  test('each repository instance starts from fresh mock data', () async {
    await repository.closeCase(
      caseId: 'mock_case_001',
      actionTaken: CaseActionTaken.retriedCheckIn,
      result: CaseOutcomeResult.elderContactedSuccessfully,
      closureReason: CaseClosureReason.safetyConfirmed,
    );
    final fresh = MockCoordinatorCaseRepository();
    addTearDown(fresh.dispose);

    expect((await fresh.getCase('mock_case_001'))!.isClosed, isFalse);
    expect(
      MockCoordinatorCaseRepository.mockCases.first.status,
      SafetyCaseStatus.pendingReview,
    );
  });
}
