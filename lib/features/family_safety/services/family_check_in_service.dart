import 'package:cloud_firestore/cloud_firestore.dart';

import '../../elder/models/check_in.dart';
import 'family_link_service.dart';

/// Today's and the next check-in for the older adult a family member is
/// linked to.
class FamilyCheckInSummary {
  const FamilyCheckInSummary({this.today, this.next});

  final CheckIn? today;
  final CheckIn? next;
}

/// Read-only view of the elder's check-ins for family caregivers.
///
/// Check-ins are matched to the linked elder by first name, the same key
/// family link requests use (see [FamilyLinkService.firstNameKey]).
class FamilyCheckInService {
  FamilyCheckInService._();

  static final FamilyCheckInService instance = FamilyCheckInService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<FamilyCheckInSummary> watchSummary(String elderName) {
    final elderKey = FamilyLinkService.firstNameKey(elderName);

    return _firestore
        .collection('check_ins')
        .orderBy('scheduledAt')
        .snapshots()
        .map((snapshot) {
      final checkIns = snapshot.docs
          .map(_checkInFromDocument)
          .whereType<CheckIn>()
          .where((checkIn) =>
              FamilyLinkService.firstNameKey(checkIn.elderName) == elderKey)
          .where((checkIn) => checkIn.status != CheckInStatus.cancelled)
          .toList();
      return _summarise(checkIns, DateTime.now());
    });
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
