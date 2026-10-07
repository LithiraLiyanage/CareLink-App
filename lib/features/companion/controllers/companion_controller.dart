import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/companion_connection.dart';
import '../models/companion_incoming_request.dart';
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

  bool get supportsSimulatedResponses => service.supportsSimulatedResponses;

  MatchPreferences? currentPreferences;
  List<MatchRecommendation> recommendations = const [];
  CompanionProfile? selectedCompanion;
  MatchRequest? currentRequest;
  CompanionConnection? currentConnection;
  CompanionConnection? studentConnection;
  MatchRequest? studentConnectionRequest;
  bool isLoadingStudentConnection = false;
  String? studentConnectionError;
  List<ConversationIdea> conversationIdeas = const [];
  List<CompanionIncomingRequest> incomingRequests = const [];
  bool isLoading = false;
  bool isLoadingIncomingRequests = false;
  String? errorMessage;
  String? incomingRequestsError;
  StreamSubscription<MatchRequest?>? _requestSubscription;
  StreamSubscription<CompanionConnection?>? _connectionSubscription;
  StreamSubscription<CompanionConnection?>? _studentConnectionSubscription;
  StreamSubscription<List<CompanionIncomingRequest>>?
  _incomingRequestsSubscription;
  String? _refreshedAcceptedRequestId;
  bool _disposed = false;

  Future<void> _stopWatching() async {
    final request = _requestSubscription;
    final connection = _connectionSubscription;
    final studentConnection = _studentConnectionSubscription;
    final incoming = _incomingRequestsSubscription;
    _requestSubscription = null;
    _connectionSubscription = null;
    _studentConnectionSubscription = null;
    _incomingRequestsSubscription = null;
    await request?.cancel();
    await connection?.cancel();
    await studentConnection?.cancel();
    await incoming?.cancel();
  }

  Future<void> _watchCurrentFlow(MatchRequest request) async {
    await _stopWatching();
    _requestSubscription = service
        .watchMatchRequest(request.id)
        .listen(
          (latest) {
            if (_disposed || latest?.id != currentRequest?.id) return;
            currentRequest = latest;
            if (latest?.status == MatchRequestStatus.accepted &&
                _refreshedAcceptedRequestId != latest?.id) {
              _refreshedAcceptedRequestId = latest!.id;
              unawaited(_refreshSelectedCompanion(latest.companionId));
            }
            if (latest!.status == MatchRequestStatus.declined ||
                latest.status == MatchRequestStatus.cancelled) {
              currentConnection = null;
            }
            notifyListeners();
          },
          onError: (Object error) {
            if (_disposed) return;
            errorMessage = error.toString();
            notifyListeners();
          },
        );
    _connectionSubscription = service
        .watchCurrentConnection(request.elderId)
        .listen(
          (latest) {
            if (_disposed ||
                latest != null && latest.companionId != selectedCompanion?.id) {
              return;
            }
            if (latest == null &&
                currentConnection?.status == ConnectionStatus.ended) {
              return;
            }
            currentConnection = latest;
            notifyListeners();
          },
          onError: (Object error) {
            if (_disposed) return;
            errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> _refreshSelectedCompanion(String companionId) async {
    try {
      final refreshed = await service.getCompanionById(companionId);
      if (_disposed ||
          refreshed == null ||
          selectedCompanion?.id != companionId) {
        return;
      }
      selectedCompanion = refreshed;
      notifyListeners();
    } catch (error) {
      if (_disposed) return;
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_stopWatching());
    super.dispose();
  }

  MatchRecommendation? get selectedRecommendation {
    final id = selectedCompanion?.id;
    if (id == null) return null;
    for (final recommendation in recommendations) {
      if (recommendation.companion.id == id) return recommendation;
    }
    return null;
  }

  List<String> get sharedInterests {
    final preferences = currentPreferences;
    final companion = selectedCompanion;
    if (preferences == null || companion == null) return const [];
    return List.unmodifiable(
      companion.interests.where(
        (interest) => preferences.interests.any(
          (selected) => selected.toLowerCase() == interest.toLowerCase(),
        ),
      ),
    );
  }

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
        await service.saveMatchPreferences(preferences);
        final loaded = await service.getRecommendations(preferences);
        currentPreferences = preferences;
        recommendations = loaded;
      });

  void selectCompanion(CompanionProfile companion) {
    if (selectedCompanion?.id != companion.id) {
      unawaited(_stopWatching());
      currentRequest = null;
      currentConnection = null;
    }
    selectedCompanion = companion;
    errorMessage = null;
    notifyListeners();
  }

  void selectRecommendation(MatchRecommendation recommendation) {
    selectCompanion(recommendation.companion);
  }

  Future<void> sendRequest() => _run(() async {
    final companion = selectedCompanion;
    if (companion == null) throw StateError('Select a companion first.');
    currentRequest = await service.sendMatchRequest(
      elderId: service.currentElderId,
      companionId: companion.id,
    );
    await _watchCurrentFlow(currentRequest!);
  });

  void watchIncomingRequests() {
    if (_incomingRequestsSubscription != null) return;
    isLoadingIncomingRequests = true;
    incomingRequestsError = null;
    notifyListeners();
    _incomingRequestsSubscription = service.watchIncomingRequests().listen(
      (latest) {
        if (_disposed) return;
        incomingRequests = latest;
        isLoadingIncomingRequests = false;
        incomingRequestsError = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_disposed) return;
        isLoadingIncomingRequests = false;
        incomingRequestsError = error.toString();
        notifyListeners();
      },
    );
  }

  void watchCompanionConnection() {
    if (_studentConnectionSubscription != null) return;
    isLoadingStudentConnection = true;
    studentConnectionError = null;
    notifyListeners();
    _studentConnectionSubscription = service.watchCompanionConnection().listen(
      (latest) {
        if (_disposed) return;
        studentConnection = latest;
        if (latest == null) {
          studentConnectionRequest = null;
        } else if (studentConnectionRequest?.id != latest.matchRequestId) {
          studentConnectionRequest = null;
          unawaited(_loadStudentConnectionRequest(latest));
        }
        isLoadingStudentConnection = false;
        studentConnectionError = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_disposed) return;
        isLoadingStudentConnection = false;
        studentConnectionError = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> _loadStudentConnectionRequest(
    CompanionConnection connection,
  ) async {
    final requestId = connection.matchRequestId;
    if (requestId == null) return;
    try {
      final request = await service.getAcceptedRequest(requestId);
      if (_disposed || studentConnection?.id != connection.id) return;
      studentConnectionRequest = request;
      notifyListeners();
    } catch (error) {
      if (_disposed || studentConnection?.id != connection.id) return;
      studentConnectionError = error.toString();
      notifyListeners();
    }
  }

  Future<void> respondToIncomingRequest({
    required CompanionIncomingRequest incoming,
    required MatchRequestStatus status,
  }) => _run(() async {
    if (status != MatchRequestStatus.accepted &&
        status != MatchRequestStatus.declined) {
      throw ArgumentError.value(
        status,
        'status',
        'Incoming requests can only be accepted or declined.',
      );
    }
    final updated = await service.updateMatchRequestStatus(
      requestId: incoming.request.id,
      status: status,
    );
    currentRequest = updated;
    if (updated.status == MatchRequestStatus.accepted) {
      currentConnection = await service.createConnectionFromAcceptedRequest(
        updated,
      );
    } else {
      currentConnection = null;
    }
    incomingRequests = incomingRequests
        .where((request) => request.request.id != updated.id)
        .toList(growable: false);
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

  Future<void> loadConversationIdeas({List<String>? interests}) =>
      _run(() async {
        conversationIdeas = await service.getConversationIdeas(
          interests ?? currentPreferences?.interests ?? const [],
        );
      });
}
