import 'package:flutter/foundation.dart';

import '../models/companion_connection.dart';
import '../models/companion_profile.dart';
import '../models/conversation_idea.dart';
import '../models/match_preferences.dart';
import '../models/match_recommendation.dart';
import '../models/match_request.dart';
import '../services/companion_service.dart';

/// Feature state independent of the eventual service implementation.
class CompanionController extends ChangeNotifier {
  CompanionController({required this.service});

  final CompanionService service;

  MatchPreferences? currentPreferences;
  List<MatchRecommendation> recommendations = const [];
  CompanionProfile? selectedCompanion;
  MatchRequest? currentRequest;
  CompanionConnection? currentConnection;
  List<ConversationIdea> conversationIdeas = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> _run(Future<void> Function() operation) async {
    if (isLoading) {
      errorMessage = 'Another companion action is still in progress.';
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendations(MatchPreferences preferences) =>
      _run(() async {
        final loaded = await service.getRecommendations(preferences);
        currentPreferences = preferences;
        recommendations = loaded;
      });

  void selectCompanion(CompanionProfile companion) {
    if (selectedCompanion?.id != companion.id) {
      currentRequest = null;
      currentConnection = null;
    }
    selectedCompanion = companion;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> sendRequest(String elderId) => _run(() async {
    final companion = selectedCompanion;
    if (companion == null) throw StateError('Select a companion first.');
    currentRequest = await service.sendMatchRequest(
      elderId: elderId,
      companionId: companion.id,
    );
  });

  Future<void> acceptCurrentRequest() => _run(() async {
    var request = currentRequest;
    if (request == null) throw StateError('No match request is selected.');
    if (request.status == MatchRequestStatus.pending) {
      request = await service.updateMatchRequestStatus(
        requestId: request.id,
        status: MatchRequestStatus.accepted,
      );
      currentRequest = request;
    }
    if (request.status != MatchRequestStatus.accepted) {
      throw StateError('Only a pending or accepted request can connect.');
    }
    currentConnection = await service.createConnectionFromAcceptedRequest(
      request,
    );
  });

  Future<void> declineCurrentRequest() => _run(() async {
    final request = currentRequest;
    if (request == null) throw StateError('No match request is selected.');
    currentRequest = await service.updateMatchRequestStatus(
      requestId: request.id,
      status: MatchRequestStatus.declined,
    );
    currentConnection = null;
  });

  Future<void> cancelCurrentRequest() => _run(() async {
    final request = currentRequest;
    if (request == null) throw StateError('No match request is selected.');
    currentRequest = await service.updateMatchRequestStatus(
      requestId: request.id,
      status: MatchRequestStatus.cancelled,
    );
    currentConnection = null;
  });

  Future<void> loadCurrentConnection(String elderId) => _run(() async {
    currentConnection = await service.getCurrentConnection(elderId);
  });

  Future<void> pauseCurrentConnection() => _run(() async {
    final connection = currentConnection;
    if (connection == null) throw StateError('No connection is selected.');
    currentConnection = await service.pauseConnection(connection);
  });

  Future<void> resumeCurrentConnection() => _run(() async {
    final connection = currentConnection;
    if (connection == null) throw StateError('No connection is selected.');
    currentConnection = await service.resumeConnection(connection);
  });

  Future<void> endCurrentConnection() => _run(() async {
    final connection = currentConnection;
    if (connection == null) throw StateError('No connection is selected.');
    // Keep the ended record for the current UI state, while the service will
    // no longer return it from getCurrentConnection.
    currentConnection = await service.endConnection(connection);
  });

  Future<void> loadConversationIdeas() => _run(() async {
    conversationIdeas = await service.getConversationIdeas(
      currentPreferences?.interests ?? const [],
    );
  });
}
