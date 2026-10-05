class MatchPreferences {
  final String preferredLanguage;
  final List<String> interests;

  /// W01 currently offers one day group; keep its existing scalar API.
  final String availability;
  final String preferredTime;
  final String? checkInType;

  const MatchPreferences({
    required this.preferredLanguage,
    required this.interests,
    required this.availability,
    required this.preferredTime,
    this.checkInType,
  });

  /// List view for services without changing the existing W01 hand-off.
  List<String> get availabilitySelections =>
      availability.trim().isEmpty ? const [] : [availability];
}
