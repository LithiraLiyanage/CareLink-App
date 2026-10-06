import 'companion_map_values.dart';

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

  Map<String, Object?> toMap() => {
    'preferredLanguage': preferredLanguage,
    'interests': interests,
    'availability': availability,
    'preferredTime': preferredTime,
    'checkInType': checkInType,
  };

  factory MatchPreferences.fromMap(Map<String, dynamic> map) =>
      MatchPreferences(
        preferredLanguage: map['preferredLanguage'] as String? ?? '',
        interests: companionStringList(map['interests']),
        availability: map['availability'] as String? ?? '',
        preferredTime: map['preferredTime'] as String? ?? '',
        checkInType: map['checkInType'] as String?,
      );

  /// List view for services without changing the existing W01 hand-off.
  List<String> get availabilitySelections =>
      availability.trim().isEmpty ? const [] : [availability];
}
