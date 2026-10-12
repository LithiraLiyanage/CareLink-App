import 'companion_map_values.dart';

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

  Map<String, Object?> toMap() => {
    'id': id,
    'elderId': elderId,
    'companionId': companionId,
    'matchRequestId': matchRequestId,
    'status': status.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'pausedAt': pausedAt?.toUtc().toIso8601String(),
    'endedAt': endedAt?.toUtc().toIso8601String(),
  };

  factory CompanionConnection.fromMap(Map<String, dynamic> map) =>
      CompanionConnection(
        id: map['id'] as String,
        elderId: map['elderId'] as String,
        companionId: map['companionId'] as String,
        matchRequestId: map['matchRequestId'] as String?,
        status: ConnectionStatus.values.byName(map['status'] as String),
        startedAt: companionDateTime(map['startedAt']),
        pausedAt: companionOptionalDateTime(map['pausedAt']),
        endedAt: companionOptionalDateTime(map['endedAt']),
      );

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
