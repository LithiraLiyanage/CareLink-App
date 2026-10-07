import '../models/companion_profile.dart';
import '../models/match_preferences.dart';
import 'mock_companion_service.dart';

enum RecommendationReason {
  sameLanguage,
  sharedInterests,
  preferredDay,
  preferredTime,
}

/// Deterministic preference scoring for local previews.
/// No connection or request is created by viewing these recommendations.
abstract final class CompanionRecommendations {
  static final profiles = MockCompanionService.mockProfiles
      .map(
        (profile) => CompanionProfile.fromMap({
          ...profile.toMap(),
          'id': profile.id.replaceFirst('companion_', ''),
        }),
      )
      .toList(growable: false);

  static List<CompanionProfile> ordered(MatchPreferences preferences) {
    final ranked = List<CompanionProfile>.of(profiles);
    ranked.sort((a, b) {
      final difference = score(b, preferences) - score(a, preferences);
      if (difference != 0) return difference;
      return profiles.indexOf(a).compareTo(profiles.indexOf(b));
    });
    return ranked;
  }

  static int score(CompanionProfile profile, MatchPreferences preferences) {
    return (sameLanguage(profile, preferences) ? 1 : 0) +
        sharedInterestCount(profile, preferences) +
        (preferredDay(profile, preferences) ? 1 : 0) +
        (preferredTime(profile, preferences) ? 1 : 0);
  }

  static bool sameLanguage(
    CompanionProfile profile,
    MatchPreferences preferences,
  ) => profile.languages.any(
    (language) =>
        language.toLowerCase() == preferences.preferredLanguage.toLowerCase(),
  );

  static int sharedInterestCount(
    CompanionProfile profile,
    MatchPreferences preferences,
  ) => preferences.interests
      .where(
        (interest) => profile.interests.any(
          (offered) => offered.toLowerCase() == interest.toLowerCase(),
        ),
      )
      .length;

  static bool preferredDay(
    CompanionProfile profile,
    MatchPreferences preferences,
  ) {
    final availability = profile.availability.toLowerCase();
    return switch (preferences.availability.toLowerCase()) {
      'weekends' =>
        availability.contains('weekend') || availability.contains('sunday'),
      'weekdays' => availability.contains('weekday'),
      _ => false,
    };
  }

  static bool preferredTime(
    CompanionProfile profile,
    MatchPreferences preferences,
  ) {
    final preferred = preferences.preferredTime.toLowerCase();
    if (preferred.isEmpty) return false;
    return profile.availability.toLowerCase().contains(preferred) ||
        profile.shortAvailability.toLowerCase().contains(preferred);
  }

  static List<RecommendationReason> reasonsFor(
    CompanionProfile profile,
    MatchPreferences preferences,
  ) => [
    if (sameLanguage(profile, preferences)) RecommendationReason.sameLanguage,
    if (sharedInterestCount(profile, preferences) > 0)
      RecommendationReason.sharedInterests,
    if (preferredDay(profile, preferences)) RecommendationReason.preferredDay,
    if (preferredTime(profile, preferences)) RecommendationReason.preferredTime,
  ];
}
