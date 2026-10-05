class CompanionProfile {
  final String id;
  final String name;
  final String imagePath;
  final bool verified;
  final List<String> languages;
  final List<String> interests;
  final String availability;
  final String shortAvailability;
  final String about;

  const CompanionProfile({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.verified,
    required this.languages,
    required this.interests,
    required this.availability,
    this.shortAvailability = '',
    required this.about,
  });

  String get firstName {
    final words = name.trim().split(RegExp(r'\s+'));
    return words.first;
  }
}
