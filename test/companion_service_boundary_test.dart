import 'package:carelink_app/features/companion/controllers/companion_controller.dart';
import 'package:carelink_app/features/companion/controllers/companion_controller_factory.dart';
import 'package:carelink_app/features/companion/models/companion_connection.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/models/match_preferences.dart';
import 'package:carelink_app/features/companion/models/match_request.dart';
import 'package:carelink_app/features/companion/screens/request_pending_screen.dart';
import 'package:carelink_app/features/companion/screens/connection_accepted_screen.dart';
import 'package:carelink_app/features/companion/screens/scheduling_handoff_screen.dart';
import 'package:carelink_app/features/companion/services/firebase_companion_service.dart';
import 'package:carelink_app/features/companion/services/mock_companion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoSimulationMockService extends MockCompanionService {
  @override
  bool get supportsSimulatedResponses => false;
}

class _CustomElderMockService extends MockCompanionService {
  @override
  String get currentElderId => 'mock_elder_from_service';
}

void main() {
  test('authenticated service selection uses Firebase by default', () {
    expect(createCompanionService(), isA<FirebaseCompanionService>());
    final controller = createCompanionController();
    expect(controller.service, isA<FirebaseCompanionService>());
    controller.dispose();
  });

  final rankingCases = [
    (
      'companion_kavindu',
      const MatchPreferences(
        preferredLanguage: 'Sinhala',
        interests: ['Music', 'Culture'],
        availability: 'Weekdays',
        preferredTime: 'Evening',
      ),
    ),
    (
      'companion_amaya',
      const MatchPreferences(
        preferredLanguage: 'English',
        interests: ['Books', 'Movies'],
        availability: 'Weekends',
        preferredTime: 'Morning',
      ),
    ),
    (
      'companion_nethmi',
      const MatchPreferences(
        preferredLanguage: 'Sinhala',
        interests: ['Gardening', 'Music'],
        availability: 'Weekends',
        preferredTime: 'Evening',
      ),
    ),
  ];

  for (final (expectedId, preferences) in rankingCases) {
    test('$expectedId ranks first from actual mock preferences', () async {
      final controller = createCompanionController(
        service: MockCompanionService(),
      );
      addTearDown(controller.dispose);
      await controller.loadRecommendations(preferences);
      expect(controller.errorMessage, isNull);
      expect(controller.recommendations.first.companion.id, expectedId);
      expect(controller.recommendations.first.reasons, isNotEmpty);
    });
  }

  test(
    'request identity comes from the service and hand-off is minimal',
    () async {
      final controller = CompanionController(
        service: _CustomElderMockService(),
      );
      addTearDown(controller.dispose);
      const preferences = MatchPreferences(
        preferredLanguage: 'English',
        interests: ['Books', 'Movies'],
        availability: 'Weekends',
        preferredTime: 'Morning',
        checkInType: 'Voice',
      );
      await controller.loadRecommendations(preferences);
      controller.selectRecommendation(controller.recommendations.first);
      await controller.sendRequest();
      expect(controller.currentRequest?.elderId, 'mock_elder_from_service');
      expect(controller.currentRequest?.status, MatchRequestStatus.pending);
      expect(controller.currentConnection, isNull);
      await controller.acceptCurrentRequest();
      expect(controller.currentConnection?.status, ConnectionStatus.active);
      final accepted = await controller.service.getAcceptedRequest(
        controller.currentRequest!.id,
      );
      expect(accepted?.status, MatchRequestStatus.accepted);

      final handoff = SchedulingHandoffScreen(
        profile: controller.selectedCompanion!,
        selectedLanguage: CompanionLanguage.english,
        controller: controller,
      ).schedulingDetails;
      expect(handoff.elderId, 'mock_elder_from_service');
      expect(handoff.companionId, controller.selectedCompanion!.id);
      expect(handoff.connectionId, controller.currentConnection!.id);
      expect(handoff.preferredCheckInType, 'Voice');

      await controller.pauseCurrentConnection();
      expect(controller.currentConnection?.status, ConnectionStatus.paused);
      await controller.resumeCurrentConnection();
      expect(controller.currentConnection?.status, ConnectionStatus.active);
      await controller.endCurrentConnection();
      expect(controller.currentConnection?.status, ConnectionStatus.ended);
    },
  );

  testWidgets('pending simulation controls are hidden for a non-mock mode', (
    tester,
  ) async {
    final service = _NoSimulationMockService();
    final controller = CompanionController(service: service);
    addTearDown(controller.dispose);
    final profile = (await service.getCompanionById('companion_amaya'))!;
    controller.selectCompanion(profile);
    await controller.sendRequest();
    const language = CompanionLanguage.english;
    final strings = CompanionStrings(language);

    await tester.pumpWidget(
      MaterialApp(
        home: RequestPendingScreen(
          profile: profile,
          selectedLanguage: language,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(strings.simulateAccept), findsNothing);
    expect(find.text(strings.simulateDecline), findsNothing);
    expect(find.text(strings.cancelRequest), findsOneWidget);
  });

  testWidgets('pending simulation controls are hidden without a service', (
    tester,
  ) async {
    final service = MockCompanionService();
    final profile = (await service.getCompanionById('companion_amaya'))!;
    const language = CompanionLanguage.english;
    final strings = CompanionStrings(language);

    await tester.pumpWidget(
      MaterialApp(
        home: RequestPendingScreen(
          profile: profile,
          selectedLanguage: language,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(strings.simulateAccept), findsNothing);
    expect(find.text(strings.simulateDecline), findsNothing);
  });

  testWidgets('W05 renders the cancelled request state', (tester) async {
    final service = MockCompanionService();
    final controller = CompanionController(service: service);
    addTearDown(controller.dispose);
    final profile = (await service.getCompanionById('companion_amaya'))!;
    controller.selectCompanion(profile);
    await controller.sendRequest();
    await controller.cancelCurrentRequest();

    await tester.pumpWidget(
      MaterialApp(
        home: RequestPendingScreen(
          profile: profile,
          selectedLanguage: CompanionLanguage.english,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Request Cancelled'), findsOneWidget);
    expect(find.text('Simulate Accept'), findsNothing);
  });

  testWidgets('W05 renders an accepted request from controller state', (
    tester,
  ) async {
    final service = MockCompanionService();
    final controller = CompanionController(service: service);
    addTearDown(controller.dispose);
    final profile = (await service.getCompanionById('companion_amaya'))!;
    controller.selectCompanion(profile);
    await controller.sendRequest();
    await controller.acceptCurrentRequest();

    await tester.pumpWidget(
      MaterialApp(
        home: RequestPendingScreen(
          profile: profile,
          selectedLanguage: CompanionLanguage.english,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionAcceptedScreen), findsOneWidget);
    expect(find.text('Connection Accepted!'), findsOneWidget);
    expect(find.text('View Connection'), findsOneWidget);
  });
}
