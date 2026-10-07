import 'companion_map_values.dart';

class CompanionProfile {
  final String id;
  final String userId;
  final String name;
  final String imagePath;
  final String? profileImageUrl;
  final bool verified;
  final List<String> languages;
  final List<String> interests;
  final String availability;
  final List<String> availabilitySlots;
  final List<String> preferredTimes;
  final String shortAvailability;
  final String about;
  final bool active;

  const CompanionProfile({
    required this.id,
    String? userId,
    required this.name,
    required this.imagePath,
    this.profileImageUrl,
    required this.verified,
    required this.languages,
    required this.interests,
    required this.availability,
    this.availabilitySlots = const [],
    this.preferredTimes = const [],
    this.shortAvailability = '',
    required this.about,
    this.active = true,
  }) : userId = userId ?? 'user_$id';

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'bio': about,
    'verified': verified,
    'languages': languages,
    'interests': interests,
    'availability': availability,
    'availabilitySlots': availabilitySlots,
    'preferredTimes': preferredTimes,
    'shortAvailability': shortAvailability,
    'profileImagePath': imagePath,
    'profileImageUrl': profileImageUrl,
    'active': active,
  };

  factory CompanionProfile.fromMap(Map<String, dynamic> map) =>
      CompanionProfile(
        id: map['id'] as String,
        userId: map['userId'] as String?,
        name: map['name'] as String? ?? map['fullName'] as String? ?? '',
        about: map['bio'] as String? ?? '',
        verified: map['verified'] == true,
        languages: companionStringList(map['languages']),
        interests: companionStringList(map['interests']),
        availability: map['availability'] as String? ?? '',
        availabilitySlots: companionStringList(map['availabilitySlots']),
        preferredTimes: companionStringList(map['preferredTimes']),
        shortAvailability: map['shortAvailability'] as String? ?? '',
        imagePath: map['profileImagePath'] as String? ?? '',
        profileImageUrl: map['profileImageUrl'] as String?,
        active: map['active'] != false,
      );

  /// Compatibility names used by the future data service. Existing screens
  /// continue to use [about], [imagePath], and the display [availability].
  String get bio => about;
  String? get profileImagePath => imagePath.isEmpty ? null : imagePath;
  List<String> get availableSlots =>
      availabilitySlots.isEmpty ? [availability] : availabilitySlots;

  String get firstName {
    final words = name.trim().split(RegExp(r'\s+'));
    return words.first;
  }
}
