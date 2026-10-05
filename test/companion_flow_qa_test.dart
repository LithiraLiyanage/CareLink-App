import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/screens/companion_profile_screen.dart';
import 'package:carelink_app/features/companion/screens/connection_accepted_screen.dart';
import 'package:carelink_app/features/companion/screens/current_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/end_connection_confirmation_screen.dart';
import 'package:carelink_app/features/companion/screens/manage_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/matching_preferences_screen.dart';
import 'package:carelink_app/features/companion/screens/recommended_companions_screen.dart';
import 'package:carelink_app/features/companion/screens/request_pending_screen.dart';
import 'package:carelink_app/features/companion/screens/send_match_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final language in CompanionLanguage.values) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'accepted, keep, and end flows preserve $language at $textScale× text',
        (tester) async {
          tester.view.physicalSize = const Size(393, 852);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final strings = CompanionStrings(language);
          final navigatorKey = GlobalKey<NavigatorState>();

          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigatorKey,
              theme: CareLinkTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: const MatchingPreferencesScreen(),
            ),
          );
          await _tapVisible(tester, find.text(language.displayLabel));
          await _tapVisible(tester, find.text('Find Companions'));
          expect(find.byType(RecommendedCompanionsScreen), findsOneWidget);
          expect(find.text(strings.recommendedCompanions), findsOneWidget);

          await _tapVisible(tester, find.text(strings.viewProfile));
          expect(find.byType(CompanionProfileScreen), findsOneWidget);
          expect(find.text(strings.whyGoodMatch), findsOneWidget);
          await _tapVisible(tester, find.text(strings.sendMatchRequest));
          expect(find.byType(SendMatchRequestScreen), findsOneWidget);
          expect(find.text(strings.informationShared), findsOneWidget);
          expect(find.text(strings.notShared), findsOneWidget);

          await _tapVisible(tester, find.text(strings.reviewSendRequest));
          expect(find.byType(RequestPendingScreen), findsOneWidget);
          expect(find.byType(CurrentConnectionScreen), findsNothing);
          expect(find.text(strings.pending), findsWidgets);
          await _tapVisible(tester, find.text(strings.simulateAccept));
          expect(find.byType(ConnectionAcceptedScreen), findsOneWidget);
          expect(find.text(strings.connectionStatusActive), findsOneWidget);

          await _tapVisible(tester, find.text(strings.viewConnection));
          expect(find.byType(CurrentConnectionScreen), findsOneWidget);
          expect(find.text(strings.currentConnectionActive), findsOneWidget);
          await _tapVisible(tester, find.text(strings.manageConnection));
          expect(find.byType(ManageConnectionScreen), findsOneWidget);

          await _tapVisible(tester, find.text(strings.reviewEndConnection));
          expect(find.byType(EndConnectionConfirmationScreen), findsOneWidget);
          await _tapVisible(tester, find.text(strings.keepConnection));
          expect(find.byType(ManageConnectionScreen), findsOneWidget);
          await _tapVisible(tester, find.text(strings.reviewEndConnection));
          // W08 remains visible behind the confirmation modal, so scope this
          // action to W08B instead of its background section heading.
          await _tapVisible(
            tester,
            find.descendant(
              of: find.byType(EndConnectionConfirmationScreen),
              matching: find.text(strings.endConnection),
            ),
          );
          expect(find.byType(RecommendedCompanionsScreen), findsOneWidget);
          expect(find.text(strings.currentConnectionActive), findsNothing);

          await navigatorKey.currentState!.maybePop();
          await tester.pumpAndSettle();
          expect(find.byType(MatchingPreferencesScreen), findsOneWidget);
          expect(find.byType(CurrentConnectionScreen), findsNothing);
        },
      );
    }
  }
}
