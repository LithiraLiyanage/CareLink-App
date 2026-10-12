import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/controllers/companion_controller.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_profile.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/models/match_preferences.dart';
import 'package:carelink_app/features/companion/screens/conversation_ideas_screen.dart';
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
    testWidgets(
      'W09 prioritizes Books and Movies for Amaya in ${language.name}',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = CompanionController(service: MockCompanionService());
        addTearDown(controller.dispose);
        await controller.loadRecommendations(
          const MatchPreferences(
            preferredLanguage: 'English',
            interests: ['Books', 'Movies'],
            availability: 'Weekends',
            preferredTime: 'Morning',
          ),
        );
        controller.selectRecommendation(controller.recommendations.first);
        final profile = controller.selectedCompanion!;
        expect(profile.name, 'Amaya Perera');

        await tester.pumpWidget(
          MaterialApp(
            theme: CareLinkTheme.lightTheme,
            home: ConversationIdeasScreen(
              profile: profile,
              selectedLanguage: language,
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('conversation-idea-books')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('conversation-idea-movies')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('conversation-idea-gardening')),
          findsNothing,
        );
        final book = controller.conversationIdeas.first;
        final expected = switch (language) {
          CompanionLanguage.english => book.textEn,
          CompanionLanguage.sinhala => book.textSi,
          CompanionLanguage.tamil => book.textTa,
        };
        expect(find.text(expected), findsOneWidget);
        await tester.tap(find.text(CompanionStrings(language).showAnotherIdea));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('conversation-idea-movies')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final language in CompanionLanguage.values) {
    testWidgets('W09 ideas are optional and selectable in $language', (
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
          home: ConversationIdeasScreen(
            profile: _profile,
            selectedLanguage: language,
          ),
        ),
      );

      expect(find.text(strings.conversationIdeas), findsOneWidget);
      expect(find.text(strings.conversationIdeasHelper), findsOneWidget);
      expect(find.text(strings.conversationIdeasReassurance), findsOneWidget);
      expect(find.text(strings.useThisIdea), findsNWidgets(4));
      expect(
        find.byKey(const ValueKey('conversation-idea-gardening')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('conversation-idea-music')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('conversation-idea-food-traditions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('conversation-idea-memories')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final gardeningButton = find.descendant(
        of: find.byKey(const ValueKey('conversation-idea-gardening')),
        matching: find.byType(OutlinedButton),
      );
      await tester.ensureVisible(gardeningButton);
      await tester.tap(gardeningButton);
      await tester.pump();
      expect(find.text(strings.ideaSelected), findsOneWidget);
      expect(find.text(strings.useThisIdea), findsNWidgets(3));

      await tester.tap(find.text(strings.showAnotherIdea));
      await tester.pumpAndSettle();
      final musicTop = tester.getTopLeft(
        find.byKey(const ValueKey('conversation-idea-music')),
      );
      final gardeningTop = tester.getTopLeft(
        find.byKey(const ValueKey('conversation-idea-gardening')),
      );
      expect(musicTop.dy, lessThan(gardeningTop.dy));
      expect(find.text(strings.ideaSelected), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('W09 supports larger text and a check-in return', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: CareLinkTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(body: Center(child: Text('Check-in'))),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const ConversationIdeasScreen(
          profile: _profile,
          selectedLanguage: CompanionLanguage.tamil,
          openedFromCheckIn: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final backLabel = const CompanionStrings(CompanionLanguage.tamil)
        .backToCheckIn;
    await tester.tap(find.text(backLabel));
    await tester.pumpAndSettle();
    expect(find.text('Check-in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
