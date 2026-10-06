import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/controllers/companion_controller.dart';
import 'package:carelink_app/features/companion/models/companion_connection.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/models/match_preferences.dart';
import 'package:carelink_app/features/companion/models/match_request.dart';
import 'package:carelink_app/features/companion/screens/connection_paused_screen.dart';
import 'package:carelink_app/features/companion/screens/conversation_ideas_screen.dart';
import 'package:carelink_app/features/companion/screens/current_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/recommended_companions_screen.dart';
import 'package:carelink_app/features/companion/screens/scheduling_handoff_screen.dart';
import 'package:carelink_app/features/companion/services/mock_companion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases =
      <({String id, MatchPreferences preferences, List<String> shared})>[
        (
          id: 'companion_nethmi',
          preferences: MatchPreferences(
            preferredLanguage: 'Sinhala',
            interests: ['Gardening', 'Music'],
            availability: 'Weekends',
            preferredTime: 'Evening',
          ),
          shared: ['Gardening', 'Music'],
        ),
        (
          id: 'companion_amaya',
          preferences: MatchPreferences(
            preferredLanguage: 'English',
            interests: ['Books', 'Movies'],
            availability: 'Weekends',
            preferredTime: 'Morning',
          ),
          shared: ['Books', 'Movies'],
        ),
        (
          id: 'companion_kavindu',
          preferences: MatchPreferences(
            preferredLanguage: 'Sinhala',
            interests: ['Music', 'Culture'],
            availability: 'Weekdays',
            preferredTime: 'Evening',
          ),
          shared: ['Music', 'Culture'],
        ),
      ];

  for (final testCase in cases) {
    test(
      '${testCase.id} stays selected across request and connection',
      () async {
        final service = MockCompanionService();
        final controller = CompanionController(service: service);
        addTearDown(controller.dispose);

        await controller.loadRecommendations(testCase.preferences);
        expect(controller.recommendations.first.companion.id, testCase.id);
        controller.selectRecommendation(controller.recommendations.first);
        expect(controller.selectedCompanion?.id, testCase.id);
        expect(controller.sharedInterests, testCase.shared);

        await controller.sendRequest();
        expect(controller.currentRequest?.elderId, service.currentElderId);
        expect(controller.currentRequest?.status, MatchRequestStatus.pending);
        expect(controller.currentRequest?.companionId, testCase.id);
        expect(controller.currentConnection, isNull);

        await controller.acceptCurrentRequest();
        expect(controller.currentRequest?.status, MatchRequestStatus.accepted);
        expect(controller.currentConnection?.status, ConnectionStatus.active);
        expect(controller.currentConnection?.companionId, testCase.id);

        await controller.loadConversationIdeas();
        expect(
          controller.conversationIdeas.first.interest,
          testCase.preferences.interests.first,
        );

        await controller.pauseCurrentConnection();
        expect(controller.currentConnection?.status, ConnectionStatus.paused);
        await controller.resumeCurrentConnection();
        expect(controller.currentConnection?.status, ConnectionStatus.active);
        await controller.endCurrentConnection();
        expect(controller.currentConnection?.status, ConnectionStatus.ended);
        expect(
          await service.getCurrentConnection(service.currentElderId),
          isNull,
        );
        await controller.resumeCurrentConnection();
        expect(controller.errorMessage, isNotNull);
        expect(controller.currentConnection?.status, ConnectionStatus.ended);
      },
    );
  }

  test('declined request never creates an active connection', () async {
    final service = MockCompanionService();
    final controller = CompanionController(service: service);
    addTearDown(controller.dispose);
    await controller.loadRecommendations(cases.first.preferences);
    controller.selectRecommendation(controller.recommendations.first);
    await controller.sendRequest();
    await controller.declineCurrentRequest();
    expect(controller.currentRequest?.status, MatchRequestStatus.declined);
    expect(controller.currentRequest?.elderId, service.currentElderId);
    expect(controller.currentConnection, isNull);
    expect(await service.getCurrentConnection(service.currentElderId), isNull);
    await controller.acceptCurrentRequest();
    expect(controller.errorMessage, isNotNull);
    expect(controller.currentConnection, isNull);
  });

  testWidgets(
    'active Amaya UI keeps state through ideas, hand-off, pause and end',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = MockCompanionService();
      final controller = CompanionController(service: service);
      addTearDown(controller.dispose);
      await controller.loadRecommendations(cases[1].preferences);
      controller.selectRecommendation(controller.recommendations.first);
      await controller.sendRequest();
      await controller.acceptCurrentRequest();
      final profile = controller.selectedCompanion!;
      const language = CompanionLanguage.sinhala;
      const strings = CompanionStrings(language);

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: CareLinkTheme.lightTheme,
          home: CurrentConnectionScreen(
            profile: profile,
            selectedLanguage: language,
            controller: controller,
          ),
        ),
      );
      await tap(find.text(strings.conversationIdeas));
      expect(find.byType(ConversationIdeasScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('conversation-idea-books')),
        findsOneWidget,
      );
      await tap(find.byTooltip(strings.backToCheckIn));

      await tap(find.text(strings.viewOrScheduleCheckIn));
      final handoff = tester.widget<SchedulingHandoffScreen>(
        find.byType(SchedulingHandoffScreen),
      );
      expect(handoff.schedulingDetails.companionId, profile.id);
      expect(
        handoff.schedulingDetails.connectionId,
        controller.currentConnection?.id,
      );
      expect(handoff.schedulingDetails.elderId, service.currentElderId);
      await tap(find.text(strings.backToConnection));

      await tap(find.text(strings.manageConnection));
      await tap(find.widgetWithText(OutlinedButton, strings.pauseConnection));
      expect(find.byType(ConnectionPausedScreen), findsOneWidget);
      expect(controller.currentConnection?.status, ConnectionStatus.paused);
      await tap(find.text(strings.backToConnection));
      expect(controller.currentConnection?.status, ConnectionStatus.paused);
      await tap(find.text(strings.manageConnection));
      await tap(find.widgetWithText(OutlinedButton, strings.resumeConnection));
      await tap(find.widgetWithText(ElevatedButton, strings.resumeConnection));
      expect(controller.currentConnection?.status, ConnectionStatus.active);

      await tap(find.text(strings.manageConnection));
      await tap(find.text(strings.reviewEndConnection));
      await tap(find.widgetWithText(OutlinedButton, strings.endConnection));
      expect(controller.currentConnection?.status, ConnectionStatus.ended);
      expect(find.byType(RecommendedCompanionsScreen), findsOneWidget);
      expect(find.byType(CurrentConnectionScreen), findsNothing);
    },
  );
}
