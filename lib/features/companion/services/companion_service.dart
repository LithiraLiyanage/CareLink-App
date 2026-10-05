import '../models/companion_connection.dart';
import '../models/companion_profile.dart';
import '../models/conversation_idea.dart';
import '../models/match_preferences.dart';
import '../models/match_recommendation.dart';
import '../models/match_request.dart';

/// Storage-independent contract for companion matching and connection state.
abstract class CompanionService {
  Future<List<MatchRecommendation>> getRecommendations(
    MatchPreferences preferences,
  );

  Future<CompanionProfile?> getCompanionById(String companionId);

  Future<MatchRequest> sendMatchRequest({
    required String elderId,
    required String companionId,
  });

  Future<MatchRequest> updateMatchRequestStatus({
    required String requestId,
    required MatchRequestStatus status,
  });

  Future<CompanionConnection> createConnectionFromAcceptedRequest(
    MatchRequest request,
  );

  Future<CompanionConnection?> getCurrentConnection(String elderId);

  Future<CompanionConnection> pauseConnection(CompanionConnection connection);

  Future<CompanionConnection> resumeConnection(CompanionConnection connection);

  Future<CompanionConnection> endConnection(CompanionConnection connection);

  Future<List<ConversationIdea>> getConversationIdeas(
    List<String> elderInterests,
  );
}
