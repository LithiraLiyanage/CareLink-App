class MatchPreferences {
  final String preferredLanguage;
  final List<String> interests;
  final String availability;
  final String preferredTime;
  final String checkInType;

  const MatchPreferences({
    required this.preferredLanguage,
    required this.interests,
    required this.availability,
    required this.preferredTime,
    required this.checkInType,
  });
}
