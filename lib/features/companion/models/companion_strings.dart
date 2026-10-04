import 'companion_language.dart';
import 'conversation_idea.dart';

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

  String get amayaRecommendationDetails => switch (language) {
    CompanionLanguage.english => 'English • Books • Weekend morning',
    CompanionLanguage.sinhala => 'English • පොත් • සති අන්තයේ උදෑසන',
    CompanionLanguage.tamil => 'English • புத்தகங்கள் • வார இறுதி காலை',
  };

  String get kavinduRecommendationDetails => switch (language) {
    CompanionLanguage.english => 'Sinhala • Music • Weekday evening',
    CompanionLanguage.sinhala => 'Sinhala • සංගීතය • සතියේ දිනක සවස',
    CompanionLanguage.tamil => 'Sinhala • இசை • வாரநாள் மாலை',
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

  String get schedulingHandOffComingSoon => switch (language) {
    CompanionLanguage.english => 'Scheduling hand-off (H01) is coming soon.',
    CompanionLanguage.sinhala => 'හමුවීම් සැලසුම් කිරීම (H01) ළඟදීම පැමිණේ.',
    CompanionLanguage.tamil => 'சந்திப்பு திட்டமிடல் (H01) விரைவில் வரும்.',
  };

  String get schedulingHandoffSubtitle => switch (language) {
    CompanionLanguage.english => 'Continue in the CareLink scheduling module.',
    CompanionLanguage.sinhala =>
      'CareLink සැලසුම් කිරීමේ මොඩියුලය වෙත ඉදිරියට යන්න.',
    CompanionLanguage.tamil => 'CareLink திட்டமிடல் தொகுதியில் தொடரவும்.',
  };

  String get systemHandoff => switch (language) {
    CompanionLanguage.english => 'System hand-off',
    CompanionLanguage.sinhala => 'පද්ධති මාරු කිරීම',
    CompanionLanguage.tamil => 'கணினி ஒப்படைப்பு',
  };

  String readyToSchedule(String firstName) => switch (language) {
    CompanionLanguage.english => '$firstName is ready to schedule',
    CompanionLanguage.sinhala => '$firstName හමුවීමක් සැලසුම් කිරීමට සූදානම්.',
    CompanionLanguage.tamil => '$firstName சந்திப்பை திட்டமிட தயாராக உள்ளார்.',
  };

  String get acceptedConnectionHandoffDescription => switch (language) {
    CompanionLanguage.english => 'The accepted connection is passed securely to the Scheduling & Check-in module.',
    CompanionLanguage.sinhala => 'පිළිගත් සම්බන්ධතාව Scheduling & Check-in මොඩියුලය වෙත ආරක්ෂිතව යොමු කරයි.',
    CompanionLanguage.tamil => 'ஏற்கப்பட்ட இணைப்பு Scheduling & Check-in தொகுதிக்கு பாதுகாப்பாக அனுப்பப்படுகிறது.',
  };

  String get nextModule => switch (language) {
    CompanionLanguage.english => 'Next module',
    CompanionLanguage.sinhala => 'ඊළඟ මොඩියුලය',
    CompanionLanguage.tamil => 'அடுத்த தொகுதி',
  };

  String get schedulingNextSteps => switch (language) {
    CompanionLanguage.english =>
      'Select day and time, confirm a check-in, and receive reminders.',
    CompanionLanguage.sinhala =>
      'දිනය සහ වේලාව තෝරා, හමුවීම තහවුරු කර, මතක් කිරීම් ලබා ගන්න.',
    CompanionLanguage.tamil => 'நாள் மற்றும் நேரத்தை தேர்ந்தெடுத்து, சந்திப்பை உறுதிப்படுத்தி, நினைவூட்டல்களை பெறவும்.',
  };

  String get continueToScheduling => switch (language) {
    CompanionLanguage.english => 'Continue to Scheduling',
    CompanionLanguage.sinhala => 'සැලසුම් කිරීම වෙත ඉදිරියට යන්න',
    CompanionLanguage.tamil => 'திட்டமிடலுக்கு தொடரவும்',
  };

  String get backToConnection => switch (language) {
    CompanionLanguage.english => 'Back to Connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව වෙත ආපසු යන්න',
    CompanionLanguage.tamil => 'இணைப்பிற்கு திரும்பவும்',
  };

  String get schedulingIntegrationPending => switch (language) {
    CompanionLanguage.english => 'Scheduling module integration pending',
    CompanionLanguage.sinhala =>
      'සැලසුම් කිරීමේ මොඩියුලය සම්බන්ධ කිරීම තවම සිදු වී නැත.',
    CompanionLanguage.tamil =>
      'திட்டமிடல் தொகுதி இணைப்பு இன்னும் தயாராக இல்லை.',
  };

  String get myConnection => switch (language) {
    CompanionLanguage.english => 'My Connection',
    CompanionLanguage.sinhala => 'මගේ සම්බන්ධතාව',
    CompanionLanguage.tamil => 'என் இணைப்பு',
  };

  String get activeCompanionSubtitle => switch (language) {
    CompanionLanguage.english => 'Your active companion and next actions.',
    CompanionLanguage.sinhala => 'ඔබගේ සක්‍රිය සහචරයා සහ ඊළඟ ක්‍රියා.',
    CompanionLanguage.tamil =>
      'உங்கள் செயலில் உள்ள துணையாளர் மற்றும் அடுத்த செயல்கள்.',
  };

  String get currentConnectionActive => switch (language) {
    CompanionLanguage.english => 'Active',
    CompanionLanguage.sinhala => 'සක්‍රිය',
    CompanionLanguage.tamil => 'செயலில்',
  };

  String get nextCheckIn => switch (language) {
    CompanionLanguage.english => 'Next check-in',
    CompanionLanguage.sinhala => 'ඊළඟ හමුවීම',
    CompanionLanguage.tamil => 'அடுத்த சந்திப்பு',
  };

  String get nextCheckInTime => switch (language) {
    CompanionLanguage.english => 'Sunday • 6:30 PM',
    CompanionLanguage.sinhala => 'ඉරිදා • ප.ව. 6:30',
    CompanionLanguage.tamil => 'ஞாயிறு • மாலை 6:30',
  };

  String get viewOrScheduleCheckIn => switch (language) {
    CompanionLanguage.english => 'View / Schedule Check-in',
    CompanionLanguage.sinhala => 'හමුවීම බලන්න / සැලසුම් කරන්න',
    CompanionLanguage.tamil => 'சந்திப்பை பார்க்கவும் / திட்டமிடவும்',
  };

  String get manageConnection => switch (language) {
    CompanionLanguage.english => 'Manage connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව කළමනාකරණය කරන්න',
    CompanionLanguage.tamil => 'இணைப்பை நிர்வகிக்கவும்',
  };

  String get completedCheckInsUnaffected => switch (language) {
    CompanionLanguage.english =>
      'These actions do not affect completed check-ins.',
    CompanionLanguage.sinhala =>
      'මෙම ක්‍රියා සම්පූර්ණ කළ හමුවීම්වලට බලපාන්නේ නැත.',
    CompanionLanguage.tamil => 'இந்த செயல்கள் முடிந்த சந்திப்புகளை பாதிக்காது.',
  };

  String get manageConnectionTitle => switch (language) {
    CompanionLanguage.english => 'Manage Connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව කළමනාකරණය කරන්න',
    CompanionLanguage.tamil => 'இணைப்பை நிர்வகிக்கவும்',
  };

  String get confirmationProtects => switch (language) {
    CompanionLanguage.english =>
      'Confirmation protects against accidental ending.',
    CompanionLanguage.sinhala =>
      'තහවුරු කිරීම අහම්බෙන් සම්බන්ධතාව අවසන් වීමෙන් ආරක්ෂා කරයි.',
    CompanionLanguage.tamil =>
      'உறுதிப்படுத்தல் தவறுதலாக இணைப்பை முடிப்பதைத் தடுக்கிறது.',
  };

  String get companionSince => switch (language) {
    CompanionLanguage.english => 'Companion since Aug 2026',
    CompanionLanguage.sinhala => '2026 අගෝස්තු සිට සහචරයා',
    CompanionLanguage.tamil => 'ஆகஸ்ட் 2026 முதல் துணையாளர்',
  };

  String get reviewEndConnection => switch (language) {
    CompanionLanguage.english => 'Review End Connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව අවසන් කිරීම පරීක්ෂා කරන්න',
    CompanionLanguage.tamil => 'இணைப்பை முடிப்பதை சரிபார்க்கவும்',
  };

  String get endThisConnection => switch (language) {
    CompanionLanguage.english => 'End this connection?',
    CompanionLanguage.sinhala => 'මෙම සම්බන්ධතාව අවසන් කරන්නද?',
    CompanionLanguage.tamil => 'இந்த இணைப்பை முடிக்கவா?',
  };

  String endConnectionDescription(String firstName) => switch (language) {
    CompanionLanguage.english =>
      'This will end your active connection with $firstName. You can still find another companion later.',
    CompanionLanguage.sinhala =>
      'මෙය $firstName සමඟ ඇති ඔබගේ සක්‍රිය සම්බන්ධතාව අවසන් කරයි. ඔබට පසුව වෙනත් සහචරයෙකු සොයාගත හැක.',
    CompanionLanguage.tamil =>
      'இது $firstName உடனான உங்கள் செயலில் உள்ள இணைப்பை முடிக்கும். பின்னர் நீங்கள் மற்றொரு துணையாளரை தேடலாம்.',
  };

  String get keepConnection => switch (language) {
    CompanionLanguage.english => 'Keep Connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව තබා ගන්න',
    CompanionLanguage.tamil => 'இணைப்பை தொடரவும்',
  };

  String get endConnection => switch (language) {
    CompanionLanguage.english => 'End Connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව අවසන් කරන්න',
    CompanionLanguage.tamil => 'இணைப்பை முடிக்கவும்',
  };

  String get connectionEnded => switch (language) {
    CompanionLanguage.english => 'Connection ended.',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව අවසන් කර ඇත.',
    CompanionLanguage.tamil => 'இணைப்பு முடிக்கப்பட்டது.',
  };

  String get manageConnectionComingSoon => switch (language) {
    CompanionLanguage.english => 'Manage Connection (W08) is coming soon.',
    CompanionLanguage.sinhala =>
      'සම්බන්ධතාව කළමනාකරණය කිරීම (W08) ළඟදීම පැමිණේ.',
    CompanionLanguage.tamil =>
      'இணைப்பை நிர்வகிக்கும் திரை (W08) விரைவில் வரும்.',
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

  String get conversationIdeas => switch (language) {
    CompanionLanguage.english => 'Conversation Ideas',
    CompanionLanguage.sinhala => 'සංවාද අදහස්',
    CompanionLanguage.tamil => 'உரையாடல் யோசனைகள்',
  };

  String get conversationIdeasHelper => switch (language) {
    CompanionLanguage.english => 'Optional - choose only if helpful',
    CompanionLanguage.sinhala => 'අවශ්‍ය නම් පමණක් භාවිතා කරන්න',
    CompanionLanguage.tamil => 'உதவியாக இருந்தால் மட்டும் தேர்வு செய்யவும்',
  };

  String get useThisIdea => switch (language) {
    CompanionLanguage.english => 'Use this idea',
    CompanionLanguage.sinhala => 'මෙම අදහස භාවිතා කරන්න',
    CompanionLanguage.tamil => 'இந்த யோசனையை பயன்படுத்தவும்',
  };

  String get ideaSelected => switch (language) {
    CompanionLanguage.english => 'Selected',
    CompanionLanguage.sinhala => 'තෝරා ඇත',
    CompanionLanguage.tamil => 'தேர்ந்தெடுக்கப்பட்டது',
  };

  String get showAnotherIdea => switch (language) {
    CompanionLanguage.english => 'Show Another Idea',
    CompanionLanguage.sinhala => 'වෙනත් අදහසක් පෙන්වන්න',
    CompanionLanguage.tamil => 'மற்றொரு யோசனையை காண்பிக்கவும்',
  };

  String get backToCheckIn => switch (language) {
    CompanionLanguage.english => 'Back to Check-in',
    CompanionLanguage.sinhala => 'හමුවීමට ආපසු යන්න',
    CompanionLanguage.tamil => 'சந்திப்பிற்கு திரும்பவும்',
  };

  String get conversationIdeasReassurance => switch (language) {
    CompanionLanguage.english =>
      'These are conversation starters, not questions you must answer.',
    CompanionLanguage.sinhala => 'මේවා සංවාදයක් ආරම්භ කිරීමට උපකාරී වන අදහස් පමණි. ඔබට ඒවාට පිළිතුරු දීම අනිවාර්ය නොවේ.',
    CompanionLanguage.tamil => 'இவை உரையாடலை தொடங்க உதவும் யோசனைகள் மட்டுமே. நீங்கள் பதிலளிக்க வேண்டிய கட்டாயம் இல்லை.',
  };

  String get foodAndTraditions => switch (language) {
    CompanionLanguage.english => 'Food & Traditions',
    CompanionLanguage.sinhala => 'ආහාර සහ සම්ප්‍රදායන්',
    CompanionLanguage.tamil => 'உணவு மற்றும் பாரம்பரியங்கள்',
  };

  String get memories => switch (language) {
    CompanionLanguage.english => 'Memories',
    CompanionLanguage.sinhala => 'මතකයන්',
    CompanionLanguage.tamil => 'நினைவுகள்',
  };

  String conversationIdeaCategory(ConversationIdea idea) => switch (idea.id) {
    'gardening' => gardening,
    'music' => music,
    'food-traditions' => foodAndTraditions,
    'memories' => memories,
    _ => idea.category,
  };

  String conversationIdeaPrompt(ConversationIdea idea) =>
      switch ((language, idea.id)) {
        (CompanionLanguage.sinhala, 'gardening') =>
          'ඔබ වගා කිරීමට වඩාත් කැමති ශාකය කුමක්ද?',
        (CompanionLanguage.tamil, 'gardening') =>
          'எந்த செடியை வளர்ப்பதில் நீங்கள் அதிகம் மகிழ்கிறீர்கள்?',
        (CompanionLanguage.sinhala, 'music') =>
          'ඔබට සතුටු මතකයක් මතක් කරන ගීතය කුමක්ද?',
        (CompanionLanguage.tamil, 'music') =>
          'எந்த பாடல் உங்களுக்கு மகிழ்ச்சியான நினைவைக் கொண்டுவருகிறது?',
        (CompanionLanguage.sinhala, 'food-traditions') =>
          'ඔබට නිවස මතක් කරන ආහාරය කුමක්ද?',
        (CompanionLanguage.tamil, 'food-traditions') =>
          'எந்த உணவு உங்களுக்கு வீட்டை நினைவுபடுத்துகிறது?',
        (CompanionLanguage.sinhala, 'memories') =>
          'ඔබ කැමති ඡායාරූපයක් ගැන කතා කිරීමට කැමතිද?',
        (CompanionLanguage.tamil, 'memories') =>
          'உங்களுக்கு பிடித்த ஒரு புகைப்படத்தைப் பற்றி பேச விரும்புகிறீர்களா?',
        _ => idea.prompt,
      };

  String get navigationComingSoon => switch (language) {
    CompanionLanguage.english => 'Navigation will be connected soon.',
    CompanionLanguage.sinhala => 'සංචලනය ළඟදීම සම්බන්ධ කෙරේ.',
    CompanionLanguage.tamil => 'வழிசெலுத்தல் விரைவில் இணைக்கப்படும்.',
  };

  String get requestNotAccepted => switch (language) {
    CompanionLanguage.english => 'Request Not Accepted',
    CompanionLanguage.sinhala => 'ඉල්ලීම පිළිගෙන නැත',
    CompanionLanguage.tamil => 'கோரிக்கை ஏற்கப்படவில்லை',
  };

  String get requestDeclinedMessage => switch (language) {
    CompanionLanguage.english =>
      "That's okay. You can explore other suitable companions.",
    CompanionLanguage.sinhala =>
      'එය ගැටලුවක් නොවේ. ඔබට වෙනත් සුදුසු සහචරයින් සොයා බැලිය හැක.',
    CompanionLanguage.tamil =>
      'பரவாயில்லை. நீங்கள் மற்ற பொருத்தமான துணையாளர்களை பார்க்கலாம்.',
  };

  String get declined => switch (language) {
    CompanionLanguage.english => 'Declined',
    CompanionLanguage.sinhala => 'ප්‍රතික්ෂේප කර ඇත',
    CompanionLanguage.tamil => 'நிராகரிக்கப்பட்டது',
  };

  String get declinedPrivacyMessage => switch (language) {
    CompanionLanguage.english => 'No active connection was created and your private information remains protected.',
    CompanionLanguage.sinhala => 'සක්‍රිය සම්බන්ධතාවයක් නිර්මාණය වී නොමැති අතර ඔබගේ පෞද්ගලික තොරතුරු ආරක්ෂිතව පවතී.',
    CompanionLanguage.tamil => 'செயலில் உள்ள இணைப்பு உருவாக்கப்படவில்லை மற்றும் உங்கள் தனிப்பட்ட தகவல்கள் பாதுகாப்பாக இருக்கும்.',
  };

  String get findAnotherCompanion => switch (language) {
    CompanionLanguage.english => 'Find Another Companion',
    CompanionLanguage.sinhala => 'වෙනත් සහචරයෙකු සොයන්න',
    CompanionLanguage.tamil => 'மற்றொரு துணையாளரை தேடவும்',
  };

  String get connectionPaused => switch (language) {
    CompanionLanguage.english => 'Connection Paused',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව තාවකාලිකව නවතා ඇත',
    CompanionLanguage.tamil => 'இணைப்பு தற்காலிகமாக நிறுத்தப்பட்டது',
  };

  String get pausedActivitySubtitle => switch (language) {
    CompanionLanguage.english =>
      'Your companionship activity is temporarily paused.',
    CompanionLanguage.sinhala => 'ඔබගේ සහචර ක්‍රියාකාරකම් තාවකාලිකව නවතා ඇත.',
    CompanionLanguage.tamil =>
      'உங்கள் துணையாளர் செயல்பாடு தற்காலிகமாக நிறுத்தப்பட்டுள்ளது.',
  };

  String get paused => switch (language) {
    CompanionLanguage.english => 'Paused',
    CompanionLanguage.sinhala => 'තාවකාලිකව නවතා ඇත',
    CompanionLanguage.tamil => 'தற்காலிகமாக நிறுத்தப்பட்டது',
  };

  String get whatThisMeans => switch (language) {
    CompanionLanguage.english => 'What this means',
    CompanionLanguage.sinhala => 'මෙයින් අදහස් වන්නේ',
    CompanionLanguage.tamil => 'இதன் பொருள்',
  };

  String get pausedMeaning => switch (language) {
    CompanionLanguage.english => 'New companionship activity is paused. Your existing connection can be resumed later.',
    CompanionLanguage.sinhala => 'නව සහචර ක්‍රියාකාරකම් තාවකාලිකව නවතා ඇත. ඔබගේ පවතින සම්බන්ධතාව පසුව නැවත ආරම්භ කළ හැක.',
    CompanionLanguage.tamil => 'புதிய துணையாளர் செயல்பாடு தற்காலிகமாக நிறுத்தப்பட்டுள்ளது. உங்கள் தற்போதைய இணைப்பை பின்னர் மீண்டும் தொடங்கலாம்.',
  };

  String get resumeConnection => switch (language) {
    CompanionLanguage.english => 'Resume Connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව නැවත ආරම්භ කරන්න',
    CompanionLanguage.tamil => 'இணைப்பை மீண்டும் தொடங்கவும்',
  };

  String get pauseConnection => switch (language) {
    CompanionLanguage.english => 'Pause Connection',
    CompanionLanguage.sinhala => 'සම්බන්ධතාව තාවකාලිකව නවත්වන්න',
    CompanionLanguage.tamil => 'இணைப்பை தற்காலிகமாக நிறுத்தவும்',
  };

  String get pauseConnectionDescription => switch (language) {
    CompanionLanguage.english =>
      'Temporarily pause new companionship activity. You can resume later.',
    CompanionLanguage.sinhala =>
      'නව සහචර ක්‍රියාකාරකම් තාවකාලිකව නවතී. ඔබට පසුව නැවත ආරම්භ කළ හැක.',
    CompanionLanguage.tamil => 'புதிய துணையாளர் செயல்பாடு தற்காலிகமாக நிறுத்தப்படும். பின்னர் மீண்டும் தொடங்கலாம்.',
  };
}
