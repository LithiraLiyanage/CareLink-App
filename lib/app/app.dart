import 'package:flutter/material.dart';

import '../features/companion/controllers/companion_controller.dart';
import '../features/companion/screens/incoming_requests_screen.dart';
import '../features/companion/screens/matching_preferences_screen.dart';
import '../features/companion/screens/student_companion_home_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/family_safety/screens/family_linking_screen.dart';
import '../features/family_safety/screens/family_pending_screen.dart';
import '../features/family_safety/screens/family_approved_screen.dart';
import '../features/family_safety/screens/family_dashboard_screen.dart';
import '../features/family_safety/screens/missed_session_notification_screen.dart';
import '../features/coordinator/coordinator_access_guard.dart';
import '../features/coordinator/coordinator_screens.dart';
import 'routes.dart';
import 'theme.dart';

class CareLinkApp extends StatelessWidget {
  const CareLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink',
      debugShowCheckedModeBanner: false,
      theme: CareLinkTheme.lightTheme,
      initialRoute: '/',
      routes: {
        AppRoutes.roleSelection: (context) => const SplashScreen(),
        AppRoutes.familyLinking: (context) => const FamilyLinkingScreen(),
        AppRoutes.familyPending: (context) => const FamilyPendingScreen(),
        AppRoutes.familyApproved: (context) => const FamilyApprovedScreen(),
        AppRoutes.familyDashboard: (context) => const FamilyDashboardScreen(),
        AppRoutes.missedSession: (context) =>
            const MissedSessionNotificationScreen(),
        // Coordinator-only routes: the screen is not built until the
        // Coordinator/Admin check passes.
        AppRoutes.coordinatorCaseList: (context) =>
            const CoordinatorAccessGuard(child: CoordinatorCaseListScreen()),
        AppRoutes.coordinatorCaseDetail: (context) =>
            const CoordinatorAccessGuard(child: CoordinatorCaseDetailScreen()),
        AppRoutes.consentContextReview: (context) =>
            const CoordinatorAccessGuard(child: ConsentContextReviewScreen()),
        AppRoutes.approvedContactAction: (context) =>
            const CoordinatorAccessGuard(child: ApprovedContactActionScreen()),
        AppRoutes.auditOutcomeCloseCase: (context) =>
            const CoordinatorAccessGuard(child: AuditOutcomeCloseCaseScreen()),
        AppRoutes.caseClosed: (context) =>
            const CoordinatorAccessGuard(child: CaseClosedScreen()),
        AppRoutes.coordinatorVerifications: (context) =>
            const CoordinatorAccessGuard(
              child: StudentVerificationReviewScreen(),
            ),
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
  }
}
