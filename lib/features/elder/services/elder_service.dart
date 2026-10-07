import '../models/check_in.dart';
import '../models/memory_item.dart';
import '../models/recurring_schedule.dart';

abstract class ElderService {
  Future<List<CheckIn>> getCheckIns();
  Future<CheckIn?> getCheckInById(String id);

  Future<CheckIn> rescheduleCheckIn(
    String checkInId,
    DateTime newDateTime,
  );

  Future<CheckIn> updateCheckInStatus(
    String checkInId,
    CheckInStatus status, {
    String? reflection,
  });

  Future<void> cancelCheckIn(String checkInId);

  Future<List<RecurringSchedule>> getRecurringSchedules();

  Future<RecurringSchedule> createRecurringSchedule(
    RecurringSchedule schedule,
  );

  Future<void> deleteRecurringSchedule(String scheduleId);

  Future<List<MemoryItem>> getMemories();
  Future<MemoryItem> addMemory(MemoryItem memory);
  Future<void> deleteMemory(String memoryId);
}
