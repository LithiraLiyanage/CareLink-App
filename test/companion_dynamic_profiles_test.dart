import 'dart:async';

import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/controllers/companion_controller.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/models/match_preferences.dart';
import 'package:carelink_app/features/companion/models/match_recommendation.dart';
import 'package:carelink_app/features/companion/screens/companion_profile_screen.dart';
import 'package:carelink_app/features/companion/screens/connection_accepted_screen.dart';
import 'package:carelink_app/features/companion/screens/current_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/connection_paused_screen.dart';
import 'package:carelink_app/features/companion/screens/end_connection_confirmation_screen.dart';
import 'package:carelink_app/features/companion/screens/manage_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/matching_preferences_screen.dart';
import 'package:carelink_app/features/companion/screens/recommended_companions_screen.dart';
import 'package:carelink_app/features/companion/screens/request_pending_screen.dart';
import 'package:carelink_app/features/companion/screens/send_match_request_screen.dart';
import 'package:carelink_app/features/companion/screens/scheduling_handoff_screen.dart';
import 'package:carelink_app/features/companion/services/companion_recommendations.dart';
import 'package:carelink_app/features/companion/services/mock_companion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _EmptyMockService extends MockCompanionService {
  @override
  Future<List<MatchRecommendation>> getRecommendations(
    MatchPreferences preferences,
  ) async => const [];
}

class _FailingMockService extends MockCompanionService {
  @override
  Future<List<MatchRecommendation>> getRecommendations(
    MatchPreferences preferences,
  ) async => throw StateError('Offline for test');
}

class _DelayedMockService extends MockCompanionService {
  final completer = Completer<List<MatchRecommendation>>();
  int calls = 0;

  @override
  Future<List<MatchRecommendation>> getRecommendations(
    MatchPreferences preferences,
  ) {
    calls++;
    return completer.future;
  }
}

void main() {
  for (final language in CompanionLanguage.values) {
    for (final seedProfile in CompanionRecommendations.profiles) {
      testWidgets('${seedProfile.name} stays selected in ${language.name}', (
        tester,
      ) async {
        final profile = (await MockCompanionService().getCompanionById(
          'companion_${seedProfile.id}',
        ))!;
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final strings = CompanionStrings(language);
        await tester.pumpWidget(
          MaterialApp(
            theme: CareLinkTheme.lightTheme,
            home: const MatchingPreferencesScreen(),
          ),
        );

        await _tapVisible(tester, find.text(language.displayLabel));
        await _tapVisible(tester, find.text('Find Companions'));
        expect(find.byType(RecommendedCompanionsScreen), findsOneWidget);
        expect(find.text(strings.recommendedCompanions), findsOneWidget);

        if (profile.id == 'companion_nethmi') {
          await _tapVisible(tester, find.text(strings.viewProfile));
        } else {
          await _tapVisible(tester, find.text(profile.name));
        }

        expect(find.byType(CompanionProfileScreen), findsOneWidget);
        expect(find.text(profile.name), findsOneWidget);
        expect(find.text(strings.profileAbout(profile)), findsOneWidget);
        for (final interest in profile.interests) {
          expect(find.text(strings.interestLabel(interest)), findsWidgets);
        }

        await _tapVisible(tester, find.text(strings.sendMatchRequest));
        expect(find.byType(SendMatchRequestScreen), findsOneWidget);
        expect(find.text(profile.name), findsOneWidget);

        await _tapVisible(tester, find.text(strings.reviewSendRequest));
        expect(find.byType(RequestPendingScreen), findsOneWidget);
        expect(
          find.text(strings.waitingForCompanion(profile.firstName)),
          findsOneWidget,
        );

        await _tapVisible(tester, find.text(strings.simulateAccept));
        expect(find.byType(ConnectionAcceptedScreen), findsOneWidget);
        expect(
          find.text(strings.youAndCompanionConnected(profile.firstName)),
          findsOneWidget,
        );

        await _tapVisible(tester, find.text(strings.viewConnection));
        expect(find.byType(CurrentConnectionScreen), findsOneWidget);
        expect(find.text(profile.name), findsOneWidget);
        expect(find.text(strings.myConnection), findsOneWidget);
        expect(find.text(strings.currentConnectionActive), findsOneWidget);
        for (final interest in profile.interests.take(2)) {
          expect(find.text(strings.interestLabel(interest)), findsWidgets);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('mock scoring ranks A Kavindu, B Amaya, and C Nethmi', () async {
    final service = MockCompanionService();
    const amayaPreferences = MatchPreferences(
      preferredLanguage: 'English',
      interests: ['Books', 'Movies'],
      availability: 'Weekends',
      preferredTime: 'Morning',
      checkInType: '',
    );
    const kavinduPreferences = MatchPreferences(
      preferredLanguage: 'Sinhala',
      interests: ['Music', 'Culture'],
      availability: 'Weekdays',
      preferredTime: 'Evening',
      checkInType: '',
    );

    final amayaResults = await service.getRecommendations(amayaPreferences);
    final kavinduResults = await service.getRecommendations(kavinduPreferences);
    expect(amayaResults.first.companion.id, 'companion_amaya');
    expect(kavinduResults.first.companion.id, 'companion_kavindu');
    expect(amayaResults.first.score, 12);
    expect(kavinduResults.first.score, 12);
    expect(amayaResults.first.reasons, [
      'Speaks English',
      '2 shared interests',
      'Available at your preferred time',
    ]);
    expect(amayaResults.last.reasons, isEmpty);
    const nethmiPreferences = MatchPreferences(
      preferredLanguage: 'Sinhala',
      interests: ['Gardening', 'Music'],
      availability: 'Weekends',
      preferredTime: 'Evening',
      checkInType: '',
    );
    final nethmiResults = await service.getRecommendations(nethmiPreferences);
    expect(nethmiResults.first.companion.id, 'companion_nethmi');
    expect(nethmiResults.first.score, 12);
    expect(nethmiResults.first.reasons, [
      'Speaks Sinhala',
      '2 shared interests',
      'Available at your preferred time',
    ]);
  });

  testWidgets(
    'W01 hands preferences to controller without changing UI language',
    (tester) async {
      final controller = CompanionController(service: MockCompanionService());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: CareLinkTheme.lightTheme,
          home: MatchingPreferencesScreen(
            controller: controller,
            uiLanguage: CompanionLanguage.tamil,
          ),
        ),
      );

      await _tapVisible(
        tester,
        find.text(CompanionLanguage.sinhala.displayLabel),
      );
      await _tapVisible(tester, find.text('Music'));
      await _tapVisible(tester, find.text('Culture'));
      await _tapVisible(tester, find.text('Weekdays'));
      await _tapVisible(tester, find.text('Evening'));
      await _tapVisible(tester, find.text('Voice'));
      await _tapVisible(tester, find.text('Find Companions'));

      final preferences = controller.currentPreferences!;
      expect(preferences.preferredLanguage, 'Sinhala');
      expect(preferences.interests, containsAll(['Music', 'Culture']));
      expect(preferences.availabilitySelections, ['Weekdays']);
      expect(preferences.preferredTime, 'Evening');
      expect(preferences.checkInType, 'Voice');
      expect(
        controller.recommendations.first.companion.id,
        'companion_kavindu',
      );
      final screen = tester.widget<RecommendedCompanionsScreen>(
        find.byType(RecommendedCompanionsScreen),
      );
      expect(screen.selectedLanguage, CompanionLanguage.tamil);

      await _tapVisible(
        tester,
        find.text(CompanionStrings(CompanionLanguage.tamil).viewProfile),
      );
      expect(controller.selectedCompanion?.id, 'companion_kavindu');
    },
  );

  testWidgets('W01 disables duplicate search taps while loading', (
    tester,
  ) async {
    final service = _DelayedMockService();
    final controller = CompanionController(service: service);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: CareLinkTheme.lightTheme,
        home: MatchingPreferencesScreen(controller: controller),
      ),
    );
    await tester.tap(find.text('Find Companions'));
    await tester.pump();
    expect(service.calls, 1);
    expect(find.text('Finding Companions…'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byType(ElevatedButton).first)
          .onPressed,
      isNull,
    );
    service.completer.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byType(RecommendedCompanionsScreen), findsOneWidget);
  });

  testWidgets('W01 stays put and offers retry after a service error', (
    tester,
  ) async {
    final controller = CompanionController(service: _FailingMockService());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: CareLinkTheme.lightTheme,
        home: MatchingPreferencesScreen(controller: controller),
      ),
    );
    await tester.tap(find.text('Find Companions'));
    await tester.pumpAndSettle();
    expect(find.byType(RecommendedCompanionsScreen), findsNothing);
    expect(
      find.text('We couldn’t load companions. Please try again.'),
      findsOneWidget,
    );
    expect(controller.errorMessage, contains('Offline for test'));
    expect(controller.isLoading, isFalse);
  });

  testWidgets('W02 has an inline empty state with Adjust Preferences', (
    tester,
  ) async {
    final controller = CompanionController(service: _EmptyMockService());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: CareLinkTheme.lightTheme,
        home: RecommendedCompanionsScreen(
          selectedLanguage: CompanionLanguage.english,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No suitable companions found yet.'), findsOneWidget);
    expect(
      find.text('Try adjusting your language, interests or availability.'),
      findsOneWidget,
    );
    expect(find.text('Adjust preferences →'), findsOneWidget);
  });

  testWidgets('featured Amaya Send Request uses Amaya, not Nethmi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const preferences = MatchPreferences(
      preferredLanguage: 'English',
      interests: ['Books', 'Movies'],
      availability: 'Weekends',
      preferredTime: 'Morning',
      checkInType: '',
    );
    const language = CompanionLanguage.tamil;
    final strings = CompanionStrings(language);
    await tester.pumpWidget(
      MaterialApp(
        theme: CareLinkTheme.lightTheme,
        home: const RecommendedCompanionsScreen(
          selectedLanguage: language,
          preferences: preferences,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text(strings.sendRequest));
    expect(find.byType(SendMatchRequestScreen), findsOneWidget);
    expect(find.text('Amaya Perera'), findsOneWidget);
    expect(find.text(strings.sendMatchRequest), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final profileId in ['amaya', 'kavindu']) {
    testWidgets('$profileId featured card fits small phone at 2× text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferences = profileId == 'amaya'
          ? const MatchPreferences(
              preferredLanguage: 'English',
              interests: ['Books', 'Movies'],
              availability: 'Weekends',
              preferredTime: 'Morning',
              checkInType: '',
            )
          : const MatchPreferences(
              preferredLanguage: 'Sinhala',
              interests: ['Music', 'Culture'],
              availability: 'Weekdays',
              preferredTime: 'Evening',
              checkInType: '',
            );
      await tester.pumpWidget(
        MaterialApp(
          theme: CareLinkTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: RecommendedCompanionsScreen(
            selectedLanguage: CompanionLanguage.tamil,
            preferences: preferences,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Amaya stays selected through manage, pause, and hand-off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const language = CompanionLanguage.sinhala;
    final strings = CompanionStrings(language);
    final amaya = CompanionRecommendations.profiles[1];

    await tester.pumpWidget(
      MaterialApp(
        theme: CareLinkTheme.lightTheme,
        home: CurrentConnectionScreen(
          profile: amaya,
          selectedLanguage: language,
        ),
      ),
    );

    await _tapVisible(tester, find.text(strings.manageConnection));
    expect(find.byType(ManageConnectionScreen), findsOneWidget);
    expect(find.text(amaya.name), findsOneWidget);
    await _tapVisible(tester, find.text(strings.reviewEndConnection));
    expect(find.byType(EndConnectionConfirmationScreen), findsOneWidget);
    expect(
      find.text(strings.endConnectionDescription(amaya.firstName)),
      findsOneWidget,
    );
    await _tapVisible(tester, find.text(strings.keepConnection));
    await _tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, strings.pauseConnection),
    );
    expect(find.byType(ConnectionPausedScreen), findsOneWidget);
    expect(find.text(amaya.name), findsOneWidget);
    await _tapVisible(tester, find.text(strings.resumeConnection));
    expect(find.byType(CurrentConnectionScreen), findsOneWidget);
    expect(find.text(amaya.name), findsOneWidget);

    await _tapVisible(tester, find.text(strings.viewOrScheduleCheckIn));
    expect(find.byType(SchedulingHandoffScreen), findsOneWidget);
    expect(find.text(strings.readyToSchedule(amaya.firstName)), findsOneWidget);
    final handoff = tester.widget<SchedulingHandoffScreen>(
      find.byType(SchedulingHandoffScreen),
    );
    expect(handoff.schedulingDetails.companionId, amaya.id);
    expect(handoff.schedulingDetails.companionName, amaya.name);
    expect(handoff.schedulingDetails.language, language);
    expect(tester.takeException(), isNull);
  });
}
