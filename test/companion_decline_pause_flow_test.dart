import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_profile.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/screens/connection_paused_screen.dart';
import 'package:carelink_app/features/companion/screens/current_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/end_connection_confirmation_screen.dart';
import 'package:carelink_app/features/companion/screens/manage_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/matching_preferences_screen.dart';
import 'package:carelink_app/features/companion/screens/recommended_companions_screen.dart';
import 'package:carelink_app/features/companion/screens/request_declined_screen.dart';
import 'package:carelink_app/features/companion/screens/request_pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = CompanionProfile(
  id: 'nethmi-jayasooriya',
  name: 'Nethmi Jayasooriya',
  imagePath: '',
  verified: true,
  languages: ['Sinhala', 'English', 'Tamil'],
  interests: ['Gardening', 'Music'],
  availability: 'Sunday, 4:00 PM - 7:00 PM',
  about: '',
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _openPending(
  WidgetTester tester,
  CompanionLanguage language,
  CompanionStrings strings,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: CareLinkTheme.lightTheme,
      home: const MatchingPreferencesScreen(),
    ),
  );
  await _tapVisible(tester, find.text(language.displayLabel));
  await _tapVisible(tester, find.text('Find Companions'));
  await _tapVisible(tester, find.text(strings.viewProfile));
  await _tapVisible(tester, find.text(strings.sendMatchRequest));
  await _tapVisible(tester, find.text(strings.reviewSendRequest));
  expect(find.byType(RequestPendingScreen), findsOneWidget);
}

void main() {
  for (final language in CompanionLanguage.values) {
    testWidgets('decline returns to recommendations in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final strings = CompanionStrings(language);

      await _openPending(tester, language, strings);
      await _tapVisible(tester, find.text(strings.simulateDecline));
      expect(find.byType(RequestDeclinedScreen), findsOneWidget);
      expect(find.text(strings.requestNotAccepted), findsOneWidget);
      expect(find.text(strings.declined), findsOneWidget);
      expect(find.byType(CurrentConnectionScreen), findsNothing);

      await _tapVisible(tester, find.text(strings.findAnotherCompanion));
      expect(find.byType(RecommendedCompanionsScreen), findsOneWidget);
      expect(find.byType(RequestPendingScreen), findsNothing);
      expect(find.byType(RequestDeclinedScreen), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RequestPendingScreen), findsNothing);
    });

    testWidgets(
      'declined Back to Matches also works from a direct preview in $language',
      (tester) async {
        final strings = CompanionStrings(language);
        await tester.pumpWidget(
          MaterialApp(
            theme: CareLinkTheme.lightTheme,
            home: RequestDeclinedScreen(
              profile: _profile,
              selectedLanguage: language,
            ),
          ),
        );
        await _tapVisible(tester, find.text(strings.backToMatches));
        expect(find.byType(RecommendedCompanionsScreen), findsOneWidget);
        expect(find.byType(RequestDeclinedScreen), findsNothing);
      },
    );

    testWidgets('pause, back, and resume preserve status in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final strings = CompanionStrings(language);

      await _openPending(tester, language, strings);
      await _tapVisible(tester, find.text(strings.simulateAccept));
      await _tapVisible(tester, find.text(strings.viewConnection));
      await _tapVisible(tester, find.text(strings.manageConnection));
      expect(find.byType(ManageConnectionScreen), findsOneWidget);

      await _tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, strings.pauseConnection),
      );
      expect(find.byType(ConnectionPausedScreen), findsOneWidget);
      expect(find.text(strings.connectionPaused), findsOneWidget);
      expect(find.text(strings.paused), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ConnectionPausedScreen), findsOneWidget);

      await _tapVisible(tester, find.text(strings.backToConnection));
      expect(find.byType(CurrentConnectionScreen), findsOneWidget);
      expect(find.text(strings.paused), findsOneWidget);
      final pausedScheduleButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, strings.viewOrScheduleCheckIn),
      );
      expect(pausedScheduleButton.onPressed, isNull);

      await _tapVisible(tester, find.text(strings.manageConnection));
      expect(find.text(strings.paused), findsOneWidget);
      await _tapVisible(tester, find.text(strings.reviewEndConnection));
      expect(find.byType(EndConnectionConfirmationScreen), findsOneWidget);
      expect(find.text(strings.paused), findsOneWidget);
      await _tapVisible(tester, find.text(strings.keepConnection));

      await _tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, strings.resumeConnection),
      );
      expect(find.byType(ConnectionPausedScreen), findsOneWidget);
      await _tapVisible(tester, find.text(strings.resumeConnection));
      expect(find.byType(CurrentConnectionScreen), findsOneWidget);
      expect(find.text(strings.currentConnectionActive), findsOneWidget);
      final activeScheduleButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, strings.viewOrScheduleCheckIn),
      );
      expect(activeScheduleButton.onPressed, isNotNull);
    });
  }
}
