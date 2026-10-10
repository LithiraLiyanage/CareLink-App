import '../models/companion_profile.dart';
import '../models/match_preferences.dart';
import '../models/match_recommendation.dart';

/// The same transparent scoring for mock and Firebase candidates.
List<MatchRecommendation> rankCompanions(
  Iterable<CompanionProfile> candidates,
  MatchPreferences preferences,
) {
  final profiles = candidates.toList();
  final ranked = <MatchRecommendation>[];
  for (final companion in profiles) {
    if (!companion.verified || !companion.active) {
      continue;
    }
    final shared = preferences.interests
        .where(
          (interest) => companion.interests.any(
            (other) => other.toLowerCase() == interest.toLowerCase(),
          ),
        )
        .map((interest) => interest.toLowerCase())
        .toSet();
    final languageMatch = companion.languages.any(
      (language) =>
          language.toLowerCase() == preferences.preferredLanguage.toLowerCase(),
    );
    final availability = [
      ...companion.availableSlots,
      ...companion.preferredTimes,
    ].join(' ').toLowerCase();
    final desiredDay = preferences.availability.trim().toLowerCase();
    final dayMatch = switch (desiredDay) {
      'weekend' || 'weekends' =>
        availability.contains('weekend') ||
            availability.contains('saturday') ||
            availability.contains('sunday'),
      'weekday' || 'weekdays' => availability.contains('weekday'),
      _ => desiredDay.isNotEmpty && availability.contains(desiredDay),
    };
    final desiredTime = preferences.preferredTime.trim().toLowerCase();
    final timeMatch =
        desiredTime.isNotEmpty && availability.contains(desiredTime);
    final score =
        (languageMatch ? 3 : 0) +
        shared.length * 2 +
        (dayMatch ? 3 : 0) +
        (timeMatch ? 2 : 0);
    final reasons = List<String>.unmodifiable([
      if (languageMatch) 'Speaks ${preferences.preferredLanguage}',
      if (shared.isNotEmpty)
        '${shared.length} shared ${shared.length == 1 ? 'interest' : 'interests'}',
      if (dayMatch && timeMatch) 'Available at your preferred time',
      if (dayMatch && !timeMatch) 'Available on your preferred days',
      if (timeMatch && !dayMatch) 'Available at your preferred time of day',
    ]);
    ranked.add(
      MatchRecommendation(companion: companion, score: score, reasons: reasons),
    );
  }
  final sourceOrder = {
    for (final (index, profile) in profiles.indexed) profile.id: index,
  };
  ranked.sort((a, b) {
    final score = b.score.compareTo(a.score);
    return score != 0
        ? score
        : sourceOrder[a.companion.id]!.compareTo(sourceOrder[b.companion.id]!);
  });
  return List.unmodifiable(ranked);
}
