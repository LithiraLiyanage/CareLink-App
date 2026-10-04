import 'package:carelink_app/app/theme.dart';
import 'package:carelink_app/features/companion/models/companion_language.dart';
import 'package:carelink_app/features/companion/models/companion_match.dart';
import 'package:carelink_app/features/companion/models/companion_profile.dart';
import 'package:carelink_app/features/companion/models/companion_strings.dart';
import 'package:carelink_app/features/companion/screens/companion_profile_screen.dart';
import 'package:carelink_app/features/companion/screens/connection_accepted_screen.dart';
import 'package:carelink_app/features/companion/screens/connection_paused_screen.dart';
import 'package:carelink_app/features/companion/screens/conversation_ideas_screen.dart';
import 'package:carelink_app/features/companion/screens/current_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/end_connection_confirmation_screen.dart';
import 'package:carelink_app/features/companion/screens/manage_connection_screen.dart';
import 'package:carelink_app/features/companion/screens/matching_preferences_screen.dart';
import 'package:carelink_app/features/companion/screens/recommended_companions_screen.dart';
import 'package:carelink_app/features/companion/screens/request_pending_screen.dart';
import 'package:carelink_app/features/companion/screens/request_declined_screen.dart';
import 'package:carelink_app/features/companion/screens/scheduling_handoff_screen.dart';
import 'package:carelink_app/features/companion/screens/send_match_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(393, 852),
    const Size(412, 915),
  ]) {
    for (final language in CompanionLanguage.values) {
      for (final textScale in [1.0, 2.0]) {
        testWidgets(
          'companion screens fit $size in $language at $textScale× text',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            final strings = CompanionStrings(language);
            final profile = CompanionProfile(
              id: 'nethmi-jayasooriya',
              name: 'Nethmi Jayasooriya',
              imagePath: '',
              verified: true,
              languages: const ['Sinhala', 'English', 'Tamil'],
              interests: [
                strings.gardening,
                strings.music,
                strings.traditionalFood,
              ],
              availability: strings.sundayAvailability,
              about: strings.volunteerAbout,
            );
            final screens = <Widget>[
              const MatchingPreferencesScreen(),
              RecommendedCompanionsScreen(selectedLanguage: language),
              CompanionProfileScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              SendMatchRequestScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              RequestPendingScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              RequestDeclinedScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              ConnectionAcceptedScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              CurrentConnectionScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              ManageConnectionScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              ConnectionPausedScreen(
                profile: profile,
                selectedLanguage: language,
                connectionStatus: MatchStatus.paused,
              ),
              EndConnectionConfirmationScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              ConversationIdeasScreen(
                profile: profile,
                selectedLanguage: language,
              ),
              SchedulingHandoffScreen(
                profile: profile,
                selectedLanguage: language,
              ),
            ];

            for (final screen in screens) {
              await tester.pumpWidget(
                MaterialApp(
                  theme: CareLinkTheme.lightTheme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(textScale)),
                    child: child!,
                  ),
                  home: screen,
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${screen.runtimeType} at $size in $language at $textScale×',
              );
            }
          },
        );
      }
    }
  }
}
