/// Kinds of entries in a case's audit timeline.
enum CaseAuditEventType {
  checkInMissed('Check-in missed'),
  caseReviewed('Coordinator reviewed case'),
  consentChecked('Consent checked'),
  retryRequested('Check-in retry requested'),
  checkInRescheduled('Check-in rescheduled'),
  approvedContactCalled('Approved contact contacted'),
  approvedContactMessaged('Approved contact messaged'),
  contactFollowUpCompleted('Contact follow-up completed'),
  caseClosed('Case closed');

  const CaseAuditEventType(this.label);

  final String label;
}

/// Who produced an audit entry.
///
/// Only the role is recorded; there is no individual coordinator identity yet,
/// so none is shown.
enum CaseAuditActor {
  system('System'),
  coordinator('Coordinator');

  const CaseAuditActor(this.label);

  final String label;
}

/// An immutable entry in a safety case's audit timeline.
class CaseAuditEvent {
  final String id;
  final String caseId;
  final CaseAuditEventType type;
  final CaseAuditActor actor;
  final DateTime occurredAt;

  /// What the entry changed, e.g. the status it set; empty when not recorded.
  final String result;
  final String note;

  const CaseAuditEvent({
    required this.id,
    required this.caseId,
    required this.type,
    required this.actor,
    required this.occurredAt,
    this.result = '',
    this.note = '',
  });
}
