import 'package:carelink_app/features/companion/models/companion_connection.dart';
import 'package:carelink_app/features/companion/models/companion_profile.dart';
import 'package:carelink_app/features/companion/models/conversation_idea.dart';
import 'package:carelink_app/features/companion/models/match_preferences.dart';
import 'package:carelink_app/features/companion/models/match_request.dart';
import 'package:carelink_app/features/companion/services/mock_companion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pure companion models round-trip without Firebase types', () {
    const profile = CompanionProfile(
      id: 'student_1',
      userId: 'student_1',
      name: 'Student One',
      imagePath: '',
      verified: true,
      languages: ['Sinhala'],
      interests: ['Music'],
      availability: 'Weekend Evening',
      about: 'A volunteer',
    );
    const preferences = MatchPreferences(
      preferredLanguage: 'Sinhala',
      interests: ['Music'],
      availability: 'Weekends',
      preferredTime: 'Evening',
    );
    const idea = ConversationIdea(
      id: 'music',
      interest: 'Music',
      textEn: 'Favourite song?',
      textSi: 'Song?',
      textTa: 'Song?',
    );
    final now = DateTime.utc(2026, 10, 6);
    final request = MatchRequest(
      id: 'pair',
      elderId: 'elder',
      companionId: 'student_1',
      status: MatchRequestStatus.pending,
      createdAt: now,
    );
    final connection = CompanionConnection(
      id: 'pair',
      elderId: 'elder',
      companionId: 'student_1',
      matchRequestId: 'pair',
      status: ConnectionStatus.active,
      startedAt: now,
    );

    expect(CompanionProfile.fromMap(profile.toMap()).name, profile.name);
    expect(MatchPreferences.fromMap(preferences.toMap()).interests, ['Music']);
    expect(ConversationIdea.fromMap(idea.toMap()).textEn, idea.textEn);
    expect(MatchRequest.fromMap(request.toMap()).createdAt, now);
    expect(
      CompanionConnection.fromMap(connection.toMap()).status,
      ConnectionStatus.active,
    );
  });

  test('matching profile maps public fields and tolerates optional gaps', () {
    final profile = CompanionProfile.fromMap({
      'id': 'student_1',
      'userId': 'student_1',
      'fullName': 'Student One',
      'active': true,
      'verified': true,
      'languages': ['Sinhala'],
      'interests': ['Music'],
      'availability': 'Weekends',
      'preferredTimes': ['Evening'],
      'profileImageUrl': 'https://example.invalid/profile.jpg',
    });

    expect(profile.name, 'Student One');
    expect(profile.languages, ['Sinhala']);
    expect(profile.interests, ['Music']);
    expect(profile.availableSlots, ['Weekends']);
    expect(profile.preferredTimes, ['Evening']);
    expect(profile.profileImageUrl, 'https://example.invalid/profile.jpg');
    expect(profile.about, isEmpty);
    expect(profile.toMap().keys, isNot(contains('email')));
    expect(profile.toMap().keys, isNot(contains('phone')));
  });

  test('mock ranking produces reasons only for actual matches', () async {
    final service = MockCompanionService();
    const preferences = MatchPreferences(
      preferredLanguage: 'English',
      interests: ['Books', 'Movies'],
      availability: 'Weekends',
      preferredTime: 'Morning',
    );
    final results = await service.getRecommendations(preferences);
    expect(results.first.companion.name, 'Amaya Perera');
    expect(results.first.reasons, contains('2 shared interests'));
    expect(results.first.reasons, contains('Speaks English'));
    expect(results.first.reasons, contains('Available at your preferred time'));
  });

  test('mock prevents a duplicate pending request and decline creates no connection', () async {
    final service = MockCompanionService();
    final request = await service.sendMatchRequest(
      elderId: 'elder_1',
      companionId: 'companion_amaya',
    );
    await expectLater(
      service.sendMatchRequest(
        elderId: 'elder_1',
        companionId: 'companion_amaya',
      ),
      throwsStateError,
    );
    final declined = await service.updateMatchRequestStatus(
      requestId: request.id,
      status: MatchRequestStatus.declined,
    );
    expect(declined.status, MatchRequestStatus.declined);
    expect(await service.getCurrentConnection('elder_1'), isNull);
  });
}
