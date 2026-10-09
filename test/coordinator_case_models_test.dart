import 'package:carelink_app/features/coordinator/models/case_audit_event.dart';
import 'package:carelink_app/features/coordinator/models/case_outcome.dart';
import 'package:carelink_app/features/coordinator/models/elder_consent_context.dart';
import 'package:carelink_app/features/coordinator/models/safety_case.dart';
import 'package:flutter_test/flutter_test.dart';

SafetyCase _case(String id, SafetyCaseStatus status) => SafetyCase(
  id: id,
  caseNumber: 7,
  elderId: 'elder_$id',
  elderReference: 'EL007',
  elderDisplayName: 'Test Elder',
  status: status,
  scheduledAt: DateTime(2026, 9, 30, 10, 30),
  openedAt: DateTime(2026, 9, 30, 10, 30),
);

void main() {
  group('SafetyCase', () {
    test('formats the case label with three digits', () {
      expect(_case('a', SafetyCaseStatus.pendingReview).caseLabel, 'Case #007');
    });

    test('status labels match the case list screen', () {
      expect(SafetyCaseStatus.values.map((status) => status.label), [
        'Pending Review',
        'Retry Requested',
        'Rescheduled',
        'Contact Follow-up',
        'Closed',
      ]);
      expect(SafetyCaseReason.missedCheckIn.label, 'Missed Check-in');
    });

    test('copyWith updates workflow fields and keeps identity', () {
      final original = _case('a', SafetyCaseStatus.pendingReview);
      final outcome = CaseOutcome(
        actionTaken: CaseActionTaken.retriedCheckIn,
        result: CaseOutcomeResult.elderContactedSuccessfully,
        closureReason: CaseClosureReason.safetyConfirmed,
        recordedAt: DateTime(2026, 9, 30, 11),
      );
      final closed = original.copyWith(
        status: SafetyCaseStatus.closed,
        closedAt: DateTime(2026, 9, 30, 11),
        outcome: outcome,
      );

      expect(closed.id, original.id);
      expect(closed.elderDisplayName, original.elderDisplayName);
      expect(closed.isClosed, isTrue);
      expect(closed.outcome, same(outcome));
      expect(original.isClosed, isFalse);
    });
  });

  group('SafetyCaseFilter and SafetyCaseCounts', () {
    final cases = [
      _case('a', SafetyCaseStatus.pendingReview),
      _case('b', SafetyCaseStatus.contactFollowUp),
      _case('c', SafetyCaseStatus.closed),
    ];

    test('pending includes every open status', () {
      expect(SafetyCaseFilter.pending.apply(cases).map((c) => c.id), [
        'a',
        'b',
      ]);
      expect(SafetyCaseFilter.closed.apply(cases).map((c) => c.id), ['c']);
      expect(SafetyCaseFilter.all.apply(cases), hasLength(3));
    });

    test('counts are derived from the cases', () {
      final counts = SafetyCaseCounts.fromCases(cases);
      expect(counts.all, 3);
      expect(counts.pending, 2);
      expect(counts.closed, 1);
      for (final filter in SafetyCaseFilter.values) {
        expect(counts.countFor(filter), filter.apply(cases).length);
      }
    });

    test('counts are zero for no cases', () {
      final counts = SafetyCaseCounts.fromCases(const []);
      expect([counts.all, counts.pending, counts.closed], [0, 0, 0]);
    });
  });

  group('CaseAction', () {
    test('only contact actions require an approved contact', () {
      expect(
        CaseAction.values.where((action) => action.requiresApprovedContact),
        [
          CaseAction.callApprovedContact,
          CaseAction.messageApprovedContact,
          CaseAction.completeContactFollowUp,
        ],
      );
    });

    test('maps to status changes and audit events', () {
      expect(CaseAction.reviewCase.resultingStatus, isNull);
      expect(CaseAction.checkConsent.resultingStatus, isNull);
      expect(
        CaseAction.retryCheckIn.resultingStatus,
        SafetyCaseStatus.retryRequested,
      );
      expect(
        CaseAction.rescheduleCheckIn.resultingStatus,
        SafetyCaseStatus.rescheduled,
      );
      expect(
        CaseAction.callApprovedContact.resultingStatus,
        SafetyCaseStatus.contactFollowUp,
      );
      for (final action in CaseAction.values) {
        expect(action.resultingStatus, isNot(SafetyCaseStatus.closed));
        expect(action.auditEventType, isNot(CaseAuditEventType.caseClosed));
      }
    });

    test('only outcomes that reached someone count as resolved', () {
      expect(
        CaseOutcomeResult.values.where((result) => !result.isResolved),
        [
          CaseOutcomeResult.elderNotReached,
          CaseOutcomeResult.approvedContactNotReached,
        ],
      );
      expect(
        CaseOutcomeResult.values.where(
          (result) => result.requiresApprovedContact,
        ),
        [
          CaseOutcomeResult.safetyConfirmedByApprovedContact,
          CaseOutcomeResult.approvedContactNotReached,
        ],
      );
    });

    test('safety confirmed is not a closure reason for unresolved outcomes',
        () {
      for (final result in CaseOutcomeResult.values) {
        expect(
          CaseClosureReason.safetyConfirmed.allows(result),
          result.isResolved,
        );
        expect(
          CaseClosureReason.noFurtherActionAvailable.allows(result),
          isTrue,
        );
      }
    });

    test('outcome labels match the case outcome screen', () {
      expect(
        CaseActionTaken.contactedApprovedPerson.label,
        'Contacted Approved Person',
      );
      expect(
        CaseOutcomeResult.elderContactedSuccessfully.label,
        'Elder contacted successfully',
      );
    });
  });

  group('ElderConsentContext', () {
    test('notRecorded grants nothing', () {
      const context = ElderConsentContext.notRecorded(
        elderId: 'elder_x',
        source: ConsentContextSource.mock,
      );
      expect(context.familySharing, ConsentSharingStatus.notRecorded);
      expect(context.approvedContact, isNull);
      expect(context.allowedInformation, isEmpty);
      expect(context.canContactApprovedPerson, isFalse);
      expect(context.isMock, isTrue);
    });

    test('contact requires approval and a named contact', () {
      const contact = ApprovedContact(
        id: 'c1',
        name: 'Jane Silva',
        relationship: 'Daughter',
      );
      expect(contact.displayLabel, 'Jane Silva (Daughter)');

      const approved = ElderConsentContext(
        elderId: 'e',
        familySharing: ConsentSharingStatus.approved,
        approvedContact: contact,
        source: ConsentContextSource.mock,
      );
      const withdrawn = ElderConsentContext(
        elderId: 'e',
        familySharing: ConsentSharingStatus.withdrawn,
        approvedContact: contact,
        source: ConsentContextSource.mock,
      );
      const approvedWithoutContact = ElderConsentContext(
        elderId: 'e',
        familySharing: ConsentSharingStatus.approved,
        source: ConsentContextSource.mock,
      );

      expect(approved.canContactApprovedPerson, isTrue);
      expect(withdrawn.canContactApprovedPerson, isFalse);
      expect(approvedWithoutContact.canContactApprovedPerson, isFalse);
    });
  });
}
