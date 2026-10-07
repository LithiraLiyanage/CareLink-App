import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/controllers/companion_controller.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_profile.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/screens/current_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/end_connection_confirmation_screen.dart';
import 'package:carelink_app/features/companion/screens/recommended_companions_screen.dart';
import 'package:carelink_app/features/companion/services/mock_companion_service.dart';
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

void main() {
  for (final language in CompanionLanguage.values) {
    testWidgets('W07 → W08 → W08B keeps the connection in $language', (
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
          home: CurrentConnectionScreen(
            profile: _profile,
            selectedLanguage: language,
          ),
        ),
      );

      await tester.tap(find.text(strings.manageConnection));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(strings.reviewEndConnection));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.reviewEndConnection));
      await tester.pumpAndSettle();

      expect(find.text(strings.endThisConnection), findsOneWidget);
      expect(
        find.text(strings.endConnectionDescription('Nethmi')),
        findsOneWidget,
      );
      expect(find.text(_profile.name), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text(strings.keepConnection));
      await tester.tap(find.text(strings.keepConnection));
      await tester.pumpAndSettle();

      expect(find.text(strings.reviewEndConnection), findsOneWidget);
      expect(find.text(strings.endThisConnection), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('End removes Active screens and Back does not restore them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const language = CompanionLanguage.tamil;
    final strings = CompanionStrings(language);
    final navigatorKey = GlobalKey<NavigatorState>();
    final controller = CompanionController(service: MockCompanionService());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: CareLinkTheme.lightTheme,
        home: const Scaffold(body: Center(child: Text('Matching preferences'))),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/companion-recommendations'),
        builder: (_) => RecommendedCompanionsScreen(
          selectedLanguage: language,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const EndConnectionConfirmationScreen(
          profile: _profile,
          selectedLanguage: language,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(strings.endConnection));
    await tester.tap(find.text(strings.endConnection));
    await tester.pumpAndSettle();

    expect(find.text(strings.recommendedCompanions), findsOneWidget);
    expect(find.text(strings.currentConnectionActive), findsNothing);
    expect(tester.takeException(), isNull);

    await navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Matching preferences'), findsOneWidget);
    expect(find.text(strings.currentConnectionActive), findsNothing);
  });
}
