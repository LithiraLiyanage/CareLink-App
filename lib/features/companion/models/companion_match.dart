import 'companion_profile.dart';

enum MatchStatus { pending, accepted, declined, paused, ended }

class CompanionMatch {
  final String id;
  final CompanionProfile companion;
  final List<String> matchReasons;
  final MatchStatus status;
  final DateTime createdAt;

  const CompanionMatch({
    required this.id,
    required this.companion,
    required this.matchReasons,
    required this.status,
    required this.createdAt,
  });
}
