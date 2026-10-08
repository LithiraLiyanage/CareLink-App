import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/check_in.dart';
import '../models/check_in_scheduling.dart';
import '../models/memory_item.dart';
import '../models/recurring_schedule.dart';
import 'elder_service.dart';

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

class FirebaseElderService implements ElderService {
  FirebaseElderService._();

  static final FirebaseElderService instance = FirebaseElderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _checkIns =>
      _firestore.collection('check_ins');

  CollectionReference<Map<String, dynamic>> get _recurringSchedules =>
      _firestore.collection('recurring_schedules');

  CollectionReference<Map<String, dynamic>> get _memories =>
      _firestore.collection('memories');

  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Please sign in before viewing check-ins.');
    }
    return uid;
  }

  Future<String> getCurrentElderName() async {
    final user = await _firestore.collection('users').doc(_currentUid).get();
    if (!user.exists) {
      throw StateError('Your CareLink user profile could not be found.');
    }
    return user.data()?['fullName'] as String? ?? '';
  }

  Future<ElderConnectionDetails?> getActiveConnectionForCurrentElder() async {
    final snapshot = await _firestore
        .collection('connections')
        .where('elderId', isEqualTo: _currentUid)
        .get();
    return _activeConnectionFromDocuments(snapshot.docs);
  }

  Stream<ElderConnectionDetails?> watchActiveConnectionForCurrentElder() {
    return _firestore
        .collection('connections')
        .where('elderId', isEqualTo: _currentUid)
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

    final elderId = active.data()['elderId'] as String? ?? _currentUid;
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

  // ============================================================
  // CHECK-INS
  // ============================================================

  @override
  Future<List<CheckIn>> getCheckIns() async {
    final snapshot = await _checkIns
        .where('elderId', isEqualTo: _currentUid)
        .get();

    final checkIns = snapshot.docs.map(_checkInFromDocument).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return checkIns;
  }

  Future<List<CheckIn>> getCheckInsForConnection({
    required String elderId,
    required String companionId,
  }) async {
    final snapshot = await _checkIns
        .where('elderId', isEqualTo: elderId)
        .where('companionId', isEqualTo: companionId)
        .get();
    final checkIns =
        snapshot.docs
            .map(_checkInFromDocument)
            .where((checkIn) => checkIn.status != CheckInStatus.cancelled)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return checkIns;
  }

  @override
  Future<CheckIn?> getCheckInById(String id) async {
    final doc = await _checkIns.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return _checkInFromDocument(doc);
  }

  @override
  Future<CheckIn> createCheckIn(CheckIn checkIn) async {
    final connection = await getActiveConnectionForCurrentElder();
    if (connection == null) {
      throw StateError(
        'An active companion connection is required to schedule.',
      );
    }
    if (checkIn.elderId != connection.elderId ||
        checkIn.companionId != connection.companionId) {
      throw StateError(
        'This check-in must use your active companion connection.',
      );
    }

    final error = CheckInScheduling.validateSelection(
      scheduledAt: checkIn.scheduledAt,
      durationMinutes: checkIn.durationMinutes,
      mode: checkIn.mode,
    );
    if (error != null) {
      throw StateError(error);
    }

    final ref = checkIn.id.isEmpty ? _checkIns.doc() : _checkIns.doc(checkIn.id);
    final created = checkIn.copyWith(
      id: ref.id,
      elderName: checkIn.elderName.trim().isEmpty
          ? connection.elderName
          : checkIn.elderName,
      companionName: checkIn.companionName.trim().isEmpty
          ? connection.companionName
          : checkIn.companionName,
      status: CheckInStatus.scheduled,
    );

    await ref.set(_checkInDocumentData(created));
    return created;
  }

  Map<String, dynamic> _checkInDocumentData(CheckIn checkIn) {
    return {
      'elderId': checkIn.elderId,
      'elderName': checkIn.elderName,
      'elderImageUrl': checkIn.elderImageUrl,
      'companionId': checkIn.companionId,
      'companionName': checkIn.companionName,
      'scheduledAt': Timestamp.fromDate(checkIn.scheduledAt),
      'durationMinutes': checkIn.durationMinutes,
      'mode': checkIn.mode,
      'status': CheckInStatus.scheduled.name,
      'reflection': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> createScheduleWithFirstCheckIn({
    required RecurringSchedule schedule,
    required CheckIn checkIn,
  }) async {
    final connectionId = schedule.connectionId;
    if (connectionId == null || connectionId.isEmpty) {
      throw StateError('An active connection is required to schedule.');
    }

    final scheduleRef = schedule.id.isEmpty
        ? _recurringSchedules.doc()
        : _recurringSchedules.doc(schedule.id);
    final checkInRef = checkIn.id.isEmpty
        ? _checkIns.doc()
        : _checkIns.doc(checkIn.id);

    final createdSchedule = schedule.copyWith(id: scheduleRef.id);
    final createdCheckIn = checkIn.copyWith(
      id: checkInRef.id,
      status: CheckInStatus.scheduled,
    );

    final batch = _firestore.batch();

    batch.set(scheduleRef, {
      'elderId': createdSchedule.elderId,
      'elderName': createdSchedule.elderName,
      'companionId': createdSchedule.companionId,
      'companionName': createdSchedule.companionName,
      'connectionId': connectionId,
      'mode': createdSchedule.mode,
      'weekdays': createdSchedule.weekdays,
      'hour': createdSchedule.hour,
      'minute': createdSchedule.minute,
      'durationMinutes': createdSchedule.durationMinutes,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(checkInRef, _checkInDocumentData(createdCheckIn));

    await batch.commit();
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

    final existing = _checkInFromDocument(snapshot);
    final error = CheckInScheduling.validateSelection(
      scheduledAt: newDateTime,
      durationMinutes: existing.durationMinutes,
      mode: existing.mode,
    );
    if (error != null) {
      throw StateError(error);
    }

    await ref.update({
      'scheduledAt': Timestamp.fromDate(newDateTime),
      'status': CheckInStatus.scheduled.name,
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

    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
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
    final snapshot = await _recurringSchedules
        .where('elderId', isEqualTo: _currentUid)
        .get();

    return snapshot.docs
        .map((doc) => _recurringScheduleFromDocument(doc))
        .toList();
  }

  Future<List<RecurringSchedule>> getRecurringSchedulesForConnection({
    required String elderId,
    required String companionId,
    required String connectionId,
  }) async {
    final snapshot = await _recurringSchedules
        .where('elderId', isEqualTo: elderId)
        .where('companionId', isEqualTo: companionId)
        .where('connectionId', isEqualTo: connectionId)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map(_recurringScheduleFromDocument)
        .toList(growable: false);
  }

  @override
  Future<RecurringSchedule> createRecurringSchedule(
    RecurringSchedule schedule,
  ) async {
    final DocumentReference<Map<String, dynamic>> ref = schedule.id.isEmpty
        ? _recurringSchedules.doc()
        : _recurringSchedules.doc(schedule.id);

    final createdSchedule = schedule.copyWith(id: ref.id);

    await ref.set({
      'elderId': createdSchedule.elderId,
      'elderName': createdSchedule.elderName,
      'companionId': createdSchedule.companionId,
      'companionName': createdSchedule.companionName,
      'connectionId': createdSchedule.connectionId,
      'mode': createdSchedule.mode,
      'weekdays': createdSchedule.weekdays,
      'hour': createdSchedule.hour,
      'minute': createdSchedule.minute,
      'durationMinutes': createdSchedule.durationMinutes,
      'isActive': createdSchedule.isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return createdSchedule;
  }

  @override
  Future<void> deleteRecurringSchedule(String scheduleId) async {
    await _recurringSchedules.doc(scheduleId).delete();
  }

  // ============================================================
  // MEMORIES
  // ============================================================

  @override
  Future<List<MemoryItem>> getMemories() async {
    final snapshot = await _memories
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => _memoryFromDocument(doc)).toList();
  }

  @override
  Future<MemoryItem> addMemory(MemoryItem memory) async {
    final DocumentReference<Map<String, dynamic>> ref = memory.id.isEmpty
        ? _memories.doc()
        : _memories.doc(memory.id);

    final createdMemory = memory.copyWith(id: ref.id);

    await ref.set({
      'ownerId': createdMemory.ownerId,
      'type': createdMemory.type.name,
      'title': createdMemory.title,
      'caption': createdMemory.caption,
      'mediaPath': createdMemory.mediaPath,
      'memoryDate': Timestamp.fromDate(createdMemory.memoryDate),
      'createdAt': Timestamp.fromDate(createdMemory.createdAt),
      'visibility': createdMemory.visibility,
    });

    return createdMemory;
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await _memories.doc(memoryId).delete();
  }

  // ============================================================
  // FIRESTORE -> MODEL
  // ============================================================

  CheckIn _checkInFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Check-in document has no data: ${doc.id}');
    }

    final rawScheduledAt = data['scheduledAt'];
    final scheduledAt = switch (rawScheduledAt) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      _ => throw StateError(
        'Check-in has no valid scheduledAt timestamp: ${doc.id}',
      ),
    };
    final rawDuration = data['durationMinutes'];
    final durationMinutes = rawDuration is num ? rawDuration.toInt() : 0;
    final mode = data['mode'] as String? ?? '';
    if (durationMinutes <= 0 || mode.isEmpty) {
      throw StateError('Check-in has incomplete schedule details: ${doc.id}');
    }

    return CheckIn(
      id: doc.id,
      elderId: data['elderId'] as String? ?? '',
      elderName: data['elderName'] as String? ?? '',
      elderImageUrl: data['elderImageUrl'] as String?,
      companionId: data['companionId'] as String? ?? '',
      companionName: data['companionName'] as String? ?? '',
      companionImageUrl: data['companionImageUrl'] as String?,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      mode: mode,
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
    final rawHour = data['hour'];
    final rawMinute = data['minute'];
    final rawDuration = data['durationMinutes'];
    final mode = data['mode'] as String? ?? '';
    final hour = rawHour is num ? rawHour.toInt() : -1;
    final minute = rawMinute is num ? rawMinute.toInt() : -1;
    final durationMinutes = rawDuration is num ? rawDuration.toInt() : 0;

    final weekdays = rawWeekdays is List
        ? rawWeekdays.whereType<num>().map((value) => value.toInt()).toList()
        : <int>[];
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        durationMinutes <= 0 ||
        mode.isEmpty ||
        (data['connectionId'] as String?)?.isEmpty != false) {
      throw StateError(
        'Recurring schedule has incomplete schedule details: ${doc.id}',
      );
    }

    return RecurringSchedule(
      id: doc.id,
      elderId: data['elderId'] as String? ?? '',
      elderName: data['elderName'] as String? ?? '',
      companionId: data['companionId'] as String? ?? '',
      companionName: data['companionName'] as String? ?? '',
      connectionId: data['connectionId'] as String?,
      mode: mode,
      weekdays: weekdays,
      hour: hour,
      minute: minute,
      durationMinutes: durationMinutes,
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

  // ============================================================
  // HELPERS
  // ============================================================

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
}
