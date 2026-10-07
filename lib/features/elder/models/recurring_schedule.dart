class RecurringSchedule {
  final String id;
  final String elderId;
  final String elderName;
  final String companionId;
  final String companionName;

  /// ISO weekdays: Monday = 1 ... Sunday = 7.
  final List<int> weekdays;

  final int hour;
  final int minute;
  final int durationMinutes;
  final bool isActive;

  const RecurringSchedule({
    required this.id,
    required this.elderId,
    required this.elderName,
    required this.companionId,
    required this.companionName,
    required this.weekdays,
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    required this.isActive,
  });

  RecurringSchedule copyWith({
    String? id,
    String? elderId,
    String? elderName,
    String? companionId,
    String? companionName,
    List<int>? weekdays,
    int? hour,
    int? minute,
    int? durationMinutes,
    bool? isActive,
  }) {
    return RecurringSchedule(
      id: id ?? this.id,
      elderId: elderId ?? this.elderId,
      elderName: elderName ?? this.elderName,
      companionId: companionId ?? this.companionId,
      companionName: companionName ?? this.companionName,
      weekdays: weekdays ?? this.weekdays,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
    );
  }
}
