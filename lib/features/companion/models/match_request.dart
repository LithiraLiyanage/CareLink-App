import 'companion_map_values.dart';

enum MatchRequestStatus { pending, accepted, declined, cancelled }

class MatchRequest {
  final String id;
  final String elderId;
  final String companionId;
  final MatchRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const MatchRequest({
    required this.id,
    required this.elderId,
    required this.companionId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'elderId': elderId,
    'companionId': companionId,
    'status': status.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'respondedAt': respondedAt?.toUtc().toIso8601String(),
  };

  factory MatchRequest.fromMap(Map<String, dynamic> map) => MatchRequest(
    id: map['id'] as String,
    elderId: map['elderId'] as String,
    companionId: map['companionId'] as String,
    status: MatchRequestStatus.values.byName(map['status'] as String),
    createdAt: companionDateTime(map['createdAt']),
    respondedAt: companionOptionalDateTime(map['respondedAt']),
  );

  MatchRequest copyWith({MatchRequestStatus? status, DateTime? respondedAt}) =>
      MatchRequest(
        id: id,
        elderId: elderId,
        companionId: companionId,
        status: status ?? this.status,
        createdAt: createdAt,
        respondedAt: respondedAt ?? this.respondedAt,
      );
}
