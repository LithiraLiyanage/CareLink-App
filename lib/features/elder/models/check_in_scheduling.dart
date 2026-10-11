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

  // Scheduled start time has arrived.
  static bool isDue(CheckIn checkIn, {DateTime? now}) {
    return !(now ?? DateTime.now()).isBefore(checkIn.scheduledAt);
  }

  // Example:
  // Start: 4:08 PM
  // Duration: 45 minutes
  // End: 4:53 PM
  static DateTime callWindowEndsAt(CheckIn checkIn) {
    return checkIn.scheduledAt.add(Duration(minutes: checkIn.durationMinutes));
  }

  // A new call can begin from start time until just before end time.
  static bool isWithinCallWindow(CheckIn checkIn, {DateTime? now}) {
    if (checkIn.durationMinutes <= 0) {
      return false;
    }

    final current = now ?? DateTime.now();
    final end = callWindowEndsAt(checkIn);

    return !current.isBefore(checkIn.scheduledAt) && current.isBefore(end);
  }

  // At exactly the end time, the window is expired.
  static bool isCallWindowExpired(CheckIn checkIn, {DateTime? now}) {
    if (checkIn.durationMinutes <= 0) {
      return true;
    }

    final current = now ?? DateTime.now();

    return !current.isBefore(callWindowEndsAt(checkIn));
  }

  // Used to display the Ready screen.
  // A call that has already started is also companion-confirmed.
  static bool companionReadinessConfirmed(CheckIn checkIn) {
    return checkIn.status == CheckInStatus.ready ||
        checkIn.status == CheckInStatus.inProgress;
  }

  // Used to AUTHORIZE a new call.
  // Only a READY check-in within the scheduled window is allowed.
  static bool canOpenReadyScreen(CheckIn checkIn, {DateTime? now}) {
    return checkIn.status == CheckInStatus.ready &&
        isWithinCallWindow(checkIn, now: now);
  }

  // Keep the existing schedule-list behavior.
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
