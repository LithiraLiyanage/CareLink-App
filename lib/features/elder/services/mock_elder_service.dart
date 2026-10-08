import '../models/check_in.dart';
import '../models/check_in_scheduling.dart';
import '../models/memory_item.dart';
import '../models/recurring_schedule.dart';
import 'elder_service.dart';

class MockElderService implements ElderService {
  MockElderService._();

  static final MockElderService instance = MockElderService._();

  final List<CheckIn> _checkIns = [
    CheckIn(
      id: 'checkin-001',
      elderId: 'elder-kamala',
      elderName: 'Kamala Perera',
      companionId: 'companion-nethmi',
      companionName: 'Nethmi Jayasooriya',
      scheduledAt: DateTime(2026, 10, 5, 18, 30),
      durationMinutes: 30,
      mode: 'Video',
      status: CheckInStatus.ready,
    ),
    CheckIn(
      id: 'checkin-002',
      elderId: 'elder-kamala',
      elderName: 'Kamala Perera',
      companionId: 'companion-nethmi',
      companionName: 'Nethmi Jayasooriya',
      scheduledAt: DateTime(2026, 10, 7, 18, 30),
      durationMinutes: 30,
      mode: 'Video',
      status: CheckInStatus.scheduled,
    ),
    CheckIn(
      id: 'checkin-003',
      elderId: 'elder-kamala',
      elderName: 'Kamala Perera',
      companionId: 'companion-nethmi',
      companionName: 'Nethmi Jayasooriya',
      scheduledAt: DateTime(2026, 10, 9, 18, 30),
      durationMinutes: 30,
      mode: 'Video',
      status: CheckInStatus.scheduled,
    ),
  ];

  final List<RecurringSchedule> _recurringSchedules = [
    const RecurringSchedule(
      id: 'schedule-001',
      elderId: 'elder-kamala',
      elderName: 'Kamala Perera',
      companionId: 'companion-nethmi',
      companionName: 'Nethmi Jayasooriya',
      weekdays: [1, 3, 5],
      hour: 18,
      minute: 30,
      durationMinutes: 30,
      isActive: true,
    ),
  ];

  final List<MemoryItem> _memories = [
    MemoryItem(
      id: 'memory-001',
      ownerId: 'elder-kamala',
      type: MemoryType.photo,
      title: 'A favourite family moment',
      caption: 'Colombo • Jan 1998',
      mediaPath: 'assets/elder/family_memory.jpg',
      memoryDate: DateTime(1998, 1, 1),
      createdAt: DateTime(2026, 10, 1),
    ),
    MemoryItem(
      id: 'memory-002',
      ownerId: 'elder-kamala',
      type: MemoryType.voice,
      title: "Listen to Amma's Story",
      caption: '02:45',
      memoryDate: DateTime(2000, 4, 10),
      createdAt: DateTime(2026, 10, 2),
    ),
    MemoryItem(
      id: 'memory-003',
      ownerId: 'elder-kamala',
      type: MemoryType.song,
      title: 'Favourite Song',
      memoryDate: DateTime(2001, 6, 15),
      createdAt: DateTime(2026, 10, 3),
    ),
  ];

  @override
  Future<List<CheckIn>> getCheckIns() async {
    await _delay();
    final items = List<CheckIn>.from(_checkIns)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }

  @override
  Future<CheckIn?> getCheckInById(String id) async {
    await _delay();
    for (final item in _checkIns) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<CheckIn> createCheckIn(CheckIn checkIn) async {
    await _delay();
    final error = CheckInScheduling.validateSelection(
      scheduledAt: checkIn.scheduledAt,
      durationMinutes: checkIn.durationMinutes,
      mode: checkIn.mode,
    );
    if (error != null) {
      throw StateError(error);
    }
    final created = checkIn.copyWith(
      id: checkIn.id.isEmpty
          ? 'checkin-${DateTime.now().microsecondsSinceEpoch}'
          : checkIn.id,
      status: CheckInStatus.scheduled,
    );
    _checkIns.add(created);
    return created;
  }

  @override
  Future<CheckIn> rescheduleCheckIn(
    String checkInId,
    DateTime newDateTime,
  ) async {
    await _delay();
    final index = _indexOfCheckIn(checkInId);
    final existing = _checkIns[index];
    final error = CheckInScheduling.validateSelection(
      scheduledAt: newDateTime,
      durationMinutes: existing.durationMinutes,
      mode: existing.mode,
    );
    if (error != null) {
      throw StateError(error);
    }
    final updated = existing.copyWith(
      scheduledAt: newDateTime,
      status: CheckInStatus.scheduled,
    );
    _checkIns[index] = updated;
    return updated;
  }

  @override
  Future<CheckIn> updateCheckInStatus(
    String checkInId,
    CheckInStatus status, {
    String? reflection,
  }) async {
    await _delay();
    final index = _indexOfCheckIn(checkInId);
    final updated = _checkIns[index].copyWith(
      status: status,
      reflection: reflection,
    );
    _checkIns[index] = updated;
    return updated;
  }

  @override
  Future<void> cancelCheckIn(String checkInId) async {
    await updateCheckInStatus(checkInId, CheckInStatus.cancelled);
  }

  @override
  Future<List<RecurringSchedule>> getRecurringSchedules() async {
    await _delay();
    return List<RecurringSchedule>.unmodifiable(_recurringSchedules);
  }

  @override
  Future<RecurringSchedule> createRecurringSchedule(
    RecurringSchedule schedule,
  ) async {
    await _delay();
    final created = schedule.copyWith(
      id: schedule.id.isEmpty
          ? 'schedule-${DateTime.now().microsecondsSinceEpoch}'
          : schedule.id,
    );
    _recurringSchedules.add(created);
    return created;
  }

  @override
  Future<void> deleteRecurringSchedule(String scheduleId) async {
    await _delay();
    _recurringSchedules.removeWhere((item) => item.id == scheduleId);
  }

  @override
  Future<List<MemoryItem>> getMemories() async {
    await _delay();
    final items = List<MemoryItem>.from(_memories)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<MemoryItem> addMemory(MemoryItem memory) async {
    await _delay();
    final created = memory.copyWith(
      id: memory.id.isEmpty
          ? 'memory-${DateTime.now().microsecondsSinceEpoch}'
          : memory.id,
    );
    _memories.add(created);
    return created;
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await _delay();
    _memories.removeWhere((item) => item.id == memoryId);
  }

  int _indexOfCheckIn(String id) {
    final index = _checkIns.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Check-in not found: $id');
    }
    return index;
  }

  Future<void> _delay() {
    return Future<void>.delayed(
      const Duration(milliseconds: 250),
    );
  }
}
