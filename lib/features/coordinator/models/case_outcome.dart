import 'case_audit_event.dart';
import 'safety_case.dart';

/// Actions a coordinator can record on an open case.
enum CaseAction {
  reviewCase,
  checkConsent,
  retryCheckIn,
  rescheduleCheckIn,
  callApprovedContact,
  messageApprovedContact,
  completeContactFollowUp;

  /// Contact actions are only allowed when consent names an approved contact.
  bool get requiresApprovedContact => switch (this) {
    CaseAction.callApprovedContact ||
    CaseAction.messageApprovedContact ||
    CaseAction.completeContactFollowUp => true,
    _ => false,
  };

  /// The status the case moves to, or null when the status is unchanged.
  SafetyCaseStatus? get resultingStatus => switch (this) {
    CaseAction.reviewCase || CaseAction.checkConsent => null,
    CaseAction.retryCheckIn => SafetyCaseStatus.retryRequested,
    CaseAction.rescheduleCheckIn => SafetyCaseStatus.rescheduled,
    CaseAction.callApprovedContact ||
    CaseAction.messageApprovedContact ||
    CaseAction.completeContactFollowUp => SafetyCaseStatus.contactFollowUp,
  };

  CaseAuditEventType get auditEventType => switch (this) {
    CaseAction.reviewCase => CaseAuditEventType.caseReviewed,
    CaseAction.checkConsent => CaseAuditEventType.consentChecked,
    CaseAction.retryCheckIn => CaseAuditEventType.retryRequested,
    CaseAction.rescheduleCheckIn => CaseAuditEventType.checkInRescheduled,
    CaseAction.callApprovedContact => CaseAuditEventType.approvedContactCalled,
    CaseAction.messageApprovedContact =>
      CaseAuditEventType.approvedContactMessaged,
    CaseAction.completeContactFollowUp =>
      CaseAuditEventType.contactFollowUpCompleted,
  };
}

/// "Action Taken" options on the case outcome screen.
enum CaseActionTaken {
  contactedApprovedPerson('Contacted Approved Person'),
  retriedCheckIn('Retried Check-in'),
  rescheduledCheckIn('Rescheduled Check-in');

  const CaseActionTaken(this.label);

  final String label;
}

/// "Outcome" options on the case outcome screen.
///
/// Only outcomes where the elder or their approved contact was actually
/// reached count as resolved; the rest close the case without confirming the
/// elder's safety.
enum CaseOutcomeResult {
  elderContactedSuccessfully('Elder contacted successfully', isResolved: true),
  safetyConfirmedByApprovedContact(
    'Approved contact confirmed elder is safe',
    isResolved: true,
  ),
  checkInRescheduled('Check-in rescheduled with elder', isResolved: true),
  elderNotReached('Elder could not be reached', isResolved: false),
  approvedContactNotReached(
    'Approved contact could not be reached',
    isResolved: false,
  );

  const CaseOutcomeResult(this.label, {required this.isResolved});

  final String label;
  final bool isResolved;

  /// Outcomes that involve the approved contact need consent naming one.
  bool get requiresApprovedContact => switch (this) {
    CaseOutcomeResult.safetyConfirmedByApprovedContact ||
    CaseOutcomeResult.approvedContactNotReached => true,
    _ => false,
  };
}

/// "Closure Reason" options: why the coordinator is closing the case, kept
/// separate from what the outcome was.
enum CaseClosureReason {
  safetyConfirmed('Elder safety confirmed'),
  followUpScheduled('Follow-up check-in scheduled'),
  handedOverOutsideCareLink('Handed over outside CareLink'),
  noFurtherActionAvailable('No further coordinator action available');

  const CaseClosureReason(this.label);

  final String label;

  /// Whether this reason can be given for [result]; safety cannot be cited as
  /// confirmed when the outcome is unresolved.
  bool allows(CaseOutcomeResult result) =>
      this != CaseClosureReason.safetyConfirmed || result.isResolved;
}

/// What the coordinator recorded when closing a case.
class CaseOutcome {
  final CaseActionTaken actionTaken;
  final CaseOutcomeResult result;
  final CaseClosureReason closureReason;
  final String notes;
  final DateTime recordedAt;

  const CaseOutcome({
    required this.actionTaken,
    required this.result,
    required this.closureReason,
    this.notes = '',
    required this.recordedAt,
  });

  bool get isResolved => result.isResolved;

  /// "Resolved" or "Unresolved", as shown on the closed case.
  String get resolutionLabel => isResolved ? 'Resolved' : 'Unresolved';
}
