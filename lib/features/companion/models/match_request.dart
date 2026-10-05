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
