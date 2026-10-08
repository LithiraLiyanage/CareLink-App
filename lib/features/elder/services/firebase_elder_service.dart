import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/check_in.dart';
import '../models/check_in_scheduling.dart';
import '../models/memory_item.dart';
import '../models/recurring_schedule.dart';
import 'elder_service.dart';

class ElderFlowContext {
  const ElderFlowContext({
    required this.connectionId,
    required this.matchRequestId,
    required this.elderId,
    required this.elderName,
    required this.companionId,
    required this.companionName,
  });

  final String connectionId;
  final String matchRequestId;
  final String elderId;
  final String elderName;
  final String companionId;
  final String companionName;
}

class FirebaseElderService implements ElderService {
  FirebaseElderService._();

  static final FirebaseElderService instance = FirebaseElderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _companionProfiles =>
      _firestore.collection('companion_profiles');

  CollectionReference<Map<String, dynamic>> get _connections =>
      _firestore.collection('connections');

  CollectionReference<Map<String, dynamic>> get _matchRequests =>
      _firestore.collection('match_requests');

  CollectionReference<Map<String, dynamic>> get _checkIns =>
      _firestore.collection('check_ins');

  CollectionReference<Map<String, dynamic>> get _recurringSchedules =>
      _firestore.collection('recurring_schedules');

  CollectionReference<Map<String, dynamic>> get _memories =>
      _firestore.collection('memories');

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Please sign in before using check-ins.');
    }
    return uid;
  }

  Future<Map<String, dynamic>> _currentUserData() async {
    final snapshot = await _users.doc(_uid).get();
    final data = snapshot.data();

    if (data == null) {
      throw StateError('Your CareLink user profile could not be found.');
    }

    return data;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>>
  _currentConnectionDocument() async {
    final uid = _uid;
    final userData = await _currentUserData();
    final role = userData['role'] as String?;

    Query<Map<String, dynamic>> query;

    if (role == 'Student Companion') {
      query = _connections.where('companionId', isEqualTo: uid);
    } else if (role == 'Older Adult') {
      query = _connections.where('elderId', isEqualTo: uid);
    } else {
      throw StateError(
        'Only an Older Adult or Student Companion can use check-ins.',
      );
    }

    final snapshot = await query.get();

    final active = snapshot.docs
        .where(
          (doc) =>
              doc.data()['status'] == 'active' ||
              doc.data()['status'] == 'paused',
        )
        .toList();

    // Prefer an active connection over a paused one when multiple exist.
    active.sort((a, b) {
      final aIsActive = a.data()['status'] == 'active';
      final bIsActive = b.data()['status'] == 'active';
      if (aIsActive != bIsActive) return aIsActive ? -1 : 1;
      final aStarted = a.data()['startedAt'];
      final bStarted = b.data()['startedAt'];

      if (aStarted is Timestamp && bStarted is Timestamp) {
        return bStarted.compareTo(aStarted);
      }

      return 0;
    });

    if (active.isEmpty) {
      throw StateError(
        role == 'Student Companion'
            ? 'Accept an Elder request before creating check-ins.'
            : 'No active companion connection was found.',
      );
    }

    return active.first;
  }

  Future<ElderFlowContext> getCurrentFlowContext() async {
    final connection = await _currentConnectionDocument();
    final connectionData = connection.data();

    final elderId = connectionData['elderId'] as String? ?? '';
    final companionId = connectionData['companionId'] as String? ?? '';
    final matchRequestId = connectionData['matchRequestId'] as String? ?? '';

    if (elderId.isEmpty || companionId.isEmpty || matchRequestId.isEmpty) {
      throw StateError('The active connection is missing required data.');
    }

    final requestSnapshot = await _matchRequests.doc(matchRequestId).get();
    final requestData = requestSnapshot.data();

    if (requestData == null) {
      throw StateError('The accepted companion request could not be found.');
    }

    final currentUserSnapshot = await _users.doc(_uid).get();
    final currentUserData =
        currentUserSnapshot.data() ?? const <String, dynamic>{};
    final currentRole = currentUserData['role'] as String?;

    String elderName =
        requestData['elderDisplayName'] as String? ?? 'Older Adult';
    String companionName = 'Student Companion';

    if (currentRole == 'Student Companion') {
      companionName =
          currentUserData['fullName'] as String? ?? 'Student Companion';
    } else {
      final profileSnapshot = await _companionProfiles.doc(companionId).get();
      final profileData = profileSnapshot.data() ?? const <String, dynamic>{};
      companionName = profileData['fullName'] as String? ?? 'Student Companion';

      elderName =
          currentUserData['fullName'] as String? ??
          requestData['elderDisplayName'] as String? ??
          'Older Adult';
    }

    return ElderFlowContext(
      connectionId: connection.id,
      matchRequestId: matchRequestId,
      elderId: elderId,
      elderName: elderName,
      companionId: companionId,
      companionName: companionName,
    );
  }

  bool _belongsToCurrentUser(Map<String, dynamic> data) {
    final uid = _uid;
    return data['elderId'] == uid || data['companionId'] == uid;
  }

  Future<void> _requireCurrentParticipant(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final data = snapshot.data();

    if (data == null || !_belongsToCurrentUser(data)) {
      throw StateError('This check-in is not available to your account.');
    }
  }

  // ============================================================
  // CHECK-INS
  // ============================================================

  @override
  Future<List<CheckIn>> getCheckIns() async {
    final context = await getCurrentFlowContext();

    final snapshot = await _checkIns
        .where('elderId', isEqualTo: context.elderId)
        .where('companionId', isEqualTo: context.companionId)
        .get();

    final items = snapshot.docs
        .map((doc) => _checkInFromDocument(doc))
        .toList();

    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }

  @override
  Future<CheckIn?> getCheckInById(String id) async {
    final doc = await _checkIns.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    await _requireCurrentParticipant(doc);
    return _checkInFromDocument(doc);
  }

  // Required by ElderService and the Testing branch's scheduling screens.
  // Create only for a verified, active match; never trust route-supplied IDs.
  @override
  Future<CheckIn> createCheckIn(CheckIn checkIn) async {
    final connection = await _currentConnectionDocument();
    final fields = connection.data();
    if (fields['status'] != 'active' ||
        fields['elderId'] != checkIn.elderId ||
        fields['companionId'] != checkIn.companionId) {
      throw StateError('Choose your currently active companion connection.');
    }
    final validationError = CheckInScheduling.validateSelection(
      scheduledAt: checkIn.scheduledAt,
      durationMinutes: checkIn.durationMinutes,
      mode: checkIn.mode,
    );
    if (validationError != null) throw StateError(validationError);
    final context = await getCurrentFlowContext();
    final ref = checkIn.id.isEmpty
        ? _checkIns.doc()
        : _checkIns.doc(checkIn.id);
    if (checkIn.id.isNotEmpty && (await ref.get()).exists) {
      throw StateError('A check-in with this ID already exists.');
    }
    await ref.set({
      'connectionId': context.connectionId,
      'matchRequestId': context.matchRequestId,
      'elderId': context.elderId,
      'elderName': context.elderName,
      'companionId': context.companionId,
      'companionName': context.companionName,
      'scheduledAt': Timestamp.fromDate(checkIn.scheduledAt),
      'durationMinutes': checkIn.durationMinutes,
      'mode': checkIn.mode,
      'status': CheckInStatus.scheduled.name,
      'reflection': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final created = await ref.get();
    return _checkInFromDocument(created);
  }

  Future<CheckIn> createInitialCheckInForSchedule(
    RecurringSchedule schedule,
  ) async {
    final context = await getCurrentFlowContext();

    final scheduledAt = _nextOccurrence(
      schedule.weekdays,
      schedule.hour,
      schedule.minute,
    );

    final ref = _checkIns.doc();

    await ref.set({
      'connectionId': context.connectionId,
      'matchRequestId': context.matchRequestId,
      'elderId': context.elderId,
      'elderName': context.elderName,
      'companionId': context.companionId,
      'companionName': context.companionName,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'durationMinutes': schedule.durationMinutes,
      'mode': 'Video',
      'status': CheckInStatus.scheduled.name,
      'reflection': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final created = await ref.get();
    return _checkInFromDocument(created);
  }

  @override
  Future<CheckIn> rescheduleCheckIn(
    String checkInId,
    DateTime newDateTime,
  ) async {
    final ref = _checkIns.doc(checkInId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw StateError('Check-in not found: $checkInId');
    }

    await _requireCurrentParticipant(snapshot);

    await ref.update({
      'scheduledAt': Timestamp.fromDate(newDateTime),
      'status': CheckInStatus.ready.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updated = await ref.get();
    return _checkInFromDocument(updated);
  }

  @override
  Future<CheckIn> updateCheckInStatus(
    String checkInId,
    CheckInStatus status, {
    String? reflection,
  }) async {
    final ref = _checkIns.doc(checkInId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw StateError('Check-in not found: $checkInId');
    }

    await _requireCurrentParticipant(snapshot);

    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == CheckInStatus.inProgress)
        'startedAt': FieldValue.serverTimestamp(),
      if (status == CheckInStatus.completed)
        'completedAt': FieldValue.serverTimestamp(),
    };

    if (reflection != null) {
      data['reflection'] = reflection;
    }

    await ref.update(data);

    final updated = await ref.get();
    return _checkInFromDocument(updated);
  }

  @override
  Future<void> cancelCheckIn(String checkInId) async {
    await updateCheckInStatus(checkInId, CheckInStatus.cancelled);
  }

  // ============================================================
  // RECURRING SCHEDULES
  // ============================================================

  @override
  Future<List<RecurringSchedule>> getRecurringSchedules() async {
    final context = await getCurrentFlowContext();

    final snapshot = await _recurringSchedules
        .where('elderId', isEqualTo: context.elderId)
        .where('companionId', isEqualTo: context.companionId)
        .get();

    return snapshot.docs
        .map((doc) => _recurringScheduleFromDocument(doc))
        .toList();
  }

  @override
  Future<RecurringSchedule> createRecurringSchedule(
    RecurringSchedule schedule,
  ) async {
    final context = await getCurrentFlowContext();

    final DocumentReference<Map<String, dynamic>> ref = schedule.id.isEmpty
        ? _recurringSchedules.doc()
        : _recurringSchedules.doc(schedule.id);

    final createdSchedule = schedule.copyWith(
      id: ref.id,
      elderId: context.elderId,
      elderName: context.elderName,
      companionId: context.companionId,
      companionName: context.companionName,
    );

    await ref.set({
      'connectionId': context.connectionId,
      'matchRequestId': context.matchRequestId,
      'elderId': createdSchedule.elderId,
      'elderName': createdSchedule.elderName,
      'companionId': createdSchedule.companionId,
      'companionName': createdSchedule.companionName,
      'weekdays': createdSchedule.weekdays,
      'hour': createdSchedule.hour,
      'minute': createdSchedule.minute,
      'durationMinutes': createdSchedule.durationMinutes,
      'isActive': createdSchedule.isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return createdSchedule;
  }

  @override
  Future<void> deleteRecurringSchedule(String scheduleId) async {
    final snapshot = await _recurringSchedules.doc(scheduleId).get();
    final data = snapshot.data();

    if (data == null || !_belongsToCurrentUser(data)) {
      throw StateError('This recurring schedule is not available to you.');
    }

    await snapshot.reference.delete();
  }

  // ============================================================
  // MEMORIES
  // ============================================================

  @override
  Future<List<MemoryItem>> getMemories() async {
    final context = await getCurrentFlowContext();
    final uid = _uid;

    // Query only documents the rules can prove this user may read.
    // Querying the whole pair would expose 'Only me' memories and be denied.
    final owned = await _memories.where('ownerId', isEqualTo: uid).get();

    Query<Map<String, dynamic>> sharedQuery;
    if (uid == context.companionId) {
      sharedQuery = _memories
          .where('companionId', isEqualTo: uid)
          .where('visibility', isEqualTo: 'Companion');
    } else {
      sharedQuery = _memories
          .where('elderId', isEqualTo: uid)
          .where('visibility', isEqualTo: 'Companion');
    }
    final shared = await sharedQuery.get();

    final unique = <String, MemoryItem>{};
    for (final doc in [...owned.docs, ...shared.docs]) {
      final data = doc.data();
      if (data['elderId'] != context.elderId ||
          data['companionId'] != context.companionId) {
        continue;
      }
      unique[doc.id] = _memoryFromDocument(doc);
    }

    final items = unique.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<MemoryItem> addMemory(MemoryItem memory) async {
    final context = await getCurrentFlowContext();

    final DocumentReference<Map<String, dynamic>> ref = memory.id.isEmpty
        ? _memories.doc()
        : _memories.doc(memory.id);

    final currentUid = _uid;
    final createdMemory = memory.copyWith(id: ref.id, ownerId: currentUid);

    // The rules allow editing only content fields, not the connection/owner IDs.
    // Use update() for an existing memory; set() would rewrite server metadata.
    if (memory.id.isNotEmpty) {
      final previous = await ref.get();
      if (previous.data()?['ownerId'] != currentUid) {
        throw StateError('Only the memory creator can edit it.');
      }
      await ref.update({
        'title': createdMemory.title,
        'caption': createdMemory.caption,
        'mediaPath': createdMemory.mediaPath,
        'memoryDate': Timestamp.fromDate(createdMemory.memoryDate),
        'visibility': createdMemory.visibility,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return createdMemory;
    }

    await ref.set({
      'connectionId': context.connectionId,
      'matchRequestId': context.matchRequestId,
      'elderId': context.elderId,
      'companionId': context.companionId,
      'ownerId': currentUid,
      'type': createdMemory.type.name,
      'title': createdMemory.title,
      'caption': createdMemory.caption,
      'mediaPath': createdMemory.mediaPath,
      'memoryDate': Timestamp.fromDate(createdMemory.memoryDate),
      'createdAt': Timestamp.fromDate(createdMemory.createdAt),
      'visibility': createdMemory.visibility,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return createdMemory;
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    final snapshot = await _memories.doc(memoryId).get();
    final data = snapshot.data();

    if (data == null ||
        !_belongsToCurrentUser(data) ||
        data['ownerId'] != _uid) {
      throw StateError('Only the memory creator can delete it.');
    }

    await snapshot.reference.delete();
  }

  // ============================================================
  // FIRESTORE -> MODEL
  // ============================================================

  CheckIn _checkInFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Check-in document has no data: ${doc.id}');
    }

    return CheckIn(
      id: doc.id,
      elderId: data['elderId'] as String? ?? '',
      elderName: data['elderName'] as String? ?? '',
      companionId: data['companionId'] as String? ?? '',
      companionName: data['companionName'] as String? ?? '',
      scheduledAt: _dateTimeFromFirestore(data['scheduledAt']),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      mode: data['mode'] as String? ?? 'Video',
      status: _checkInStatusFromString(data['status'] as String?),
      reflection: data['reflection'] as String?,
    );
  }

  RecurringSchedule _recurringScheduleFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Recurring schedule document has no data: ${doc.id}');
    }

    final rawWeekdays = data['weekdays'];

    final weekdays = rawWeekdays is List
        ? rawWeekdays.whereType<num>().map((value) => value.toInt()).toList()
        : <int>[];

    return RecurringSchedule(
      id: doc.id,
      elderId: data['elderId'] as String? ?? '',
      elderName: data['elderName'] as String? ?? '',
      companionId: data['companionId'] as String? ?? '',
      companionName: data['companionName'] as String? ?? '',
      weekdays: weekdays,
      hour: (data['hour'] as num?)?.toInt() ?? 18,
      minute: (data['minute'] as num?)?.toInt() ?? 30,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  MemoryItem _memoryFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Memory document has no data: ${doc.id}');
    }

    return MemoryItem(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      type: _memoryTypeFromString(data['type'] as String?),
      title: data['title'] as String? ?? '',
      caption: data['caption'] as String?,
      mediaPath: data['mediaPath'] as String?,
      memoryDate: _dateTimeFromFirestore(data['memoryDate']),
      createdAt: _dateTimeFromFirestore(data['createdAt']),
      visibility: data['visibility'] as String? ?? 'Only me',
    );
  }

  DateTime _dateTimeFromFirestore(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  CheckInStatus _checkInStatusFromString(String? value) {
    for (final status in CheckInStatus.values) {
      if (status.name == value) {
        return status;
      }
    }

    return CheckInStatus.scheduled;
  }

  MemoryType _memoryTypeFromString(String? value) {
    for (final type in MemoryType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return MemoryType.photo;
  }

  DateTime _nextOccurrence(List<int> weekdays, int hour, int minute) {
    if (weekdays.isEmpty) {
      throw StateError('Select at least one day for the recurring check-in.');
    }

    final now = DateTime.now();

    for (int offset = 0; offset < 14; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset, hour, minute);

      if (weekdays.contains(day.weekday) && day.isAfter(now)) {
        return day;
      }
    }

    throw StateError('Could not calculate the next check-in time.');
  }

  @Deprecated(
    'Do not seed demo data into the shared CareLink Firebase project.',
  )
  Future<void> seedDemoDataIfEmpty() async {}
}

// Compatibility types and APIs for the Testing branch.
class ElderConnectionDetails {
  const ElderConnectionDetails({
    required this.id,
    required this.elderId,
    required this.elderName,
    required this.companionId,
    required this.companionName,
    required this.companionImageUrl,
    required this.companionVerified,
  });

  final String id;
  final String elderId;
  final String elderName;
  final String companionId;
  final String companionName;
  final String companionImageUrl;
  final bool companionVerified;
}

class ElderScheduleData {
  const ElderScheduleData({
    required this.checkIns,
    required this.recurringSchedules,
  });

  final List<CheckIn> checkIns;
  final List<RecurringSchedule> recurringSchedules;
}

// Keep tested Student Companion writes in FirebaseElderService unchanged.
extension ElderTestingCompatibility on FirebaseElderService {
  Future<String> getCurrentElderName() async {
    final user = await _firestore.collection('users').doc(_uid).get();
    if (!user.exists) {
      throw StateError('Your CareLink user profile could not be found.');
    }
    return user.data()?['fullName'] as String? ?? '';
  }

  Future<ElderConnectionDetails?> getActiveConnectionForCurrentElder() async {
    final snapshot = await _firestore
        .collection('connections')
        .where('elderId', isEqualTo: _uid)
        .get();
    return _activeConnectionFromDocuments(snapshot.docs);
  }

  Stream<ElderConnectionDetails?> watchActiveConnectionForCurrentElder() {
    return _firestore
        .collection('connections')
        .where('elderId', isEqualTo: _uid)
        .snapshots()
        .asyncMap((snapshot) => _activeConnectionFromDocuments(snapshot.docs));
  }

  Future<ElderConnectionDetails?> _activeConnectionFromDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    QueryDocumentSnapshot<Map<String, dynamic>>? active;
    for (final document in documents) {
      if (document.data()['status'] == 'active') {
        active = document;
        break;
      }
    }
    if (active == null) return null;

    final elderId = active.data()['elderId'] as String? ?? _uid;
    final companionId = active.data()['companionId'] as String? ?? '';
    final user = await _firestore.collection('users').doc(elderId).get();
    final profile = companionId.isEmpty
        ? null
        : await _firestore
              .collection('companion_profiles')
              .doc(companionId)
              .get();
    final profileData = profile?.data();
    return ElderConnectionDetails(
      id: active.id,
      elderId: elderId,
      elderName: user.data()?['fullName'] as String? ?? '',
      companionId: companionId,
      companionName: profileData?['fullName'] as String? ?? '',
      companionImageUrl: profileData?['profileImageUrl'] as String? ?? '',
      companionVerified:
          profileData?['verificationStatus'] == 'verified' &&
          profileData?['active'] == true,
    );
  }

  Stream<ElderScheduleData> watchScheduleForConnection({
    required String elderId,
    required String companionId,
    required String connectionId,
  }) {
    late final StreamController<ElderScheduleData> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? checkIns;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? schedules;
    List<CheckIn>? latestCheckIns;
    List<RecurringSchedule>? latestSchedules;

    void emitIfReady() {
      if (latestCheckIns != null && latestSchedules != null) {
        controller.add(
          ElderScheduleData(
            checkIns: latestCheckIns!,
            recurringSchedules: latestSchedules!,
          ),
        );
      }
    }

    controller = StreamController<ElderScheduleData>(
      onListen: () {
        checkIns = _checkIns
            .where('elderId', isEqualTo: elderId)
            .where('companionId', isEqualTo: companionId)
            .snapshots()
            .listen((snapshot) {
              latestCheckIns =
                  snapshot.docs
                      .map(_checkInFromDocument)
                      .where(
                        (checkIn) => checkIn.status != CheckInStatus.cancelled,
                      )
                      .toList()
                    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
              emitIfReady();
            }, onError: controller.addError);
        schedules = _recurringSchedules
            .where('elderId', isEqualTo: elderId)
            .where('companionId', isEqualTo: companionId)
            .where('connectionId', isEqualTo: connectionId)
            .where('isActive', isEqualTo: true)
            .snapshots()
            .listen((snapshot) {
              latestSchedules = snapshot.docs
                  .map(_recurringScheduleFromDocument)
                  .toList(growable: false);
              emitIfReady();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await checkIns?.cancel();
        await schedules?.cancel();
      },
    );
    return controller.stream;
  }
}
