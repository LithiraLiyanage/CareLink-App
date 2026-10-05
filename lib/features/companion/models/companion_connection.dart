enum ConnectionStatus { active, paused, ended }

class CompanionConnection {
  final String id;
  final String elderId;
  final String companionId;
  final String? matchRequestId;
  final ConnectionStatus status;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;

  const CompanionConnection({
    required this.id,
    required this.elderId,
    required this.companionId,
    this.matchRequestId,
    required this.status,
    required this.startedAt,
    this.pausedAt,
    this.endedAt,
  });

  CompanionConnection copyWith({
    ConnectionStatus? status,
    DateTime? pausedAt,
    DateTime? endedAt,
    bool clearPausedAt = false,
  }) => CompanionConnection(
    id: id,
    elderId: elderId,
    companionId: companionId,
    matchRequestId: matchRequestId,
    status: status ?? this.status,
    startedAt: startedAt,
    pausedAt: clearPausedAt ? null : pausedAt ?? this.pausedAt,
    endedAt: endedAt ?? this.endedAt,
  );
}
