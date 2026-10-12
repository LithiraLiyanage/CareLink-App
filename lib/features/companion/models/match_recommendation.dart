import 'companion_profile.dart';

/// A companion and the evidence used to rank that recommendation.
class MatchRecommendation {
  final CompanionProfile companion;
  final int score;
  final List<String> reasons;

  const MatchRecommendation({
    required this.companion,
    required this.score,
    required this.reasons,
  });
}
