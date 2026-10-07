import 'match_request.dart';

class CompanionIncomingRequest {
  const CompanionIncomingRequest({
    required this.request,
    required this.elderDisplayName,
    required this.preferredLanguage,
    required this.sharedInterests,
    required this.compatibleAvailability,
  });

  final MatchRequest request;
  final String elderDisplayName;
  final String preferredLanguage;
  final List<String> sharedInterests;
  final String compatibleAvailability;
}
