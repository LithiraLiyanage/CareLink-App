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
    CompanionLanguage.tamil => 'தோட்டப்பணி',
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

  String get requestReviewSubtitle => switch (language) {
    CompanionLanguage.english => 'Review the request before it is shared.',
    CompanionLanguage.sinhala => 'ඉල්ලීම යැවීමට පෙර විස්තර පරීක්ෂා කරන්න.',
    CompanionLanguage.tamil => 'கோரிக்கையை பகிர்வதற்கு முன் சரிபார்க்கவும்.',
  };

  String get verified => switch (language) {
    CompanionLanguage.english => 'Verified',
    CompanionLanguage.sinhala => 'තහවුරු කළ',
    CompanionLanguage.tamil => 'சரிபார்க்கப்பட்டது',
  };

  String get connectionRequestMessage => switch (language) {
    CompanionLanguage.english => 'You are about to send a connection request.',
    CompanionLanguage.sinhala => 'ඔබ සම්බන්ධතා ඉල්ලීමක් යැවීමට සූදානම්.',
    CompanionLanguage.tamil =>
      'நீங்கள் ஒரு இணைப்பு கோரிக்கையை அனுப்ப உள்ளீர்கள்.',
  };

  String get informationShared => switch (language) {
    CompanionLanguage.english => 'Information Shared',
    CompanionLanguage.sinhala => 'බෙදාගන්නා තොරතුරු',
    CompanionLanguage.tamil => 'பகிரப்படும் தகவல்கள்',
  };

  String get firstName => switch (language) {
    CompanionLanguage.english => 'First name',
    CompanionLanguage.sinhala => 'මුල් නම',
    CompanionLanguage.tamil => 'முதல் பெயர்',
  };

  String get approvedInterests => switch (language) {
    CompanionLanguage.english => 'Approved interests',
    CompanionLanguage.sinhala => 'අනුමත රුචිකත්වයන්',
    CompanionLanguage.tamil => 'அங்கீகரிக்கப்பட்ட விருப்பங்கள்',
  };

  String get preferredLanguage => switch (language) {
    CompanionLanguage.english => 'Preferred language',
    CompanionLanguage.sinhala => 'කැමති භාෂාව',
    CompanionLanguage.tamil => 'விருப்ப மொழி',
  };

  String get notShared => switch (language) {
    CompanionLanguage.english => 'Not Shared',
    CompanionLanguage.sinhala => 'බෙදා නොගන්නා තොරතුරු',
    CompanionLanguage.tamil => 'பகிரப்படாத தகவல்கள்',
  };

  String get phoneNumber => switch (language) {
    CompanionLanguage.english => 'Phone number',
    CompanionLanguage.sinhala => 'දුරකථන අංකය',
    CompanionLanguage.tamil => 'தொலைபேசி எண்',
  };

  String get homeAddress => switch (language) {
    CompanionLanguage.english => 'Home address',
    CompanionLanguage.sinhala => 'නිවසේ ලිපිනය',
    CompanionLanguage.tamil => 'வீட்டு முகவரி',
  };

  String get privateConversationContent => switch (language) {
    CompanionLanguage.english => 'Private conversation content',
    CompanionLanguage.sinhala => 'පෞද්ගලික සංවාද අන්තර්ගතය',
    CompanionLanguage.tamil => 'தனிப்பட்ட உரையாடல் உள்ளடக்கம்',
  };

  String get cancel => switch (language) {
    CompanionLanguage.english => 'Cancel',
    CompanionLanguage.sinhala => 'අවලංගු කරන්න',
    CompanionLanguage.tamil => 'ரத்து செய்',
  };

  String get reviewSendRequest => switch (language) {
    CompanionLanguage.english => 'Send Request',
    CompanionLanguage.sinhala => 'ඉල්ලීම යවන්න',
    CompanionLanguage.tamil => 'கோரிக்கையை அனுப்பவும்',
  };

  String get matchRequest => switch (language) {
    CompanionLanguage.english => 'Match Request',
    CompanionLanguage.sinhala => 'ගැළපුම් ඉල්ලීම',
    CompanionLanguage.tamil => 'பொருத்த கோரிக்கை',
  };

  String get matchingRequiresAgreement => switch (language) {
    CompanionLanguage.english =>
      'Matching only becomes active after both people agree.',
    CompanionLanguage.sinhala =>
      'දෙදෙනාම එකඟ වූ පසු පමණක් සම්බන්ධතාව සක්‍රිය වේ.',
    CompanionLanguage.tamil =>
      'இருவரும் ஒப்புக்கொண்ட பிறகே இணைப்பு செயல்படும்.',
  };

  String get pending => switch (language) {
    CompanionLanguage.english => 'Pending',
    CompanionLanguage.sinhala => 'රැඳී සිටී',
    CompanionLanguage.tamil => 'நிலுவையில்',
  };

  String get yourRequestSent => switch (language) {
    CompanionLanguage.english => 'Your request has been sent.',
    CompanionLanguage.sinhala => 'ඔබගේ ඉල්ලීම යවා ඇත.',
    CompanionLanguage.tamil => 'உங்கள் கோரிக்கை அனுப்பப்பட்டது.',
  };

  String waitingForCompanion(String firstName) => switch (language) {
    CompanionLanguage.english => 'Waiting for $firstName to respond.',
    CompanionLanguage.sinhala => '$firstNameගේ ප්‍රතිචාරය බලා සිටී.',
    CompanionLanguage.tamil => '$firstName-ன் பதிலை காத்திருக்கிறது.',
  };

  String get requestProgress => switch (language) {
    CompanionLanguage.english => 'Request progress',
    CompanionLanguage.sinhala => 'ඉල්ලීමේ ප්‍රගතිය',
    CompanionLanguage.tamil => 'கோரிக்கை முன்னேற்றம்',
  };

  String get requestSentStep => switch (language) {
    CompanionLanguage.english => 'Request sent',
    CompanionLanguage.sinhala => 'ඉල්ලීම යවා ඇත',
    CompanionLanguage.tamil => 'கோரிக்கை அனுப்பப்பட்டது',
  };

  String get completed => switch (language) {
    CompanionLanguage.english => 'Completed',
    CompanionLanguage.sinhala => 'සම්පූර්ණයි',
    CompanionLanguage.tamil => 'முடிந்தது',
  };

  String get waitingForResponse => switch (language) {
    CompanionLanguage.english => 'Waiting for response',
    CompanionLanguage.sinhala => 'ප්‍රතිචාරය බලා සිටී',
    CompanionLanguage.tamil => 'பதிலை காத்திருக்கிறது',
  };

  String get inProgress => switch (language) {
    CompanionLanguage.english => 'In progress',
    CompanionLanguage.sinhala => 'ක්‍රියාත්මක වෙමින් පවතී',
    CompanionLanguage.tamil => 'செயலில் உள்ளது',
  };

  String get connectionDecision => switch (language) {
    CompanionLanguage.english => 'Connection decision',
    CompanionLanguage.sinhala => 'සම්බන්ධතා තීරණය',
    CompanionLanguage.tamil => 'இணைப்பு முடிவு',
  };

  String get cancelRequest => switch (language) {
    CompanionLanguage.english => 'Cancel Request',
    CompanionLanguage.sinhala => 'ඉල්ලීම අවලංගු කරන්න',
    CompanionLanguage.tamil => 'கோரிக்கையை ரத்து செய்',
  };

  String get backToMatches => switch (language) {
    CompanionLanguage.english => 'Back to Matches',
    CompanionLanguage.sinhala => 'ගැළපීම් වෙත ආපසු යන්න',
    CompanionLanguage.tamil => 'பொருத்தங்களுக்கு திரும்பவும்',
  };

  String get simulateAccept => switch (language) {
    CompanionLanguage.english => 'Simulate Accept',
    CompanionLanguage.sinhala => 'පිළිගැනීම පරීක්ෂා කරන්න',
    CompanionLanguage.tamil => 'ஏற்றுக்கொள்ளுதலை சோதிக்கவும்',
  };

  String get simulateDecline => switch (language) {
    CompanionLanguage.english => 'Simulate Decline',
    CompanionLanguage.sinhala => 'ප්‍රතික්ෂේප කිරීම පරීක්ෂා කරන්න',
    CompanionLanguage.tamil => 'நிராகரிப்பை சோதிக்கவும்',
  };

  String get developmentOnly => switch (language) {
    CompanionLanguage.english => 'Development only',
    CompanionLanguage.sinhala => 'සංවර්ධන පරීක්ෂණ සඳහා පමණි',
    CompanionLanguage.tamil => 'உருவாக்கச் சோதனைக்கு மட்டும்',
  };

  String get connectionAccepted => switch (language) {
    CompanionLanguage.english => 'Connection Accepted!',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව පිළිගෙන ඇත!',
    CompanionLanguage.tamil => 'இணைப்பு ஏற்கப்பட்டது!',
  };

  String get greatConnection => switch (language) {
    CompanionLanguage.english => 'Great connection!',
    CompanionLanguage.sinhala => 'සුභ සම්බන්ධතාවයක්!',
    CompanionLanguage.tamil => 'சிறந்த இணைப்பு!',
  };

  String youAndCompanionConnected(String firstName) => switch (language) {
    CompanionLanguage.english => 'You and $firstName are now connected.',
    CompanionLanguage.sinhala => 'ඔබ සහ $firstName දැන් සම්බන්ධ වී ඇත.',
    CompanionLanguage.tamil =>
      'நீங்களும் $firstName-யும் இப்போது இணைந்துள்ளீர்கள்.',
  };

  String get verifiedCompanion => switch (language) {
    CompanionLanguage.english => 'Verified Companion',
    CompanionLanguage.sinhala => 'තහවුරු කළ සහචරයෙක්',
    CompanionLanguage.tamil => 'சரிபார்க்கப்பட்ட துணையாளர்',
  };

  String get sharedInterests => switch (language) {
    CompanionLanguage.english => 'Shared interests',
    CompanionLanguage.sinhala => 'සමාන රුචිකත්වයන්',
    CompanionLanguage.tamil => 'பொதுவான விருப்பங்கள்',
  };

  String get bothPeopleAgreed => switch (language) {
    CompanionLanguage.english => 'Both people have agreed',
    CompanionLanguage.sinhala => 'දෙදෙනාම එකඟ වී ඇත',
    CompanionLanguage.tamil => 'இருவரும் ஒப்புக்கொண்டுள்ளனர்',
  };

  String get active => switch (language) {
    CompanionLanguage.english => 'Active',
    CompanionLanguage.sinhala => 'සක්‍රියයි',
    CompanionLanguage.tamil => 'செயலில் உள்ளது',
  };

  String get connectionStatusActive => switch (language) {
    CompanionLanguage.english => 'Your connection status is now Active.',
    CompanionLanguage.sinhala => 'ඔබගේ සම්බන්ධතා තත්ත්වය දැන් සක්‍රියයි.',
    CompanionLanguage.tamil => 'உங்கள் இணைப்பு நிலை இப்போது செயலில் உள்ளது.',
  };

  String get viewConnection => switch (language) {
    CompanionLanguage.english => 'View Connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව බලන්න',
    CompanionLanguage.tamil => 'இணைப்பை பார்க்கவும்',
  };

  String get scheduleCheckIn => switch (language) {
    CompanionLanguage.english => 'Schedule Check-in',
    CompanionLanguage.sinhala => 'හමුවීමක් සැලසුම් කරන්න',
    CompanionLanguage.tamil => 'சந்திப்பை திட்டமிடவும்',
  };

  String get connectionScreenComingSoon => switch (language) {
    CompanionLanguage.english => 'Current Connection (W07) is coming soon.',
    CompanionLanguage.sinhala => 'වත්මන් සම්බන්ධතා තිරය (W07) ළඟදීම පැමිණේ.',
    CompanionLanguage.tamil => 'தற்போதைய இணைப்பு திரை (W07) விரைவில் வரும்.',
  };

  String get schedulingHandOffComingSoon => switch (language) {
    CompanionLanguage.english => 'Scheduling hand-off (H01) is coming soon.',
    CompanionLanguage.sinhala => 'හමුවීම් සැලසුම් කිරීම (H01) ළඟදීම පැමිණේ.',
    CompanionLanguage.tamil => 'சந்திப்பு திட்டமிடல் (H01) விரைவில் வரும்.',
  };

  String get declinedScreenComingSoon => switch (language) {
    CompanionLanguage.english => 'Declined screen (W06B) is coming soon.',
    CompanionLanguage.sinhala => 'ප්‍රතික්ෂේප කිරීමේ තිරය (W06B) ළඟදීම පැමිණේ.',
    CompanionLanguage.tamil => 'நிராகரிக்கப்பட்ட திரை (W06B) விரைவில் வரும்.',
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
