import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/check_in.dart';
import '../models/memory_item.dart';
import '../models/recurring_schedule.dart';
import 'elder_service.dart';

class FirebaseElderService implements ElderService {
  FirebaseElderService._();

  static final FirebaseElderService instance = FirebaseElderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _checkIns =>
      _firestore.collection('check_ins');

  CollectionReference<Map<String, dynamic>> get _recurringSchedules =>
      _firestore.collection('recurring_schedules');

  CollectionReference<Map<String, dynamic>> get _memories =>
      _firestore.collection('memories');

  // ============================================================
  // CHECK-INS
  // ============================================================

  @override
  Future<List<CheckIn>> getCheckIns() async {
    final snapshot = await _checkIns.orderBy('scheduledAt').get();

    return snapshot.docs.map((doc) => _checkInFromDocument(doc)).toList();
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
  Future<CheckIn> rescheduleCheckIn(
    String checkInId,
    DateTime newDateTime,
  ) async {
    final ref = _checkIns.doc(checkInId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw StateError('Check-in not found: $checkInId');
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
    final snapshot = await _recurringSchedules.get();

    return snapshot.docs
        .map((doc) => _recurringScheduleFromDocument(doc))
        .toList();
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

  Future<void> seedDemoDataIfEmpty() async {
    final checkInSnapshot = await _checkIns.limit(1).get();

    if (checkInSnapshot.docs.isEmpty) {
      await _checkIns.doc('checkin-001').set({
        'elderId': 'elder-kamala',
        'elderName': 'Kamala Perera',
        'companionId': 'companion-nethmi',
        'companionName': 'Nethmi Jayasooriya',
        'scheduledAt': Timestamp.fromDate(DateTime(2026, 10, 6, 18, 30)),
        'durationMinutes': 30,
        'mode': 'Video',
        'status': CheckInStatus.ready.name,
        'reflection': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _checkIns.doc('checkin-002').set({
        'elderId': 'elder-kamala',
        'elderName': 'Kamala Perera',
        'companionId': 'companion-nethmi',
        'companionName': 'Nethmi Jayasooriya',
        'scheduledAt': Timestamp.fromDate(DateTime(2026, 10, 8, 18, 30)),
        'durationMinutes': 30,
        'mode': 'Video',
        'status': CheckInStatus.scheduled.name,
        'reflection': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _checkIns.doc('checkin-003').set({
        'elderId': 'elder-kamala',
        'elderName': 'Kamala Perera',
        'companionId': 'companion-nethmi',
        'companionName': 'Nethmi Jayasooriya',
        'scheduledAt': Timestamp.fromDate(DateTime(2026, 10, 10, 18, 30)),
        'durationMinutes': 30,
        'mode': 'Video',
        'status': CheckInStatus.scheduled.name,
        'reflection': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final memorySnapshot = await _memories.limit(1).get();

    if (memorySnapshot.docs.isEmpty) {
      await _memories.doc('memory-001').set({
        'ownerId': 'elder-kamala',
        'type': MemoryType.photo.name,
        'title': 'A favourite family moment',
        'caption': 'Colombo • Jan 1998',
        'mediaPath': 'assets/elder/family_memory.jpg',
        'memoryDate': Timestamp.fromDate(DateTime(1998, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'visibility': 'Only me',
      });

      await _memories.doc('memory-002').set({
        'ownerId': 'elder-kamala',
        'type': MemoryType.voice.name,
        'title': "Listen to Amma's Story",
        'caption': '02:45',
        'mediaPath': null,
        'memoryDate': Timestamp.fromDate(DateTime(2000, 4, 10)),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'visibility': 'Only me',
      });

      await _memories.doc('memory-003').set({
        'ownerId': 'elder-kamala',
        'type': MemoryType.song.name,
        'title': 'Favourite Song',
        'caption': null,
        'mediaPath': null,
        'memoryDate': Timestamp.fromDate(DateTime(2001, 6, 15)),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'visibility': 'Only me',
      });
    }
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
