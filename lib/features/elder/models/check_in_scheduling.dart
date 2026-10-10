import 'check_in.dart';

class CheckInScheduling {
  CheckInScheduling._();

  static const List<int> durationOptions = [15, 30, 45, 60];
  static const List<String> modes = ['Video', 'Voice'];

  static String? validateSelection({
    required DateTime? scheduledAt,
    required int? durationMinutes,
    required String? mode,
    DateTime? now,
  }) {
    if (scheduledAt == null) {
      return 'Choose a date and time.';
    }
    if (!scheduledAt.isAfter(now ?? DateTime.now())) {
      return 'Choose a date and time that is not in the past.';
    }
    if (durationMinutes == null || durationMinutes <= 0) {
      return 'Choose a duration.';
    }
    if (mode != 'Video' && mode != 'Voice') {
      return 'Choose Video or Voice.';
    }
    return null;
  }

  static bool isDue(CheckIn checkIn, {DateTime? now}) {
    return !(now ?? DateTime.now()).isBefore(checkIn.scheduledAt);
  }

  static bool companionReadinessConfirmed(CheckIn checkIn) {
    return checkIn.status == CheckInStatus.ready ||
        checkIn.status == CheckInStatus.inProgress;
  }

  static bool canOpenReadyScreen(CheckIn checkIn, {DateTime? now}) {
    return isDue(checkIn, now: now) && companionReadinessConfirmed(checkIn);
  }

  static bool isActiveUpcoming(CheckIn checkIn, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (checkIn.status == CheckInStatus.ready ||
        checkIn.status == CheckInStatus.inProgress) {
      return true;
    }
    if (checkIn.status != CheckInStatus.scheduled) {
      return false;
    }
    final sessionEnd = checkIn.scheduledAt.add(
      Duration(minutes: checkIn.durationMinutes),
    );
    return !sessionEnd.isBefore(current);
  }

  static String upcomingStatus(CheckIn checkIn, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (checkIn.status == CheckInStatus.inProgress) {
      return 'In progress';
    }
    if (checkIn.status == CheckInStatus.ready) {
      return isDue(checkIn, now: current) ? 'Ready' : 'Upcoming';
    }
    if (checkIn.status == CheckInStatus.scheduled) {
      return isDue(checkIn, now: current) ? 'Due' : 'Upcoming';
    }
    return checkIn.status.name;
  }
}
