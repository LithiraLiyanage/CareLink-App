import '../models/companion_profile.dart';
import '../models/match_preferences.dart';

enum RecommendationReason {
  sameLanguage,
  sharedInterests,
  preferredDay,
  preferredTime,
}

/// Local sample profiles and a deterministic preference-based ordering.
/// No connection or request is created by viewing these recommendations.
abstract final class CompanionRecommendations {
  static const profiles = <CompanionProfile>[
    CompanionProfile(
      id: 'nethmi',
      name: 'Nethmi Jayasooriya',
      imagePath: 'assets/images/companion_nethmi.png',
      verified: true,
      languages: ['Sinhala', 'English', 'Tamil'],
      interests: ['Gardening', 'Music', 'Traditional Food'],
      availability: 'Sunday, 4:00 PM - 7:00 PM',
      shortAvailability: 'Sunday evenings',
      about: 'University student volunteer who enjoys meaningful conversations and community activities.',
    ),
    CompanionProfile(
      id: 'amaya',
      name: 'Amaya Perera',
      imagePath: 'assets/images/companion_amaya.png',
      verified: true,
      languages: ['English'],
      interests: ['Books', 'Movies'],
      availability: 'Weekend mornings',
      shortAvailability: 'Weekend morning',
      about: 'University student volunteer who enjoys books, movies and friendly conversations.',
    ),
    CompanionProfile(
      id: 'kavindu',
      name: 'Kavindu Silva',
      imagePath: 'assets/images/companion_kavindu.png',
      verified: true,
      languages: ['Sinhala'],
      interests: ['Music', 'Culture'],
      availability: 'Weekday evenings',
      shortAvailability: 'Weekday evening',
      about: 'University student volunteer interested in music, culture and meaningful conversations.',
    ),
  ];

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
