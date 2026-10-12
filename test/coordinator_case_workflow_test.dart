import 'package:carelink_app/app/routes.dart';
import 'package:carelink_app/features/coordinator/coordinator_case_scope.dart';
import 'package:carelink_app/features/coordinator/coordinator_screens.dart';
import 'package:carelink_app/features/coordinator/models/case_audit_event.dart';
import 'package:carelink_app/features/coordinator/models/case_outcome.dart';
import 'package:carelink_app/features/coordinator/models/elder_consent_context.dart';
import 'package:carelink_app/features/coordinator/models/safety_case.dart';
import 'package:carelink_app/features/coordinator/services/coordinator_case_repository.dart';
import 'package:carelink_app/features/coordinator/services/mock_coordinator_case_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _silva = 'mock_case_001';
const _perera = 'mock_case_002';

/// A repository whose every read fails, for the error states.
class _FailingRepository implements CoordinatorCaseRepository {
  @override
  bool get usesMockData => true;

  @override
  Stream<List<SafetyCase>> watchCases() =>
      Stream.error(StateError('Case service unavailable.'));

  @override
  Future<SafetyCase?> getCase(String caseId) =>
      Future.error(StateError('Case service unavailable.'));

  @override
  Future<ElderConsentContext?> getConsentContext(String caseId) =>
      Future.error(StateError('Case service unavailable.'));

  @override
  Future<SafetyCase> recordCaseAction({
    required String caseId,
    required CaseAction action,
    String note = '',
  }) => throw UnimplementedError();

  @override
  Future<SafetyCase> closeCase({
    required String caseId,
    required CaseActionTaken actionTaken,
    required CaseOutcomeResult result,
    required CaseClosureReason closureReason,
    String notes = '',
  }) => throw UnimplementedError();

  @override
  Stream<List<CaseAuditEvent>> watchAuditEvents(String caseId) =>
      Stream.error(StateError('Case service unavailable.'));
}

/// Mock cases with one consent record substituted for every elder.
class _ConsentOverrideRepository extends MockCoordinatorCaseRepository {
  _ConsentOverrideRepository(this.consent);

  final ElderConsentContext consent;

  @override
  Future<ElderConsentContext?> getConsentContext(String caseId) async =>
      await getCase(caseId) == null ? null : consent;
}

Map<String, WidgetBuilder> get _routes => {
  AppRoutes.coordinatorCaseList: (_) => const CoordinatorCaseListScreen(),
  AppRoutes.coordinatorCaseDetail: (_) => const CoordinatorCaseDetailScreen(),
  AppRoutes.consentContextReview: (_) => const ConsentContextReviewScreen(),
  AppRoutes.approvedContactAction: (_) => const ApprovedContactActionScreen(),
  AppRoutes.auditOutcomeCloseCase: (_) => const AuditOutcomeCloseCaseScreen(),
  AppRoutes.caseClosed: (_) => const CaseClosedScreen(),
};

/// Opens [route] with [caseId] on top of the case list, as the app does.
Future<void> _pumpApp(
  WidgetTester tester,
  CoordinatorCaseRepository repository, {
  String? route,
  String? caseId,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    CoordinatorCaseScope(
      repository: repository,
      child: MaterialApp(
        initialRoute: AppRoutes.coordinatorCaseList,
        routes: _routes,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (route != null) {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(route, arguments: caseId);
    await tester.pumpAndSettle();
  }
}

Future<void> _openCase(WidgetTester tester, String elderName) async {
  await tester.tap(find.text(elderName));
  await tester.pumpAndSettle();
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String fieldKey, String item) async {
  await _tapAndSettle(tester, find.byKey(ValueKey(fieldKey)));
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<List<CaseAuditEventType>> _eventTypes(
  CoordinatorCaseRepository repository,
  String caseId,
) async =>
    (await repository.watchAuditEvents(caseId).first).map((e) => e.type).toList();

void main() {
  late MockCoordinatorCaseRepository repository;

  setUp(() => repository = MockCoordinatorCaseRepository());
  tearDown(() => repository.dispose());

  group('Case list', () {
    testWidgets('derives counts and filters from repository cases', (
      tester,
    ) async {
      await _pumpApp(tester, repository);

      expect(find.text('All (4)'), findsOneWidget);
      expect(find.text('Pending (4)'), findsOneWidget);
      expect(find.text('Closed (0)'), findsOneWidget);
      for (final name in [
        'Mrs. Silva',
        'Mr. Perera',
        'Ms. Fernando',
        'Ms. Jayasinghe',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('30 Sep 2026, 2:00 PM'), findsOneWidget);
      expect(find.text('Retry Requested'), findsOneWidget);

      await _tapAndSettle(tester, find.text('Closed (0)'));
      expect(find.text('No closed cases.'), findsOneWidget);
      expect(find.text('Mrs. Silva'), findsNothing);

      await _tapAndSettle(tester, find.text('Pending (4)'));
      expect(find.text('Mrs. Silva'), findsOneWidget);
      expect(find.text('Ms. Jayasinghe'), findsOneWidget);
    });

    testWidgets('updates counts and filters when a case is closed', (
      tester,
    ) async {
      await _pumpApp(tester, repository);

      await repository.closeCase(
        caseId: _perera,
        actionTaken: CaseActionTaken.retriedCheckIn,
        result: CaseOutcomeResult.elderContactedSuccessfully,
        closureReason: CaseClosureReason.safetyConfirmed,
      );
      await tester.pumpAndSettle();

      expect(find.text('All (4)'), findsOneWidget);
      expect(find.text('Pending (3)'), findsOneWidget);
      expect(find.text('Closed (1)'), findsOneWidget);

      await _tapAndSettle(tester, find.text('Closed (1)'));
      expect(find.text('Mr. Perera'), findsOneWidget);
      expect(find.text('Mrs. Silva'), findsNothing);

      await _tapAndSettle(tester, find.text('Pending (3)'));
      expect(find.text('Mr. Perera'), findsNothing);
    });

    testWidgets('shows an error state when cases cannot load', (tester) async {
      await _pumpApp(tester, _FailingRepository());

      expect(find.text('Could not load safety cases.'), findsOneWidget);
      expect(find.text('Case service unavailable.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('tapping a case opens its own detail screen', (tester) async {
      await _pumpApp(tester, repository);

      await _openCase(tester, 'Mr. Perera');
      expect(find.text('Case #002'), findsOneWidget);
      expect(find.text('Elder ID: EL002'), findsOneWidget);
      expect(find.text('Retry Requested'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await _openCase(tester, 'Mrs. Silva');
      expect(find.text('Case #001'), findsOneWidget);
      expect(find.text('Mother'), findsOneWidget);
      expect(find.text('30 Sep 2026, 10:30 AM'), findsOneWidget);
      expect(find.text('Approved family contact'), findsOneWidget);
    });
  });

  group('Case detail', () {
    testWidgets('shows a clear state when no case id is given', (tester) async {
      await _pumpApp(tester, repository, route: AppRoutes.coordinatorCaseDetail);

      expect(find.text('No case selected.'), findsOneWidget);
    });

    testWidgets('retry asks for confirmation before recording', (tester) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mrs. Silva');
      expect(find.text('1 attempt'), findsOneWidget);

      await _tapAndSettle(tester, find.text('Retry'));
      expect(find.text('Retry check-in?'), findsOneWidget);
      await _tapAndSettle(tester, find.text('Cancel'));
      expect(await _eventTypes(repository, _silva), [
        CaseAuditEventType.checkInMissed,
      ]);

      await _tapAndSettle(tester, find.text('Retry'));
      await _tapAndSettle(tester, find.text('Request retry'));

      expect(find.text('Check-in retry requested.'), findsOneWidget);
      expect(find.text('Retry Requested'), findsOneWidget);
      expect(find.text('2 attempts'), findsOneWidget);
      expect(await _eventTypes(repository, _silva), [
        CaseAuditEventType.checkInMissed,
        CaseAuditEventType.retryRequested,
      ]);
    });

    testWidgets('reschedule records the picked date without changing the '
        'scheduled check-in', (tester) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mrs. Silva');

      await _tapAndSettle(tester, find.text('Reschedule'));
      expect(find.text('Reschedule check-in'), findsOneWidget);
      await _tapAndSettle(tester, find.text('OK'));

      final events = await repository.watchAuditEvents(_silva).first;
      expect(events.last.type, CaseAuditEventType.checkInRescheduled);
      expect(events.last.note, startsWith('Requested new check-in date: '));
      final updated = await repository.getCase(_silva);
      expect(updated!.status, SafetyCaseStatus.rescheduled);
      expect(updated.scheduledAt, DateTime(2026, 9, 30, 10, 30));
      expect(find.text('Rescheduled'), findsOneWidget);
    });

    testWidgets('contact is disabled without approved consent', (tester) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mr. Perera');

      expect(find.text('Consent not recorded'), findsOneWidget);
      expect(
        find.text('No approved consent and contact on record'),
        findsOneWidget,
      );
      await _tapAndSettle(tester, find.text('Contact Approved Person'));
      expect(find.text('Case #002'), findsOneWidget);
      expect(find.text('Call Contact'), findsNothing);
    });

    testWidgets('contact opens the approved-contact screen for the case', (
      tester,
    ) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mrs. Silva');

      // Shown only on the contact action.
      expect(find.text('Jane Silva (Daughter)'), findsOneWidget);
      await _tapAndSettle(tester, find.text('Contact Approved Person'));

      expect(find.text('Approved Contact'), findsOneWidget);
      expect(find.text('Jane Silva'), findsOneWidget);
      expect(find.text('Daughter'), findsOneWidget);
    });

    testWidgets('shows missed-session context from the case record', (
      tester,
    ) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mrs. Silva');

      expect(find.text('Missed Session'), findsNothing);
      expect(find.text('Scheduled Time'), findsOneWidget);
      expect(find.text('30 Sep 2026, 10:30 AM'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Missed Check-in'), findsOneWidget);
      expect(find.text('Previous Attempts'), findsOneWidget);
      expect(find.text('1 attempt'), findsOneWidget);
      expect(find.text('Consent'), findsOneWidget);
      expect(find.textContaining('Not connected to live sessions'),
          findsOneWidget);
    });

    testWidgets('does not show a case history section', (tester) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mrs. Silva');

      expect(find.text('Case History'), findsNothing);
      expect(find.text('Check-in missed'), findsNothing);
      expect(find.text('30 Sep 2026, 10:30 AM · System'), findsNothing);

      await _tapAndSettle(tester, find.text('Retry'));
      await _tapAndSettle(tester, find.text('Request retry'));
      await _tapAndSettle(tester, find.text('Reschedule'));
      await _tapAndSettle(tester, find.text('OK'));

      // Actions are still recorded but not listed on the detail screen.
      expect((await repository.getCase(_silva))!.isClosed, isFalse);
      expect(await _eventTypes(repository, _silva), [
        CaseAuditEventType.checkInMissed,
        CaseAuditEventType.retryRequested,
        CaseAuditEventType.checkInRescheduled,
      ]);
      expect(find.text('Case History'), findsNothing);
      expect(find.text('Check-in retry requested'), findsNothing);
      expect(find.text('Check-in rescheduled'), findsNothing);
      expect(find.textContaining('Requested new check-in date: '), findsNothing);
      expect(find.text('Scheduled Time'), findsOneWidget);
      expect(find.text('Consent'), findsOneWidget);
      expect(find.text('Record Outcome & Close'), findsOneWidget);
      expect(find.text('View Audit Timeline'), findsNothing);
    });

    testWidgets('summarises approved consent and opens the consent review', (
      tester,
    ) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mrs. Silva');

      expect(find.text('Approved family contact'), findsOneWidget);
      // Detailed consent fields live on the consent review screen only.
      expect(find.text('Consent Summary'), findsNothing);
      expect(find.text('Approved Contact'), findsNothing);
      expect(find.text('Shared Information'), findsNothing);
      expect(find.text('Last Updated'), findsNothing);
      expect(
        find.text(
          'Check-in status, Schedule information, General wellbeing status',
        ),
        findsNothing,
      );
      expect(find.text('15 Sep 2026'), findsNothing);

      await _tapAndSettle(tester, find.text('Review Consent'));
      expect(find.text('Consent & Context'), findsOneWidget);
    });

    testWidgets('consent summary does not invent consent when none is '
        'recorded', (tester) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mr. Perera');

      expect(find.text('Consent not recorded'), findsOneWidget);
      expect(find.text('Approved family contact'), findsNothing);
      expect(find.text('Approved'), findsNothing);
      expect(find.textContaining('Jane Silva'), findsNothing);
    });

    testWidgets('contact stays disabled when consent is withdrawn even with '
        'a named contact', (tester) async {
      final withdrawn = _ConsentOverrideRepository(
        ElderConsentContext(
          elderId: 'mock_elder_silva',
          familySharing: ConsentSharingStatus.withdrawn,
          approvedContact: const ApprovedContact(
            id: 'mock_contact_jane_silva',
            name: 'Jane Silva',
            relationship: 'Daughter',
          ),
          source: ConsentContextSource.mock,
        ),
      );
      addTearDown(withdrawn.dispose);
      await _pumpApp(tester, withdrawn);
      await _openCase(tester, 'Mrs. Silva');

      expect(find.text('Consent withdrawn'), findsOneWidget);
      expect(
        find.text('No approved consent and contact on record'),
        findsOneWidget,
      );
      await _tapAndSettle(tester, find.text('Contact Approved Person'));
      expect(find.text('Case #001'), findsOneWidget);
      expect(find.text('Call Contact'), findsNothing);
    });

    testWidgets('closed case links to its audit timeline and disables actions', (
      tester,
    ) async {
      await repository.recordCaseAction(
        caseId: _perera,
        action: CaseAction.retryCheckIn,
      );
      await repository.closeCase(
        caseId: _perera,
        actionTaken: CaseActionTaken.retriedCheckIn,
        result: CaseOutcomeResult.elderContactedSuccessfully,
        closureReason: CaseClosureReason.safetyConfirmed,
        notes: 'Elder answered the retry.',
      );
      await _pumpApp(tester, repository);
      await _tapAndSettle(tester, find.text('Closed (1)'));
      await _openCase(tester, 'Mr. Perera');

      expect(find.text('Closed'), findsOneWidget);
      // History lives on the audit timeline, not the detail screen.
      expect(find.text('Case History'), findsNothing);
      expect(find.text('Check-in missed'), findsNothing);
      expect(find.text('Case closed'), findsNothing);
      // Retry, Reschedule and Contact Approved Person.
      expect(find.text('Case is closed'), findsNWidgets(3));
      expect(find.text('Record Outcome & Close'), findsNothing);

      await _tapAndSettle(tester, find.text('Retry'));
      expect(find.text('Retry check-in?'), findsNothing);
      expect(await _eventTypes(repository, _perera), [
        CaseAuditEventType.checkInMissed,
        CaseAuditEventType.retryRequested,
        CaseAuditEventType.caseClosed,
      ]);

      // Consent review stays available after closure.
      await _tapAndSettle(tester, find.text('Review Consent'));
      expect(find.text('Consent & Context'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await _tapAndSettle(tester, find.text('View Audit Timeline'));
      expect(find.text('Back to Case List'), findsOneWidget);
      expect(find.text('Check-in missed'), findsOneWidget);
      expect(find.text('Check-in retry requested'), findsOneWidget);
      expect(find.text('Case closed'), findsOneWidget);
    });
  });

  group('Consent review', () {
    testWidgets('shows the approved consent recorded for the elder', (
      tester,
    ) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mrs. Silva');
      await _tapAndSettle(tester, find.text('Review Consent'));

      expect(find.text('Consent & Context'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Jane Silva (Daughter)'), findsOneWidget);
      expect(find.text('1 Jan 2026'), findsOneWidget);
      expect(find.text('15 Sep 2026'), findsOneWidget);
      expect(find.text('Check-in status'), findsOneWidget);
      expect(find.text('Private conversation content'), findsOneWidget);
      expect(find.text('Contact Jane Silva'), findsOneWidget);

      await _tapAndSettle(tester, find.text('Contact Jane Silva'));
      expect(find.text('Approved Contact'), findsOneWidget);
      expect(find.text('Jane Silva'), findsOneWidget);
    });

    testWidgets('does not invent consent when none is recorded', (
      tester,
    ) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mr. Perera');
      await _tapAndSettle(tester, find.text('Review Consent'));

      expect(find.text('Not recorded'), findsNWidgets(3));
      expect(find.text('None recorded'), findsOneWidget);
      expect(find.text('Approved'), findsNothing);
      expect(find.text('Jane Silva (Daughter)'), findsNothing);
      expect(find.text('No information sharing is recorded.'), findsOneWidget);
      expect(find.text('All case information'), findsOneWidget);
      expect(find.textContaining('Consent is not recorded.'), findsOneWidget);
      expect(find.textContaining('Contact '), findsNothing);
    });
  });

  group('Approved contact', () {
    testWidgets('is restricted when consent has no approved contact', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        repository,
        route: AppRoutes.approvedContactAction,
        caseId: _perera,
      );

      expect(find.text('Contact unavailable.'), findsOneWidget);
      expect(find.text('Call Contact'), findsNothing);
      expect(find.text('Send Message'), findsNothing);
    });

    testWidgets('shows the contact, reason and notice without action rows', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        repository,
        route: AppRoutes.approvedContactAction,
        caseId: _silva,
      );

      expect(find.text('CareLink'), findsOneWidget);
      expect(find.text('Approved Contact'), findsOneWidget);
      expect(find.text('Jane Silva'), findsOneWidget);
      expect(find.text('Daughter'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Reason for Contact'), findsOneWidget);
      expect(
        find.text(
          "Mrs. Silva's check-in scheduled for 30 Sep 2026, 10:30 AM "
          'was not completed.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('does not place calls or send messages'),
        findsOneWidget,
      );

      for (final label in [
        'Call Contact',
        'Send Message',
        'Mark Follow-up Complete',
        'Record Outcome & Close',
      ]) {
        expect(find.text(label), findsNothing);
      }
      expect(await _eventTypes(repository, _silva), [
        CaseAuditEventType.checkInMissed,
      ]);
    });
  });

  group('Case outcome', () {
    testWidgets('requires action taken and outcome', (tester) async {
      await _pumpApp(
        tester,
        repository,
        route: AppRoutes.auditOutcomeCloseCase,
        caseId: _silva,
      );

      await _tapAndSettle(tester, find.text('Close Case'));

      expect(find.text('Select the action taken.'), findsOneWidget);
      expect(find.text('Select the outcome.'), findsOneWidget);
      expect(find.text('Select the closure reason.'), findsOneWidget);
      expect(find.text('Close this case?'), findsNothing);
      expect((await repository.getCase(_silva))!.isClosed, isFalse);
    });

    testWidgets('omits approved-contact options without consent', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        repository,
        route: AppRoutes.auditOutcomeCloseCase,
        caseId: _perera,
      );

      await _tapAndSettle(tester, find.byKey(const ValueKey('actionTakenField')));
      expect(find.text('Retried Check-in'), findsWidgets);
      expect(find.text('Contacted Approved Person'), findsNothing);
      await tester.tap(find.text('Retried Check-in').last);
      await tester.pumpAndSettle();

      await _tapAndSettle(tester, find.byKey(const ValueKey('outcomeField')));
      expect(find.text('Elder could not be reached'), findsWidgets);
      expect(
        find.text('Approved contact confirmed elder is safe'),
        findsNothing,
      );
      expect(find.text('Approved contact could not be reached'), findsNothing);
    });

    testWidgets('an unresolved outcome is closed and shown as unresolved', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        repository,
        route: AppRoutes.auditOutcomeCloseCase,
        caseId: _perera,
      );

      await _select(tester, 'actionTakenField', 'Retried Check-in');
      await _select(tester, 'closureReasonField', 'Elder safety confirmed');
      await _select(tester, 'outcomeField', 'Elder could not be reached');
      expect(
        find.byKey(const ValueKey('unresolvedOutcomeNotice')),
        findsOneWidget,
      );

      // Safety cannot be cited as confirmed, so that reason was cleared.
      await _tapAndSettle(
        tester,
        find.byKey(const ValueKey('closureReasonField')),
      );
      expect(find.text('Elder safety confirmed'), findsNothing);
      await tester.tap(find.text('Handed over outside CareLink').last);
      await tester.pumpAndSettle();

      await _tapAndSettle(tester, find.text('Close Case'));
      expect(
        find.text('Add notes explaining the unresolved outcome.'),
        findsOneWidget,
      );
      expect(find.text('Close this case?'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('notesField')),
        'No answer after retry; passed to local care team.',
      );
      await _tapAndSettle(tester, find.text('Close Case'));
      expect(find.textContaining('closed as unresolved'), findsOneWidget);
      await _tapAndSettle(tester, find.text('Close case'));

      expect(find.text('Case Closed'), findsOneWidget);
      expect(
        find.text(
          "This safety case was closed as unresolved. The elder's safety "
          'was not confirmed.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('This safety case has been closed as resolved.'),
        findsNothing,
      );
      expect(
        find.textContaining('Resolution: Unresolved', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Closure reason: Handed over outside CareLink',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Unresolved: Elder could not be reached. '
          'Reason: Handed over outside CareLink.',
        ),
        findsOneWidget,
      );

      final closed = (await repository.getCase(_perera))!;
      expect(closed.isClosed, isTrue);
      expect(closed.outcome!.isResolved, isFalse);
      expect(
        closed.outcome!.closureReason,
        CaseClosureReason.handedOverOutsideCareLink,
      );
    });

    testWidgets('closes the case and replaces the form with the closed case', (
      tester,
    ) async {
      await _pumpApp(tester, repository);
      await _openCase(tester, 'Mrs. Silva');
      await _tapAndSettle(tester, find.text('Record Outcome & Close'));

      await _select(tester, 'actionTakenField', 'Contacted Approved Person');
      await _select(
        tester,
        'outcomeField',
        'Approved contact confirmed elder is safe',
      );
      expect(
        find.byKey(const ValueKey('unresolvedOutcomeNotice')),
        findsNothing,
      );
      await _select(tester, 'closureReasonField', 'Elder safety confirmed');
      await tester.enterText(
        find.byKey(const ValueKey('notesField')),
        'Spoke with daughter. Elder is safe.',
      );
      await _tapAndSettle(tester, find.text('Close Case'));
      expect(find.text('Close this case?'), findsOneWidget);
      await _tapAndSettle(tester, find.text('Close case'));

      expect(find.text('Case Closed'), findsOneWidget);
      expect(
        find.text('This safety case has been closed as resolved.'),
        findsOneWidget,
      );
      expect(find.text('Case closed'), findsOneWidget);
      // Shown on the outcome summary and on the "Case closed" audit entry.
      expect(find.text('Spoke with daughter. Elder is safe.'), findsOneWidget);
      expect(
        find.textContaining(
          'Spoke with daughter. Elder is safe.',
          findRichText: true,
        ),
        findsNWidgets(2),
      );
      final closed = await repository.getCase(_silva);
      expect(closed!.isClosed, isTrue);
      expect(
        closed.outcome!.result,
        CaseOutcomeResult.safetyConfirmedByApprovedContact,
      );

      // The outcome form was replaced, so back returns to the case detail.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Case Outcome'), findsNothing);
      expect(find.text('Case #001'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('View Audit Timeline'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Closed (1)'), findsOneWidget);
      expect(find.text('Pending (3)'), findsOneWidget);
    });

    testWidgets('an already closed case cannot be closed again', (
      tester,
    ) async {
      await repository.closeCase(
        caseId: _perera,
        actionTaken: CaseActionTaken.retriedCheckIn,
        result: CaseOutcomeResult.elderContactedSuccessfully,
        closureReason: CaseClosureReason.safetyConfirmed,
      );
      await _pumpApp(
        tester,
        repository,
        route: AppRoutes.auditOutcomeCloseCase,
        caseId: _perera,
      );

      expect(find.text('This case is already closed.'), findsOneWidget);
      expect(find.text('Close Case'), findsNothing);
    });
  });

  group('Closed case', () {
    testWidgets('shows the selected case audit events in order', (
      tester,
    ) async {
      await repository.recordCaseAction(
        caseId: _perera,
        action: CaseAction.retryCheckIn,
      );
      await repository.closeCase(
        caseId: _perera,
        actionTaken: CaseActionTaken.retriedCheckIn,
        result: CaseOutcomeResult.elderContactedSuccessfully,
        closureReason: CaseClosureReason.safetyConfirmed,
        notes: 'Elder answered the retry.',
      );
      await _pumpApp(
        tester,
        repository,
        route: AppRoutes.caseClosed,
        caseId: _perera,
      );

      expect(find.text('Case Closed'), findsOneWidget);
      expect(find.text('Mr. Perera'), findsOneWidget);
      expect(find.text('Case #002'), findsOneWidget);
      final labels = [
        'Check-in missed',
        'Check-in retry requested',
        'Case closed',
      ];
      final positions = [
        for (final label in labels) tester.getTopLeft(find.text(label)).dy,
      ];
      expect(positions, orderedEquals([...positions]..sort()));
      expect(find.text('Approved contact contacted'), findsNothing);
      expect(find.text('30 Sep\n2:00 PM'), findsOneWidget);

      // Each entry shows its actor, result and notes.
      expect(find.text('By System'), findsOneWidget);
      expect(find.text('By Coordinator'), findsNWidgets(2));
      expect(find.text('Safety case opened'), findsOneWidget);
      expect(find.text('Status set to Retry Requested'), findsOneWidget);
      expect(
        find.text(
          'Resolved: Elder contacted successfully. '
          'Reason: Elder safety confirmed.',
        ),
        findsOneWidget,
      );
      expect(find.text('Elder answered the retry.'), findsOneWidget);
    });

    testWidgets('Back to Case List returns to the existing case list', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        repository,
        route: AppRoutes.caseClosed,
        caseId: _silva,
      );

      await _tapAndSettle(tester, find.text('Back to Case List'));
      expect(find.text('Safety Cases'), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    });

    testWidgets('shows an error when the audit timeline cannot load', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CoordinatorCaseScope(
          repository: _FailingRepository(),
          child: const MaterialApp(home: CaseClosedScreen(caseId: _silva)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load the audit timeline.'), findsOneWidget);
    });
  });
}
