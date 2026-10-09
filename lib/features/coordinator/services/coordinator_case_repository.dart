import '../models/case_audit_event.dart';
import '../models/case_outcome.dart';
import '../models/elder_consent_context.dart';
import '../models/safety_case.dart';

/// Storage-independent contract for the coordinator safety-case workflow.
abstract interface class CoordinatorCaseRepository {
  /// True when cases come from local mock data rather than a backend.
  bool get usesMockData;

  /// Emits the current cases immediately, then again after every change.
  Stream<List<SafetyCase>> watchCases();

  Future<SafetyCase?> getCase(String caseId);

  /// Consent context for the elder on [caseId], or null if the case is unknown.
  Future<ElderConsentContext?> getConsentContext(String caseId);

  /// Records [action] on an open case and returns the updated case.
  ///
  /// Throws [StateError] if the case is missing or closed, or if a contact
  /// action is attempted without an approved contact.
  Future<SafetyCase> recordCaseAction({
    required String caseId,
    required CaseAction action,
    String note = '',
  });

  /// Closes an open case with an outcome and returns the closed case.
  ///
  /// Throws [StateError] if the case is missing or closed, if an approved
  /// contact option is used without consent naming one, or if
  /// [closureReason] does not allow [result].
  Future<SafetyCase> closeCase({
    required String caseId,
    required CaseActionTaken actionTaken,
    required CaseOutcomeResult result,
    required CaseClosureReason closureReason,
    String notes = '',
  });

  /// Emits the case's audit timeline (oldest first), then again on changes.
  Stream<List<CaseAuditEvent>> watchAuditEvents(String caseId);
}
