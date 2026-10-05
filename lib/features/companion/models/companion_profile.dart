class CompanionProfile {
  final String id;
  final String userId;
  final String name;
  final String imagePath;
  final bool verified;
  final List<String> languages;
  final List<String> interests;
  final String availability;
  final List<String> availabilitySlots;
  final String shortAvailability;
  final String about;
  final bool active;

  const CompanionProfile({
    required this.id,
    String? userId,
    required this.name,
    required this.imagePath,
    required this.verified,
    required this.languages,
    required this.interests,
    required this.availability,
    this.availabilitySlots = const [],
    this.shortAvailability = '',
    required this.about,
    this.active = true,
  }) : userId = userId ?? 'user_$id';

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
