class CompanionProfile {
  final String id;
  final String name;
  final String imagePath;
  final bool verified;
  final List<String> languages;
  final List<String> interests;
  final String availability;
  final String about;

  const CompanionProfile({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.verified,
    required this.languages,
    required this.interests,
    required this.availability,
    required this.about,
  });
}
