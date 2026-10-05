import '../models/companion_connection.dart';
import '../models/companion_profile.dart';
import '../models/conversation_idea.dart';
import '../models/match_preferences.dart';
import '../models/match_recommendation.dart';
import '../models/match_request.dart';
import 'companion_service.dart';

/// In-memory implementation for development; no personal conversation data.
class MockCompanionService implements CompanionService {
  MockCompanionService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, MatchRequest> _requests = {};
  final Map<String, CompanionConnection> _connections = {};
  int _nextRequestId = 0;
  int _nextConnectionId = 0;

  static const List<CompanionProfile> _profiles = [
    CompanionProfile(
      id: 'companion_nethmi',
      userId: 'user_nethmi',
      name: 'Nethmi Jayasooriya',
      imagePath: 'assets/images/companion_nethmi.png',
      verified: true,
      languages: ['Sinhala', 'English', 'Tamil'],
      interests: ['Gardening', 'Music'],
      availability: 'Sunday Evening',
      availabilitySlots: ['Sunday Evening'],
      shortAvailability: 'Sunday evenings',
      about: 'Verified student volunteer who enjoys gardening, music and meaningful conversations.',
    ),
    CompanionProfile(
      id: 'companion_amaya',
      userId: 'user_amaya',
      name: 'Amaya Perera',
      imagePath: 'assets/images/companion_amaya.png',
      verified: true,
      languages: ['English'],
      interests: ['Books', 'Movies'],
      availability: 'Weekend Morning',
      availabilitySlots: ['Weekend Morning'],
      shortAvailability: 'Weekend morning',
      about: 'Verified student volunteer who enjoys books, movies and friendly conversations.',
    ),
    CompanionProfile(
      id: 'companion_kavindu',
      userId: 'user_kavindu',
      name: 'Kavindu Silva',
      imagePath: 'assets/images/companion_kavindu.png',
      verified: true,
      languages: ['Sinhala'],
      interests: ['Music', 'Culture'],
      availability: 'Weekday Evening',
      availabilitySlots: ['Weekday Evening'],
      shortAvailability: 'Weekday evening',
      about: 'Verified student volunteer interested in music, culture and meaningful conversations.',
    ),
  ];

  static const List<ConversationIdea> _ideas = [
    ConversationIdea(
      id: 'gardening',
      interest: 'Gardening',
      textEn: 'What flowers or plants did you enjoy growing?',
      textSi: 'ඔබ වගා කිරීමට කැමති මල් හෝ පැළ වර්ග මොනවාද?',
      textTa: 'எந்த மலர்கள் அல்லது செடிகளை வளர்க்க விரும்பினீர்கள்?',
    ),
    ConversationIdea(
      id: 'music',
      interest: 'Music',
      textEn: 'What songs did you enjoy when you were younger?',
      textSi: 'ඔබ තරුණ කාලයේ කැමති වූ ගීත මොනවාද?',
      textTa: 'இளமையில் நீங்கள் ரசித்த பாடல்கள் என்ன?',
    ),
    ConversationIdea(
      id: 'books',
      interest: 'Books',
      textEn: 'Is there a book or story you still remember fondly?',
      textSi: 'ඔබට තවමත් සතුටින් මතක ඇති පොතක් හෝ කතාවක් තිබේද?',
      textTa: 'நீங்கள் இன்னும் அன்புடன் நினைக்கும் புத்தகம் அல்லது கதை உள்ளதா?',
    ),
    ConversationIdea(
      id: 'movies',
      interest: 'Movies',
      textEn: 'What movie did you enjoy watching the most?',
      textSi: 'ඔබ වැඩියෙන්ම රසවිඳි චිත්‍රපටය කුමක්ද?',
      textTa: 'நீங்கள் மிகவும் ரசித்த திரைப்படம் எது?',
    ),
    ConversationIdea(
      id: 'culture',
      interest: 'Culture',
      textEn: 'What traditions did you enjoy with your family?',
      textSi: 'ඔබ පවුල සමඟ රසවිඳි සම්ප්‍රදායන් මොනවාද?',
      textTa: 'குடும்பத்துடன் நீங்கள் ரசித்த பாரம்பரியங்கள் என்ன?',
    ),
    ConversationIdea(
      id: 'cooking',
      interest: 'Cooking',
      textEn: 'What meal do you enjoy making for your family?',
      textSi: 'ඔබ පවුලට සාදා දීමට කැමති ආහාරය කුමක්ද?',
      textTa: 'உங்கள் குடும்பத்திற்குச் சமைக்க விரும்பும் உணவு எது?',
    ),
    ConversationIdea(
      id: 'travel',
      interest: 'Travel',
      textEn: 'What place would you enjoy visiting again?',
      textSi: 'ඔබ නැවත යාමට කැමති ස්ථානය කුමක්ද?',
      textTa: 'நீங்கள் மீண்டும் செல்ல விரும்பும் இடம் எது?',
    ),
    ConversationIdea(
      id: 'general-day',
      interest: 'General',
      textEn: 'What has made you smile today?',
      textSi: 'අද ඔබට සතුටක් ගෙන දුන්නේ කුමක්ද?',
      textTa: 'இன்று உங்களை புன்னகைக்க வைத்தது எது?',
    ),
    ConversationIdea(
      id: 'general-memory',
      interest: 'General',
      textEn: 'Would you like to share a happy memory?',
      textSi: 'ඔබ සතුටු මතකයක් බෙදා ගැනීමට කැමතිද?',
      textTa: 'ஒரு மகிழ்ச்சியான நினைவை பகிர விரும்புகிறீர்களா?',
    ),
  ];

  @override
  Future<List<MatchRecommendation>> getRecommendations(
    MatchPreferences preferences,
  ) async {
    final ranked = <MatchRecommendation>[];
    for (final companion in _profiles) {
      if (!companion.verified || !companion.active) continue;
      final shared = preferences.interests
          .where(
            (interest) => companion.interests.any(
              (other) => other.toLowerCase() == interest.toLowerCase(),
            ),
          )
          .map((interest) => interest.toLowerCase())
          .toSet();
      final languageMatch = companion.languages.any(
        (language) =>
            language.toLowerCase() ==
            preferences.preferredLanguage.toLowerCase(),
      );
      final availability = companion.availableSlots.join(' ').toLowerCase();
      final desiredDay = preferences.availability.trim().toLowerCase();
      final dayMatch = switch (desiredDay) {
        'weekend' || 'weekends' =>
          availability.contains('weekend') ||
              availability.contains('saturday') ||
              availability.contains('sunday'),
        'weekday' || 'weekdays' => availability.contains('weekday'),
        _ => desiredDay.isNotEmpty && availability.contains(desiredDay),
      };
      final desiredTime = preferences.preferredTime.trim().toLowerCase();
      final timeMatch =
          desiredTime.isNotEmpty && availability.contains(desiredTime);
      final score =
          (languageMatch ? 3 : 0) +
          shared.length * 2 +
          (dayMatch ? 3 : 0) +
          (timeMatch ? 2 : 0);
      ranked.add(
        MatchRecommendation(
          companion: companion,
          score: score,
          reasons: List.unmodifiable([
            if (languageMatch) 'Speaks ${preferences.preferredLanguage}',
            if (shared.isNotEmpty)
              '${shared.length} shared ${shared.length == 1 ? 'interest' : 'interests'}',
            if (dayMatch && timeMatch) 'Available at your preferred time',
            if (dayMatch && !timeMatch) 'Available on your preferred days',
            if (timeMatch && !dayMatch)
              'Available at your preferred time of day',
          ]),
        ),
      );
    }
    ranked.sort((a, b) {
      final difference = b.score.compareTo(a.score);
      if (difference != 0) return difference;
      return _profiles
          .indexOf(a.companion)
          .compareTo(_profiles.indexOf(b.companion));
    });
    return List.unmodifiable(ranked);
  }

  @override
  Future<CompanionProfile?> getCompanionById(String companionId) async {
    for (final profile in _profiles) {
      if (profile.id == companionId) return profile;
    }
    return null;
  }

  @override
  Future<MatchRequest> sendMatchRequest({
    required String elderId,
    required String companionId,
  }) async {
    if (elderId.trim().isEmpty) throw ArgumentError.value(elderId, 'elderId');
    final companion = await getCompanionById(companionId);
    if (companion == null || !companion.verified || !companion.active) {
      throw StateError('Companion is unavailable.');
    }
    if (_requests.values.any(
      (request) =>
          request.elderId == elderId &&
          request.companionId == companionId &&
          request.status == MatchRequestStatus.pending,
    )) {
      throw StateError('A request to this companion is already pending.');
    }
    if (_connections.values.any(
      (connection) =>
          connection.elderId == elderId &&
          connection.status != ConnectionStatus.ended,
    )) {
      throw StateError('An active or paused connection already exists.');
    }
    final request = MatchRequest(
      id: 'request_${++_nextRequestId}',
      elderId: elderId,
      companionId: companionId,
      status: MatchRequestStatus.pending,
      createdAt: _now(),
    );
    _requests[request.id] = request;
    return request;
  }

  @override
  Future<MatchRequest> updateMatchRequestStatus({
    required String requestId,
    required MatchRequestStatus status,
  }) async {
    final current = _requests[requestId];
    if (current == null) throw StateError('Match request was not found.');
    if (current.status != MatchRequestStatus.pending ||
        status == MatchRequestStatus.pending) {
      throw StateError('Only a pending request can receive a decision.');
    }
    final updated = current.copyWith(status: status, respondedAt: _now());
    _requests[requestId] = updated;
    return updated;
  }

  @override
  Future<CompanionConnection> createConnectionFromAcceptedRequest(
    MatchRequest request,
  ) async {
    final stored = _requests[request.id];
    if (stored == null ||
        stored.status != MatchRequestStatus.accepted ||
        stored.elderId != request.elderId ||
        stored.companionId != request.companionId) {
      throw StateError('Only an accepted request can create a connection.');
    }
    for (final existing in _connections.values) {
      if (existing.matchRequestId == request.id) return existing;
      if (existing.elderId == request.elderId &&
          existing.status != ConnectionStatus.ended) {
        throw StateError('An active or paused connection already exists.');
      }
    }
    final connection = CompanionConnection(
      id: 'connection_${++_nextConnectionId}',
      elderId: request.elderId,
      companionId: request.companionId,
      matchRequestId: request.id,
      status: ConnectionStatus.active,
      startedAt: _now(),
    );
    _connections[connection.id] = connection;
    return connection;
  }

  @override
  Future<CompanionConnection?> getCurrentConnection(String elderId) async {
    for (final connection in _connections.values.toList().reversed) {
      if (connection.elderId == elderId &&
          connection.status != ConnectionStatus.ended) {
        return connection;
      }
    }
    return null;
  }

  CompanionConnection _currentStored(CompanionConnection connection) {
    final stored = _connections[connection.id];
    if (stored == null ||
        stored.elderId != connection.elderId ||
        stored.companionId != connection.companionId) {
      throw StateError('Connection was not found.');
    }
    return stored;
  }

  @override
  Future<CompanionConnection> pauseConnection(
    CompanionConnection connection,
  ) async {
    final current = _currentStored(connection);
    if (current.status != ConnectionStatus.active) {
      throw StateError('Only an active connection can be paused.');
    }
    final updated = current.copyWith(
      status: ConnectionStatus.paused,
      pausedAt: _now(),
    );
    _connections[current.id] = updated;
    return updated;
  }

  @override
  Future<CompanionConnection> resumeConnection(
    CompanionConnection connection,
  ) async {
    final current = _currentStored(connection);
    if (current.status != ConnectionStatus.paused) {
      throw StateError('Only a paused connection can be resumed.');
    }
    final updated = current.copyWith(
      status: ConnectionStatus.active,
      clearPausedAt: true,
    );
    _connections[current.id] = updated;
    return updated;
  }

  @override
  Future<CompanionConnection> endConnection(
    CompanionConnection connection,
  ) async {
    final current = _currentStored(connection);
    if (current.status == ConnectionStatus.ended) {
      throw StateError('Connection has already ended.');
    }
    final updated = current.copyWith(
      status: ConnectionStatus.ended,
      endedAt: _now(),
      clearPausedAt: true,
    );
    _connections[current.id] = updated;
    return updated;
  }

  @override
  Future<List<ConversationIdea>> getConversationIdeas(
    List<String> elderInterests,
  ) async {
    final interests = elderInterests
        .map((value) => value.toLowerCase())
        .toList();
    final ranked = _ideas.where((idea) => idea.active).toList();
    int priority(ConversationIdea idea) {
      final matchIndex = interests.indexOf(idea.interest.toLowerCase());
      if (matchIndex >= 0) return matchIndex;
      return idea.interest == 'General' ? 100 : 200;
    }

    ranked.sort((a, b) {
      final difference = priority(a).compareTo(priority(b));
      if (difference != 0) return difference;
      return _ideas.indexOf(a).compareTo(_ideas.indexOf(b));
    });
    return List.unmodifiable(ranked);
  }
}
