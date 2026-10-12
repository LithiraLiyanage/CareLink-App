import 'package:cloud_firestore/cloud_firestore.dart';

import '../../elder/models/check_in.dart';

/// Today's and the next check-in for the older adult a family member is
/// linked to.
class FamilyCheckInSummary {
  const FamilyCheckInSummary({this.today, this.next});

  final CheckIn? today;
  final CheckIn? next;
}

/// Read-only view of the elder's check-ins for family caregivers.
///
/// Check-ins are queried by the linked elder's UID; the rules deny
/// caregiver queries that are not filtered to a linked elder.
class FamilyCheckInService {
  FamilyCheckInService._();

  static final FamilyCheckInService instance = FamilyCheckInService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<FamilyCheckInSummary> watchSummary(String elderId) {
    // Sorted here rather than with orderBy, which would need a composite
    // index on (elderId, scheduledAt).
    return _firestore
        .collection('check_ins')
        .where('elderId', isEqualTo: elderId)
        .snapshots()
        .map((snapshot) {
      final checkIns = snapshot.docs
          .map(_checkInFromDocument)
          .whereType<CheckIn>()
          .where((checkIn) => checkIn.status != CheckInStatus.cancelled)
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return _summarise(checkIns, DateTime.now());
    });
  }

  /// The elder's missed check-ins, newest first: those marked missed, and
  /// those still waiting to start after their scheduled end time.
  Stream<List<CheckIn>> watchMissed(String elderId) {
    return _firestore
        .collection('check_ins')
        .where('elderId', isEqualTo: elderId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map(_checkInFromDocument)
          .whereType<CheckIn>()
          .where((checkIn) => isMissed(checkIn, now))
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    });
  }

  static bool isMissed(CheckIn checkIn, DateTime now) {
    if (checkIn.status == CheckInStatus.missed) return true;
    final notStarted = checkIn.status == CheckInStatus.scheduled ||
        checkIn.status == CheckInStatus.ready;
    final endsAt =
        checkIn.scheduledAt.add(Duration(minutes: checkIn.durationMinutes));
    return notStarted && endsAt.isBefore(now);
  }

  static FamilyCheckInSummary _summarise(
    List<CheckIn> checkIns,
    DateTime now,
  ) {
    bool isToday(DateTime date) =>
        date.year == now.year && date.month == now.month && date.day == now.day;

    final todays = checkIns.where((c) => isToday(c.scheduledAt)).toList();

    // Prefer the latest finished check-in today, then the next one still to
    // happen, then whatever else today holds (e.g. missed).
    CheckIn? today;
    final completed =
        todays.where((c) => c.status == CheckInStatus.completed).toList();
    final upcomingToday = todays.where(_isUpcoming).toList();
    if (completed.isNotEmpty) {
      today = completed.last;
    } else if (upcomingToday.isNotEmpty) {
      today = upcomingToday.first;
    } else if (todays.isNotEmpty) {
      today = todays.last;
    }

    final next = checkIns
        .where(_isUpcoming)
        .where((c) => c.scheduledAt.isAfter(now))
        .where((c) => c.id != today?.id)
        .firstOrNull;

    return FamilyCheckInSummary(today: today, next: next);
  }

  static bool _isUpcoming(CheckIn checkIn) =>
      checkIn.status == CheckInStatus.scheduled ||
      checkIn.status == CheckInStatus.ready ||
      checkIn.status == CheckInStatus.inProgress;

  /// The check-in in [doc], or null when it has no scheduled time or an
  /// unknown status, so family members never see a time or status the
  /// document doesn't actually hold.
  CheckIn? _checkInFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final scheduledAt = data['scheduledAt'];
    final status = CheckInStatus.values
        .where((status) => status.name == data['status'])
        .firstOrNull;
    if (scheduledAt is! Timestamp || status == null) return null;
    return CheckIn(
      id: doc.id,
      elderId: data['elderId'] as String? ?? '',
      elderName: data['elderName'] as String? ?? '',
      companionId: data['companionId'] as String? ?? '',
      companionName: data['companionName'] as String? ?? '',
      scheduledAt: scheduledAt.toDate(),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      mode: data['mode'] as String? ?? 'Video',
      status: status,
      reflection: data['reflection'] as String?,
    );
  }
}
