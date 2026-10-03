import 'companion_language.dart';

/// Text used only by the companion matching flow.
class CompanionStrings {
  const CompanionStrings(this.language);

  final CompanionLanguage language;

  String get recommendedCompanions => switch (language) {
    CompanionLanguage.english => 'Recommended Companions',
    CompanionLanguage.sinhala => 'නිර්දේශිත සහචරයින්',
    CompanionLanguage.tamil => 'பரிந்துரைக்கப்பட்ட துணையாளர்கள்',
  };

  String get recommendationSubtitle => switch (language) {
    CompanionLanguage.english =>
      'Based on your language, interests and availability.',
    CompanionLanguage.sinhala =>
      'ඔබගේ භාෂාව, රුචිකත්වයන් සහ ලබාගත හැකි වේලාව අනුව.',
    CompanionLanguage.tamil =>
      'உங்கள் மொழி, விருப்பங்கள் மற்றும் கிடைக்கும் நேரத்தின் அடிப்படையில்.',
  };

  String get adjustPreferences => switch (language) {
    CompanionLanguage.english => 'Adjust preferences',
    CompanionLanguage.sinhala => 'මනාප වෙනස් කරන්න',
    CompanionLanguage.tamil => 'விருப்பங்களை மாற்றவும்',
  };

  String get whyThisMatch => switch (language) {
    CompanionLanguage.english => 'Why this match?',
    CompanionLanguage.sinhala => 'මෙම ගැළපීම ඇයි?',
    CompanionLanguage.tamil => 'இந்த பொருத்தம் ஏன்?',
  };

  String get sameLanguage => switch (language) {
    CompanionLanguage.english => 'Same language',
    CompanionLanguage.sinhala => 'එකම භාෂාව',
    CompanionLanguage.tamil => 'ஒரே மொழி',
  };

  String get twoSharedInterests => switch (language) {
    CompanionLanguage.english => '2 shared interests',
    CompanionLanguage.sinhala => 'සමාන රුචිකත්වයන් 2ක්',
    CompanionLanguage.tamil => '2 பொதுவான விருப்பங்கள்',
  };

  String get availableAtPreferredTime => switch (language) {
    CompanionLanguage.english => 'Available at your preferred time',
    CompanionLanguage.sinhala => 'ඔබ කැමති වේලාවේ ලබාගත හැක',
    CompanionLanguage.tamil => 'நீங்கள் விரும்பும் நேரத்தில் கிடைக்கிறார்',
  };

  String get viewProfile => switch (language) {
    CompanionLanguage.english => 'View Profile',
    CompanionLanguage.sinhala => 'පැතිකඩ බලන්න',
    CompanionLanguage.tamil => 'சுயவிவரத்தை பார்க்கவும்',
  };

  String get sendRequest => switch (language) {
    CompanionLanguage.english => 'Send Request',
    CompanionLanguage.sinhala => 'ඉල්ලීම යවන්න',
    CompanionLanguage.tamil => 'கோரிக்கை அனுப்பவும்',
  };

  String get verifiedStudent => switch (language) {
    CompanionLanguage.english => 'Verified Student',
    CompanionLanguage.sinhala => 'තහවුරු කළ ශිෂ්‍යයෙක්',
    CompanionLanguage.tamil => 'சரிபார்க்கப்பட்ட மாணவர்',
  };

  String get home => switch (language) {
    CompanionLanguage.english => 'Home',
    CompanionLanguage.sinhala => 'මුල් පිටුව',
    CompanionLanguage.tamil => 'முகப்பு',
  };

  String get matches => switch (language) {
    CompanionLanguage.english => 'Matches',
    CompanionLanguage.sinhala => 'ගැළපීම්',
    CompanionLanguage.tamil => 'பொருத்தங்கள்',
  };

  String get checkIns => switch (language) {
    CompanionLanguage.english => 'Check-ins',
    CompanionLanguage.sinhala => 'හමුවීම්',
    CompanionLanguage.tamil => 'சந்திப்புகள்',
  };

  String get spokenLanguages => switch (language) {
    CompanionLanguage.english => 'Sinhala, English, Tamil',
    CompanionLanguage.sinhala => 'සිංහල, ඉංග්‍රීසි, දෙමළ',
    CompanionLanguage.tamil => 'சிங்களம், ஆங்கிலம், தமிழ்',
  };

  String get sundayEvenings => switch (language) {
    CompanionLanguage.english => 'Sunday evenings',
    CompanionLanguage.sinhala => 'ඉරිදා සවස් වරුවේ',
    CompanionLanguage.tamil => 'ஞாயிறு மாலைகளில்',
  };

  String get gardening => switch (language) {
    CompanionLanguage.english => 'Gardening',
    CompanionLanguage.sinhala => 'ගෙවතු වගාව',
    CompanionLanguage.tamil => 'தோட்டக்கலை',
  };

  String get music => switch (language) {
    CompanionLanguage.english => 'Music',
    CompanionLanguage.sinhala => 'සංගීතය',
    CompanionLanguage.tamil => 'இசை',
  };

  String get verifiedStudentCompanion => switch (language) {
    CompanionLanguage.english => 'Verified Student Companion',
    CompanionLanguage.sinhala => 'තහවුරු කළ ශිෂ්‍ය සහචරයෙක්',
    CompanionLanguage.tamil => 'சரிபார்க்கப்பட்ட மாணவர் துணையாளர்',
  };

  String get about => switch (language) {
    CompanionLanguage.english => 'About',
    CompanionLanguage.sinhala => 'විස්තරය',
    CompanionLanguage.tamil => 'பற்றி',
  };

  String get languages => switch (language) {
    CompanionLanguage.english => 'Languages',
    CompanionLanguage.sinhala => 'භාෂා',
    CompanionLanguage.tamil => 'மொழிகள்',
  };

  String get interests => switch (language) {
    CompanionLanguage.english => 'Interests',
    CompanionLanguage.sinhala => 'රුචිකත්වයන්',
    CompanionLanguage.tamil => 'விருப்பங்கள்',
  };

  String get availability => switch (language) {
    CompanionLanguage.english => 'Availability',
    CompanionLanguage.sinhala => 'ලබාගත හැකි වේලාව',
    CompanionLanguage.tamil => 'கிடைக்கும் நேரம்',
  };

  String get whyGoodMatch => switch (language) {
    CompanionLanguage.english => 'Why you may be a good match',
    CompanionLanguage.sinhala => 'ඔබ දෙදෙනා හොඳින් ගැළපිය හැක්කේ ඇයි?',
    CompanionLanguage.tamil =>
      'நீங்கள் நல்ல பொருத்தமாக இருக்கக்கூடிய காரணங்கள்',
  };

  String get samePreferredLanguage => switch (language) {
    CompanionLanguage.english => 'Same preferred language',
    CompanionLanguage.sinhala => 'එකම කැමති භාෂාව',
    CompanionLanguage.tamil => 'ஒரே விருப்ப மொழி',
  };

  String get sharedGardeningAndMusic => switch (language) {
    CompanionLanguage.english => 'Shared gardening and music interests',
    CompanionLanguage.sinhala => 'ගෙවතු වගාව සහ සංගීතය පිළිබඳ සමාන රුචිකත්වයන්',
    CompanionLanguage.tamil =>
      'தோட்டப்பணி மற்றும் இசையில் பொதுவான விருப்பங்கள்',
  };

  String get matchingSundayAvailability => switch (language) {
    CompanionLanguage.english => 'Matching Sunday availability',
    CompanionLanguage.sinhala => 'ඉරිදා ලබාගත හැකි වේලාව ගැළපේ',
    CompanionLanguage.tamil => 'ஞாயிற்றுக்கிழமை கிடைக்கும் நேரம் பொருந்துகிறது',
  };

  String get sendMatchRequest => switch (language) {
    CompanionLanguage.english => 'Send Match Request',
    CompanionLanguage.sinhala => 'ගැළපුම් ඉල්ලීම යවන්න',
    CompanionLanguage.tamil => 'பொருத்த கோரிக்கையை அனுப்பவும்',
  };

  String get backToRecommendations => switch (language) {
    CompanionLanguage.english => 'Back to Recommendations',
    CompanionLanguage.sinhala => 'නිර්දේශ වෙත ආපසු යන්න',
    CompanionLanguage.tamil => 'பரிந்துரைகளுக்கு திரும்பவும்',
  };

  String get volunteerAbout => switch (language) {
    CompanionLanguage.english => 'University student volunteer who enjoys meaningful conversations and community activities.',
    CompanionLanguage.sinhala => 'අර්ථවත් සංවාද සහ ප්‍රජා ක්‍රියාකාරකම්වලට කැමති විශ්වවිද්‍යාල ශිෂ්‍ය ස්වේච්ඡා සේවිකාවක්.',
    CompanionLanguage.tamil => 'அர்த்தமுள்ள உரையாடல்களையும் சமூக செயல்பாடுகளையும் விரும்பும் பல்கலைக்கழக மாணவர் தன்னார்வலர்.',
  };

  String get sundayAvailability => switch (language) {
    CompanionLanguage.english => 'Sunday, 4:00 PM - 7:00 PM',
    CompanionLanguage.sinhala => 'ඉරිදා, ප.ව. 4:00 - 7:00',
    CompanionLanguage.tamil => 'ஞாயிற்றுக்கிழமை, மாலை 4:00 - 7:00',
  };

  String get traditionalFood => switch (language) {
    CompanionLanguage.english => 'Traditional Food',
    CompanionLanguage.sinhala => 'සාම්ප්‍රදායික ආහාර',
    CompanionLanguage.tamil => 'பாரம்பரிய உணவு',
  };

  String get requestComingSoon => switch (language) {
    CompanionLanguage.english => 'Requests will be available soon.',
    CompanionLanguage.sinhala => 'ඉල්ලීම් ළඟදීම ලබා ගත හැක.',
    CompanionLanguage.tamil => 'கோரிக்கைகள் விரைவில் கிடைக்கும்.',
  };

  String get navigationComingSoon => switch (language) {
    CompanionLanguage.english => 'Navigation will be connected soon.',
    CompanionLanguage.sinhala => 'සංචලනය ළඟදීම සම්බන්ධ කෙරේ.',
    CompanionLanguage.tamil => 'வழிசெலுத்தல் விரைவில் இணைக்கப்படும்.',
  };
}
