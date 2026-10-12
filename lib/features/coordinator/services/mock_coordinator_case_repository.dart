import 'dart:async';

import '../models/case_audit_event.dart';
import '../models/case_outcome.dart';
import '../models/elder_consent_context.dart';
import '../models/safety_case.dart';
import 'coordinator_case_repository.dart';

/// In-memory safety cases for UI development. Not connected to Firebase.
///
/// Every case, elder and consent record here is mock data based on the static
/// case-list examples; ids are prefixed with `mock_` so they cannot be mistaken
/// for Firestore documents.
class MockCoordinatorCaseRepository implements CoordinatorCaseRepository {
  MockCoordinatorCaseRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now {
    for (final safetyCase in mockCases) {
      _cases[safetyCase.id] = safetyCase;
      _events[safetyCase.id] = [
        CaseAuditEvent(
          id: _nextEventId(),
          caseId: safetyCase.id,
          type: CaseAuditEventType.checkInMissed,
          actor: CaseAuditActor.system,
          occurredAt: safetyCase.scheduledAt,
          result: 'Safety case opened',
        ),
      ];
    }
  }

  @override
  bool get usesMockData => true;

  final DateTime Function() _now;
  // Insertion order is preserved so the list matches the original screen.
  final Map<String, SafetyCase> _cases = {};
  final Map<String, List<CaseAuditEvent>> _events = {};
  final _caseChanges = StreamController<String>.broadcast();
  int _eventCounter = 0;

  static final List<SafetyCase> mockCases = List.unmodifiable([
    SafetyCase(
      id: 'mock_case_001',
      caseNumber: 1,
      elderId: 'mock_elder_silva',
      elderReference: 'EL001',
      elderDisplayName: 'Mrs. Silva',
      elderRelationship: 'Mother',
      status: SafetyCaseStatus.pendingReview,
      scheduledAt: DateTime(2026, 9, 30, 10, 30),
      previousAttempts: 1,
      openedAt: DateTime(2026, 9, 30, 10, 30),
    ),
    SafetyCase(
      id: 'mock_case_002',
      caseNumber: 2,
      elderId: 'mock_elder_perera',
      elderReference: 'EL002',
      elderDisplayName: 'Mr. Perera',
      status: SafetyCaseStatus.retryRequested,
      scheduledAt: DateTime(2026, 9, 30, 14),
      openedAt: DateTime(2026, 9, 30, 14),
    ),
    SafetyCase(
      id: 'mock_case_003',
      caseNumber: 3,
      elderId: 'mock_elder_fernando',
      elderReference: 'EL003',
      elderDisplayName: 'Ms. Fernando',
      status: SafetyCaseStatus.rescheduled,
      scheduledAt: DateTime(2026, 9, 29, 11),
      openedAt: DateTime(2026, 9, 29, 11),
    ),
    SafetyCase(
      id: 'mock_case_004',
      caseNumber: 4,
      elderId: 'mock_elder_jayasinghe',
      elderReference: 'EL004',
      elderDisplayName: 'Ms. Jayasinghe',
      status: SafetyCaseStatus.contactFollowUp,
      scheduledAt: DateTime(2026, 9, 29, 15),
      openedAt: DateTime(2026, 9, 29, 15),
    ),
  ]);

  /// Only Mrs. Silva has consent shown on the existing consent screen; every
  /// other elder falls back to [ElderConsentContext.notRecorded].
  static final Map<String, ElderConsentContext> mockConsent = Map.unmodifiable({
    'mock_elder_silva': ElderConsentContext(
      elderId: 'mock_elder_silva',
      familySharing: ConsentSharingStatus.approved,
      approvedContact: const ApprovedContact(
        id: 'mock_contact_jane_silva',
        name: 'Jane Silva',
        relationship: 'Daughter',
      ),
      validFrom: DateTime(2026, 1, 1),
      lastUpdatedAt: DateTime(2026, 9, 15),
      allowedInformation: const [
        'Check-in status',
        'Schedule information',
        'General wellbeing status',
      ],
      restrictedInformation: const ['Private conversation content'],
      source: ConsentContextSource.mock,
    ),
  });

  @override
  Stream<List<SafetyCase>> watchCases() async* {
    yield _snapshot();
    yield* _caseChanges.stream.map((_) => _snapshot());
  }

  @override
  Future<SafetyCase?> getCase(String caseId) async => _cases[caseId];

  @override
  Future<ElderConsentContext?> getConsentContext(String caseId) async {
    final safetyCase = _cases[caseId];
    if (safetyCase == null) return null;
    return _consentFor(safetyCase);
  }

  @override
  Future<SafetyCase> recordCaseAction({
    required String caseId,
    required CaseAction action,
    String note = '',
  }) async {
    final current = _openCase(caseId);
    if (action.requiresApprovedContact &&
        !_consentFor(current).canContactApprovedPerson) {
      throw StateError('No approved contact is recorded for this elder.');
    }
    final updated = current.copyWith(
      status: action.resultingStatus,
      previousAttempts: action == CaseAction.retryCheckIn
          ? current.previousAttempts + 1
          : null,
    );
    _cases[caseId] = updated;
    final status = action.resultingStatus;
    _addEvent(
      caseId,
      action.auditEventType,
      note,
      result: status == null
          ? 'Status unchanged (${updated.status.label})'
          : 'Status set to ${status.label}',
    );
    return updated;
  }

  @override
  Future<SafetyCase> closeCase({
    required String caseId,
    required CaseActionTaken actionTaken,
    required CaseOutcomeResult result,
    required CaseClosureReason closureReason,
    String notes = '',
  }) async {
    final current = _openCase(caseId);
    if ((actionTaken == CaseActionTaken.contactedApprovedPerson ||
            result.requiresApprovedContact) &&
        !_consentFor(current).canContactApprovedPerson) {
      throw StateError('No approved contact is recorded for this elder.');
    }
    if (!closureReason.allows(result)) {
      throw StateError(
        '"${closureReason.label}" cannot be given for an unresolved outcome.',
      );
    }
    final trimmedNotes = notes.trim();
    if (!result.isResolved && trimmedNotes.isEmpty) {
      throw StateError('Notes are required for an unresolved outcome.');
    }
    final closedAt = _now();
    final closed = current.copyWith(
      status: SafetyCaseStatus.closed,
      closedAt: closedAt,
      outcome: CaseOutcome(
        actionTaken: actionTaken,
        result: result,
        closureReason: closureReason,
        notes: trimmedNotes,
        recordedAt: closedAt,
      ),
    );
    _cases[caseId] = closed;
    _addEvent(
      caseId,
      CaseAuditEventType.caseClosed,
      trimmedNotes,
      result:
          '${closed.outcome!.resolutionLabel}: ${result.label}. '
          'Reason: ${closureReason.label}.',
      occurredAt: closedAt,
    );
    return closed;
  }

  @override
  Stream<List<CaseAuditEvent>> watchAuditEvents(String caseId) async* {
    yield _eventsFor(caseId);
    yield* _caseChanges.stream
        .where((changedId) => changedId == caseId)
        .map((_) => _eventsFor(caseId));
  }

  void dispose() => _caseChanges.close();

  List<SafetyCase> _snapshot() => List.unmodifiable(_cases.values);

  List<CaseAuditEvent> _eventsFor(String caseId) =>
      List.unmodifiable(_events[caseId] ?? const <CaseAuditEvent>[]);

  ElderConsentContext _consentFor(SafetyCase safetyCase) =>
      mockConsent[safetyCase.elderId] ??
      ElderConsentContext.notRecorded(
        elderId: safetyCase.elderId,
        source: ConsentContextSource.mock,
      );

  SafetyCase _openCase(String caseId) {
    final current = _cases[caseId];
    if (current == null) throw StateError('Safety case was not found.');
    if (current.isClosed) throw StateError('Safety case is already closed.');
    return current;
  }

  void _addEvent(
    String caseId,
    CaseAuditEventType type,
    String note, {
    required String result,
    DateTime? occurredAt,
  }) {
    _events[caseId]!.add(
      CaseAuditEvent(
        id: _nextEventId(),
        caseId: caseId,
        type: type,
        actor: CaseAuditActor.coordinator,
        occurredAt: occurredAt ?? _now(),
        result: result,
        note: note.trim(),
      ),
    );
    _caseChanges.add(caseId);
  }

  String _nextEventId() =>
      'mock_audit_${(++_eventCounter).toString().padLeft(3, '0')}';
}
