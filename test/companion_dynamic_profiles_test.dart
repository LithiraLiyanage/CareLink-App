import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/models/match_preferences.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in CompanionLanguage.values) {
    for (final profile in CompanionRecommendations.profiles) {
      testWidgets('${profile.name} stays selected in ${language.name}', (
        tester,
      ) async {
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

        if (profile.id == 'nethmi') {
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

  test('local ordering and reasons follow selected preferences', () {
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

    expect(
      CompanionRecommendations.ordered(amayaPreferences).first.id,
      'amaya',
    );
    expect(
      CompanionRecommendations.ordered(kavinduPreferences).first.id,
      'kavindu',
    );
    expect(
      CompanionRecommendations.reasonsFor(
        CompanionRecommendations.profiles[1],
        amayaPreferences,
      ),
      containsAll(RecommendationReason.values),
    );
    expect(
      CompanionRecommendations.reasonsFor(
        CompanionRecommendations.profiles[2],
        amayaPreferences,
      ),
      isEmpty,
    );
    const nethmiPreferences = MatchPreferences(
      preferredLanguage: 'Sinhala',
      interests: ['Gardening', 'Music'],
      availability: 'Weekends',
      preferredTime: 'Evening',
      checkInType: '',
    );
    expect(
      CompanionRecommendations.reasonsFor(
        CompanionRecommendations.profiles.first,
        nethmiPreferences,
      ),
      containsAll(RecommendationReason.values),
    );
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
