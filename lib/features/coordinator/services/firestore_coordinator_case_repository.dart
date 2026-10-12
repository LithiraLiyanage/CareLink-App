import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../elder/models/check_in.dart';
import '../../family_safety/services/family_check_in_service.dart';
import '../models/case_audit_event.dart';
import '../models/case_outcome.dart';
import '../models/elder_consent_context.dart';
import '../models/safety_case.dart';
import 'coordinator_case_repository.dart';

/// Safety cases stored in Firestore, opened from real missed check-ins.
///
/// Layout (see the SAFETY CASES section of `firestore.rules`):
///   safety_cases/{checkInId}                  one case per missed check-in
///   safety_cases/{checkInId}/audit_events/*   append-only timeline
///   counters/safety_cases                     `next` case number
///
/// There is no backend trigger, so a coordinator's case list opens a case for
/// every missed check-in that does not have one yet. The case id is the
/// check-in id, so a check-in can never get two cases. Every case change is
/// written in the same transaction as its audit event.
class FirestoreCoordinatorCaseRepository implements CoordinatorCaseRepository {
  FirestoreCoordinatorCaseRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestoreOverride = firestore,
       _authOverride = auth;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  // Resolved lazily so building the app never touches an uninitialised
  // Firebase instance.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _cases =>
      _firestore.collection('safety_cases');

  DocumentReference<Map<String, dynamic>> get _counter =>
      _firestore.collection('counters').doc('safety_cases');

  /// Check-ins whose case is queued or being opened, so overlapping snapshots
  /// do not queue the same check-in twice.
  final Set<String> _opening = {};

  /// Cases are opened one at a time: each takes the next case number, so
  /// concurrent transactions would conflict on the counter.
  Future<void> _openQueue = Future.value();

  /// Check-in statuses that can mean "missed"; scheduled and ready ones only
  /// count once their slot has ended (see [FamilyCheckInService.isMissed]).
  static const _possiblyMissedStatuses = ['missed', 'scheduled', 'ready'];

  @override
  bool get usesMockData => false;

  @override
  Stream<List<SafetyCase>> watchCases() {
    late final StreamController<List<SafetyCase>> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    // Check-ins that already have a case, so they are not re-checked on every
    // check-in snapshot.
    final knownCaseIds = <String>{};
    var checkInDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    void fail(Object error, StackTrace stackTrace) =>
        controller.addError(_describe(error), stackTrace);

    // Re-run on both snapshots, so an opening that failed (e.g. lost a race
    // with another coordinator) is retried when the cases change.
    void openMissingCases() {
      final now = DateTime.now();
      for (final doc in checkInDocs) {
        final checkIn = _checkInFromDocument(doc);
        if (checkIn != null &&
            !knownCaseIds.contains(checkIn.id) &&
            FamilyCheckInService.isMissed(checkIn, now)) {
          _queueOpenCase(
            checkIn,
            doc.data()['scheduledAt'] as Timestamp,
          ).catchError(fail);
        }
      }
    }

    controller = StreamController<List<SafetyCase>>(
      onListen: () {
        try {
          subscriptions
            ..add(
              _cases.snapshots().listen((snapshot) {
                knownCaseIds
                  ..clear()
                  ..addAll(snapshot.docs.map((doc) => doc.id));
                final cases =
                    snapshot.docs
                        .map(_caseFromDocument)
                        .whereType<SafetyCase>()
                        .toList()
                      ..sort((a, b) => b.caseNumber.compareTo(a.caseNumber));
                controller.add(List.unmodifiable(cases));
                openMissingCases();
              }, onError: fail),
            )
            ..add(
              _firestore
                  .collection('check_ins')
                  .where('status', whereIn: _possiblyMissedStatuses)
                  .snapshots()
                  .listen((snapshot) {
                    checkInDocs = snapshot.docs;
                    openMissingCases();
                  }, onError: fail),
            );
        } on Object catch (error, stackTrace) {
          // e.g. Firebase not initialised: show it as a load error.
          fail(error, stackTrace);
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<SafetyCase?> getCase(String caseId) async {
    try {
      return _caseFromDocument(await _cases.doc(caseId).get());
    } on FirebaseException catch (error) {
      throw _describe(error);
    }
  }

  @override
  Future<ElderConsentContext?> getConsentContext(String caseId) async {
    final safetyCase = await getCase(caseId);
    if (safetyCase == null) return null;
    try {
      return await _consentFor(safetyCase.elderId);
    } on FirebaseException catch (error) {
      throw _describe(error);
    }
  }

  @override
  Future<SafetyCase> recordCaseAction({
    required String caseId,
    required CaseAction action,
    String note = '',
  }) async {
    final current = await _openCase(caseId);
    if (action.requiresApprovedContact &&
        !(await _consentFor(current.elderId)).canContactApprovedPerson) {
      throw StateError('No approved contact is recorded for this elder.');
    }
    final updated = current.copyWith(
      status: action.resultingStatus,
      previousAttempts: action == CaseAction.retryCheckIn
          ? current.previousAttempts + 1
          : null,
    );
    final status = action.resultingStatus;
    await _commit(
      caseId,
      expected: current,
      changes: {
        'status': updated.status.name,
        'previousAttempts': updated.previousAttempts,
      },
      event: _eventData(
        type: action.auditEventType,
        actor: CaseAuditActor.coordinator,
        result: status == null
            ? 'Status unchanged (${updated.status.label})'
            : 'Status set to ${status.label}',
        note: note,
      ),
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
    final current = await _openCase(caseId);
    if ((actionTaken == CaseActionTaken.contactedApprovedPerson ||
            result.requiresApprovedContact) &&
        !(await _consentFor(current.elderId)).canContactApprovedPerson) {
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
    final closedAt = DateTime.now();
    final outcome = CaseOutcome(
      actionTaken: actionTaken,
      result: result,
      closureReason: closureReason,
      notes: trimmedNotes,
      recordedAt: closedAt,
    );
    await _commit(
      caseId,
      expected: current,
      changes: {
        'status': SafetyCaseStatus.closed.name,
        'closedAt': FieldValue.serverTimestamp(),
        'outcome': {
          'actionTaken': actionTaken.name,
          'result': result.name,
          'closureReason': closureReason.name,
          'notes': trimmedNotes,
          'recordedAt': FieldValue.serverTimestamp(),
        },
      },
      event: _eventData(
        type: CaseAuditEventType.caseClosed,
        actor: CaseAuditActor.coordinator,
        result:
            '${outcome.resolutionLabel}: ${result.label}. '
            'Reason: ${closureReason.label}.',
        note: trimmedNotes,
      ),
    );
    return current.copyWith(
      status: SafetyCaseStatus.closed,
      closedAt: closedAt,
      outcome: outcome,
    );
  }

  @override
  Stream<List<CaseAuditEvent>> watchAuditEvents(String caseId) => _cases
      .doc(caseId)
      .collection('audit_events')
      .orderBy('occurredAt')
      .snapshots()
      .handleError((Object error) => throw _describe(error))
      .map(
        (snapshot) => List.unmodifiable(
          snapshot.docs
              .map((doc) => _eventFromDocument(caseId, doc))
              .whereType<CaseAuditEvent>(),
        ),
      );

  /// Queues [_openCaseFor] behind any case already being opened. A failed
  /// opening is retried on a later check-in snapshot.
  Future<void> _queueOpenCase(CheckIn checkIn, Timestamp scheduledAt) {
    if (!_opening.add(checkIn.id)) return Future.value();
    final opened = _openQueue
        .then((_) => _openCaseFor(checkIn, scheduledAt))
        .whenComplete(() => _opening.remove(checkIn.id));
    _openQueue = opened.catchError((Object _) {});
    return opened;
  }

  /// Opens a case for [checkIn] unless one exists. Safe to call repeatedly.
  ///
  /// [scheduledAt] is the check-in's stored value, copied unchanged because
  /// the rules require it to match exactly (a DateTime round trip can drop
  /// sub-microsecond precision).
  Future<void> _openCaseFor(CheckIn checkIn, Timestamp scheduledAt) async {
    try {
      final caseRef = _cases.doc(checkIn.id);
      if ((await caseRef.get()).exists) return;
      await _firestore.runTransaction((transaction) async {
        // Re-read inside the transaction: another coordinator may have opened
        // the case after the check above.
        if ((await transaction.get(caseRef)).exists) return;
        final counter = await transaction.get(_counter);
        final caseNumber =
            ((counter.data()?['next'] as num?)?.toInt() ?? 0) + 1;
        transaction
          ..set(_counter, {'next': caseNumber})
          ..set(caseRef, {
            'checkInId': checkIn.id,
            'elderId': checkIn.elderId,
            'elderName': checkIn.elderName,
            'caseNumber': caseNumber,
            'status': SafetyCaseStatus.pendingReview.name,
            'scheduledAt': scheduledAt,
            'previousAttempts': 0,
            'openedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': _uid,
          })
          ..set(
            caseRef.collection('audit_events').doc(),
            _eventData(
              type: CaseAuditEventType.checkInMissed,
              actor: CaseAuditActor.system,
              result: 'Safety case opened',
            ),
          );
      });
    } on FirebaseException catch (error) {
      throw _describe(error);
    }
  }

  /// Applies [changes] and appends [event] in one transaction, failing if the
  /// case changed since [expected] was read (e.g. another coordinator closed
  /// it), so actions are never recorded against a stale case.
  Future<void> _commit(
    String caseId, {
    required SafetyCase expected,
    required Map<String, Object?> changes,
    required Map<String, Object?> event,
  }) async {
    final caseRef = _cases.doc(caseId);
    try {
      await _firestore.runTransaction((transaction) async {
        final latest = _caseFromDocument(await transaction.get(caseRef));
        if (latest == null) throw StateError('Safety case was not found.');
        if (latest.isClosed) {
          throw StateError('Safety case is already closed.');
        }
        if (latest.status != expected.status ||
            latest.previousAttempts != expected.previousAttempts) {
          throw StateError(
            'This case was updated by someone else. Reopen it and try again.',
          );
        }
        transaction
          ..update(caseRef, {
            ...changes,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': _uid,
          })
          ..set(caseRef.collection('audit_events').doc(), event);
      });
    } on FirebaseException catch (error) {
      throw _describe(error);
    }
  }

  Future<SafetyCase> _openCase(String caseId) async {
    final current = await getCase(caseId);
    if (current == null) throw StateError('Safety case was not found.');
    if (current.isClosed) throw StateError('Safety case is already closed.');
    return current;
  }

  /// Consent from the elder's own `consents` record; the approved contact is
  /// a Family Caregiver the elder accepted a family link with. Nothing is
  /// assumed when either is missing.
  Future<ElderConsentContext> _consentFor(String elderId) async {
    final results = await Future.wait([
      _firestore.collection('consents').doc(elderId).get(),
      _firestore
          .collection('family_links')
          .where('elderId', isEqualTo: elderId)
          .get(),
    ]);
    final consent = (results[0] as DocumentSnapshot<Map<String, dynamic>>)
        .data();
    final links =
        (results[1] as QuerySnapshot<Map<String, dynamic>>).docs
            .map((doc) => doc.data())
            .toList()
          ..sort(
            (a, b) => (_date(a['createdAt']) ?? DateTime(0)).compareTo(
              _date(b['createdAt']) ?? DateTime(0),
            ),
          );

    final familyLinkConsent = consent?['familyLinkConsent'];
    if (consent == null || familyLinkConsent is! bool) {
      return ElderConsentContext.notRecorded(
        elderId: elderId,
        source: ConsentContextSource.firestore,
      );
    }
    final lastUpdatedAt = _date(consent['updatedAt']);
    if (!familyLinkConsent) {
      return ElderConsentContext(
        elderId: elderId,
        familySharing: ConsentSharingStatus.withdrawn,
        lastUpdatedAt: lastUpdatedAt,
        source: ConsentContextSource.firestore,
      );
    }

    final link = links.firstOrNull;
    return ElderConsentContext(
      elderId: elderId,
      familySharing: ConsentSharingStatus.approved,
      approvedContact: link == null
          ? null
          : ApprovedContact(
              id: link['caregiverId'] as String? ?? '',
              name: link['caregiverName'] as String? ?? 'Family member',
              relationship: link['relationship'] as String? ?? 'Family',
            ),
      validFrom: link == null ? null : _date(link['createdAt']),
      lastUpdatedAt: lastUpdatedAt,
      // What a linked Family Caregiver can read under the family rules.
      allowedInformation: const ['Check-in status', 'Schedule information'],
      restrictedInformation: const [
        'Private conversation content',
        'Memories and personal notes',
      ],
      source: ConsentContextSource.firestore,
    );
  }

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in as a coordinator to continue.');
    return uid;
  }

  Map<String, Object?> _eventData({
    required CaseAuditEventType type,
    required CaseAuditActor actor,
    required String result,
    String note = '',
  }) => {
    'type': type.name,
    'actor': actor.name,
    'actorUid': _uid,
    'occurredAt': FieldValue.serverTimestamp(),
    'result': result,
    'note': note.trim(),
  };

  /// The case in [doc], or null when it is missing or has unknown values, so
  /// a malformed document is never shown with guessed fields.
  SafetyCase? _caseFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final status = _enumByName(SafetyCaseStatus.values, data['status']);
    final scheduledAt = _date(data['scheduledAt']);
    final openedAt = _writtenDate(data['openedAt'], doc.metadata);
    final caseNumber = data['caseNumber'];
    if (status == null ||
        scheduledAt == null ||
        openedAt == null ||
        caseNumber is! num) {
      return null;
    }
    final elderId = data['elderId'] as String? ?? '';
    return SafetyCase(
      id: doc.id,
      caseNumber: caseNumber.toInt(),
      elderId: elderId,
      elderReference: _elderReference(elderId),
      elderDisplayName: data['elderName'] as String? ?? 'Unknown elder',
      status: status,
      scheduledAt: scheduledAt,
      previousAttempts: (data['previousAttempts'] as num?)?.toInt() ?? 0,
      openedAt: openedAt,
      closedAt: status.isClosed
          ? _writtenDate(data['closedAt'], doc.metadata)
          : _date(data['closedAt']),
      outcome: _outcomeFrom(data['outcome'], doc.metadata),
    );
  }

  CaseOutcome? _outcomeFrom(Object? value, SnapshotMetadata metadata) {
    if (value is! Map) return null;
    final actionTaken = _enumByName(
      CaseActionTaken.values,
      value['actionTaken'],
    );
    final result = _enumByName(CaseOutcomeResult.values, value['result']);
    final closureReason = _enumByName(
      CaseClosureReason.values,
      value['closureReason'],
    );
    final recordedAt = _writtenDate(value['recordedAt'], metadata);
    if (actionTaken == null ||
        result == null ||
        closureReason == null ||
        recordedAt == null) {
      return null;
    }
    return CaseOutcome(
      actionTaken: actionTaken,
      result: result,
      closureReason: closureReason,
      notes: value['notes'] as String? ?? '',
      recordedAt: recordedAt,
    );
  }

  CaseAuditEvent? _eventFromDocument(
    String caseId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final type = _enumByName(CaseAuditEventType.values, data['type']);
    final actor = _enumByName(CaseAuditActor.values, data['actor']);
    final occurredAt = _writtenDate(data['occurredAt'], doc.metadata);
    if (type == null || actor == null || occurredAt == null) return null;
    return CaseAuditEvent(
      id: doc.id,
      caseId: caseId,
      type: type,
      actor: actor,
      occurredAt: occurredAt,
      result: data['result'] as String? ?? '',
      note: data['note'] as String? ?? '',
    );
  }

  CheckIn? _checkInFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final scheduledAt = _date(data['scheduledAt']);
    final status = _enumByName(CheckInStatus.values, data['status']);
    final elderId = data['elderId'];
    if (scheduledAt == null || status == null || elderId is! String) {
      return null;
    }
    return CheckIn(
      id: doc.id,
      elderId: elderId,
      elderName: data['elderName'] as String? ?? '',
      companionId: data['companionId'] as String? ?? '',
      companionName: data['companionName'] as String? ?? '',
      scheduledAt: scheduledAt,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      mode: data['mode'] as String? ?? 'Video',
      status: status,
    );
  }

  /// Short, stable "Elder ID" shown on case screens, derived from the UID so
  /// the full UID is not displayed.
  static String _elderReference(String elderId) => elderId.isEmpty
      ? 'Unknown'
      : 'EL-${elderId.substring(0, elderId.length.clamp(0, 6)).toUpperCase()}';

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) =>
      values.where((value) => value.name == name).firstOrNull;

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  /// Like [_date], but a server timestamp this client has just written (still
  /// null locally until the server confirms it) reads as now.
  static DateTime? _writtenDate(Object? value, SnapshotMetadata metadata) =>
      _date(value) ??
      (value == null && metadata.hasPendingWrites ? DateTime.now() : null);

  static Object _describe(Object error) {
    if (error is StateError) return error;
    if (error is FirebaseException && error.code == 'permission-denied') {
      return StateError(
        'Coordinator access was denied. Sign in with a Coordinator or Admin '
        'account.',
      );
    }
    if (error is FirebaseException && error.code == 'unavailable') {
      return StateError('You appear to be offline. Try again when connected.');
    }
    return error;
  }
}
