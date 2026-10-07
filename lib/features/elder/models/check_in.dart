enum CheckInStatus {
  scheduled,
  ready,
  inProgress,
  completed,
  cancelled,
  missed,
}

class CheckIn {
  final String id;
  final String elderId;
  final String elderName;
  final String companionId;
  final String companionName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String mode;
  final CheckInStatus status;
  final String? reflection;

  const CheckIn({
    required this.id,
    required this.elderId,
    required this.elderName,
    required this.companionId,
    required this.companionName,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.mode,
    required this.status,
    this.reflection,
  });

  CheckIn copyWith({
    String? id,
    String? elderId,
    String? elderName,
    String? companionId,
    String? companionName,
    DateTime? scheduledAt,
    int? durationMinutes,
    String? mode,
    CheckInStatus? status,
    String? reflection,
  }) {
    return CheckIn(
      id: id ?? this.id,
      elderId: elderId ?? this.elderId,
      elderName: elderName ?? this.elderName,
      companionId: companionId ?? this.companionId,
      companionName: companionName ?? this.companionName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      reflection: reflection ?? this.reflection,
    );
  }
}
