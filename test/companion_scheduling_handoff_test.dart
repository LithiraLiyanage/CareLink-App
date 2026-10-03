import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_profile.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/screens/connection_accepted_screen.dart';
import 'package:carelink_app/features/companion/screens/current_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/scheduling_handoff_screen.dart';
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
  about: 'University student volunteer.',
);

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final language in CompanionLanguage.values) {
    testWidgets('W06 → H01 → W07 preserves $language and companion', (
      tester,
    ) async {
      _setPhoneViewport(tester);
      final strings = CompanionStrings(language);

      await tester.pumpWidget(
        MaterialApp(
          theme: CareLinkTheme.lightTheme,
          home: ConnectionAcceptedScreen(
            profile: _profile,
            selectedLanguage: language,
          ),
        ),
      );

      await tester.tap(find.text(strings.scheduleCheckIn));
      await tester.pumpAndSettle();

      expect(find.byType(SchedulingHandoffScreen), findsOneWidget);
      expect(find.text(strings.schedulingHandoffSubtitle), findsOneWidget);
      expect(find.text(strings.systemHandoff), findsOneWidget);
      expect(find.text(_profile.name), findsOneWidget);
      expect(find.text(strings.readyToSchedule('Nethmi')), findsOneWidget);
      expect(
        find.text(strings.acceptedConnectionHandoffDescription),
        findsOneWidget,
      );
      expect(find.text(strings.nextModule), findsOneWidget);
      expect(find.text(strings.schedulingNextSteps), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(strings.continueToScheduling));
      await tester.pump();
      expect(find.text(strings.schedulingIntegrationPending), findsOneWidget);
      expect(find.byType(SchedulingHandoffScreen), findsOneWidget);

      await tester.tap(find.text(strings.backToConnection));
      await tester.pumpAndSettle();
      expect(find.byType(CurrentConnectionScreen), findsOneWidget);
      expect(find.text(strings.myConnection), findsOneWidget);
      expect(find.byType(SchedulingHandoffScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('W07 → H01 → W07 returns to the same active screen', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    const language = CompanionLanguage.english;
    final strings = CompanionStrings(language);
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: CareLinkTheme.lightTheme,
        home: const CurrentConnectionScreen(
          profile: _profile,
          selectedLanguage: language,
        ),
      ),
    );

    await tester.tap(find.text(strings.viewOrScheduleCheckIn));
    await tester.pumpAndSettle();
    expect(find.byType(SchedulingHandoffScreen), findsOneWidget);

    await tester.tap(find.text(strings.backToConnection));
    await tester.pumpAndSettle();
    expect(find.byType(CurrentConnectionScreen), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('H01 supports 2× text and prepares only minimum hand-off data', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    const screen = SchedulingHandoffScreen(
      profile: _profile,
      selectedLanguage: CompanionLanguage.tamil,
    );
    expect(screen.schedulingDetails.companionId, _profile.id);
    expect(screen.schedulingDetails.companionName, _profile.name);
    expect(screen.schedulingDetails.language, CompanionLanguage.tamil);

    await tester.pumpWidget(
      MaterialApp(
        theme: CareLinkTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: screen,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
