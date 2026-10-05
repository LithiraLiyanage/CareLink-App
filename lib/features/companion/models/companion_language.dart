enum CompanionLanguage {
  english('English'),
  sinhala('සිංහල'),
  tamil('தமிழ்');

  const CompanionLanguage(this.displayLabel);

  final String displayLabel;

  String get storedValue => switch (this) {
    CompanionLanguage.english => 'English',
    CompanionLanguage.sinhala => 'Sinhala',
    CompanionLanguage.tamil => 'Tamil',
  };
}
