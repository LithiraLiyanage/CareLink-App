import 'package:carelink_app/features/elder/models/recurring_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('next occurrence uses ISO weekdays and local schedule time', () {
    const schedule = RecurringSchedule(
      id: 'schedule',
      elderId: 'elder',
      elderName: 'Older Adult',
      companionId: 'companion',
      companionName: 'Student Companion',
      weekdays: [1, 3],
      hour: 18,
      minute: 30,
      durationMinutes: 30,
      isActive: true,
    );

    expect(
      schedule.nextOccurrence(DateTime(2025, 6, 2, 19)),
      DateTime(2025, 6, 4, 18, 30),
    );
  });

  test('inactive recurring schedules have no next occurrence', () {
    const schedule = RecurringSchedule(
      id: 'schedule',
      elderId: 'elder',
      elderName: 'Older Adult',
      companionId: 'companion',
      companionName: 'Student Companion',
      weekdays: [1, 3],
      hour: 18,
      minute: 30,
      durationMinutes: 30,
      isActive: false,
    );

    expect(schedule.nextOccurrence(DateTime(2025, 6, 2)), isNull);
  });
}
