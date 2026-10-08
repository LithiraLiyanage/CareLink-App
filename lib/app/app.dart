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
  }
}
