import 'package:flutter/material.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/services/accessibility_controller.dart';
import '../features/companion/controllers/companion_controller.dart';
import '../features/companion/screens/incoming_requests_screen.dart';
import '../features/companion/screens/matching_preferences_screen.dart';
import '../features/companion/screens/student_companion_home_screen.dart';
import '../features/family_safety/screens/family_linking_screen.dart';
import '../features/family_safety/screens/family_pending_screen.dart';
import '../features/family_safety/screens/family_approved_screen.dart';
import '../features/family_safety/screens/family_dashboard_screen.dart';
import '../features/family_safety/screens/missed_session_notification_screen.dart';
import '../features/family_safety/screens/coordinator_case_list_screen.dart';
import '../features/family_safety/screens/coordinator_case_detail_screen.dart';
import '../features/family_safety/screens/consent_context_review_screen.dart';
import '../features/family_safety/screens/approved_contact_action_screen.dart';
import '../features/family_safety/screens/audit_outcome_close_case_screen.dart';
import '../features/family_safety/screens/case_closed_screen.dart';
import 'routes.dart';
import 'theme.dart';

class CareLinkApp extends StatelessWidget {
  const CareLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityPreferences>(
      valueListenable: AccessibilityController.instance,
      builder: (context, preferences, _) {
        final baseTheme = preferences.highContrast
            ? CareLinkTheme.highContrastTheme
            : CareLinkTheme.lightTheme;

        return MaterialApp(
          title: 'CareLink',
          debugShowCheckedModeBanner: false,
          theme: preferences.reduceMotion
              ? baseTheme.copyWith(
                  pageTransitionsTheme: PageTransitionsTheme(
                    builders: {
                      for (final platform in TargetPlatform.values)
                        platform: const _NoMotionPageTransitionsBuilder(),
                    },
                  ),
                )
              : baseTheme,
          themeAnimationDuration: preferences.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            Widget content = MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: preferences.largerText
                    ? mediaQuery.textScaler.clamp(minScaleFactor: 1.2)
                    : mediaQuery.textScaler,
                disableAnimations:
                    mediaQuery.disableAnimations || preferences.reduceMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            );

            if (preferences.highContrast) {
              content = ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  1.5, 0, 0, 0, -100,
                  0, 1.5, 0, 0, -100,
                  0, 0, 1.5, 0, -100,
                  0, 0, 0, 1, 0,
                ]),
                child: content,
              );
            }
            return content;
          },
          initialRoute: '/',
          routes: {
            AppRoutes.roleSelection: (context) => const SplashScreen(),
            AppRoutes.familyLinking: (context) => const FamilyLinkingScreen(),
            AppRoutes.familyPending: (context) => const FamilyPendingScreen(),
            AppRoutes.familyApproved: (context) => const FamilyApprovedScreen(),
            AppRoutes.familyDashboard: (context) => const FamilyDashboardScreen(),
            AppRoutes.missedSession: (context) =>
                const MissedSessionNotificationScreen(),
            AppRoutes.coordinatorCaseList: (context) =>
                const CoordinatorCaseListScreen(),
            AppRoutes.coordinatorCaseDetail: (context) =>
                const CoordinatorCaseDetailScreen(),
            AppRoutes.consentContextReview: (context) =>
                const ConsentContextReviewScreen(),
            AppRoutes.approvedContactAction: (context) =>
                const ApprovedContactActionScreen(),
            AppRoutes.auditOutcomeCloseCase: (context) =>
                const AuditOutcomeCloseCaseScreen(),
            AppRoutes.caseClosed: (context) => const CaseClosedScreen(),
            AppRoutes.companionHome: (context) =>
                const StudentCompanionHomeScreen(),
            AppRoutes.companionMatching: (context) =>
                const MatchingPreferencesScreen(),
            AppRoutes.companionIncomingRequests: (context) {
              final argument = ModalRoute.of(context)?.settings.arguments;
              return IncomingRequestsScreen(
                controller: argument is CompanionController ? argument : null,
              );
            },
          },
        );
      },
    );
  }
}

class _NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
