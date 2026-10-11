import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../companion/screens/student_companion_home_screen.dart';
import '../../coordinator/services/coordinator_session.dart';
import '../../elder/screens/elder_home_screen.dart';
import '../../family_safety/screens/family_linking_screen.dart';
import '../screens/choose_role_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/language_accessibility_screen.dart';
import '../screens/privacy_consent_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/student_verification_screen.dart';
import '../screens/verification_status_screen.dart';
import '../screens/welcome_screen.dart';
import 'account_flow.dart';
import 'account_setup_service.dart';

class AccountFlowNavigation {
  const AccountFlowNavigation._();

  static Future<void> replaceWithNext(
    BuildContext context, {
    bool clearStack = false,
  }) => _navigate(context, clearStack: clearStack);

  static Future<void> pushNext(BuildContext context) =>
      _navigate(context, replaceCurrent: false);

  static Future<void> _navigate(
    BuildContext context, {
    bool clearStack = false,
    bool replaceCurrent = true,
  }) async {
    // Coordinators/Admins have no user setup flow; send them straight to the
    // case list. Checked first because a coordinator may have no users doc.
    if (await isCoordinatorSession()) {
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.coordinatorCaseList,
        (route) => false,
      );
      return;
    }

    final decision = await AccountSetupService().loadAccountFlow();
    if (!context.mounted) return;

    final route = MaterialPageRoute<void>(
      builder: (context) => _screenFor(decision),
    );
    if (clearStack) {
      Navigator.pushAndRemoveUntil(context, route, (route) => false);
    } else if (replaceCurrent) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }

  static Widget _screenFor(AccountFlowDecision decision) {
    final role = decision.role;
    return switch (decision.destination) {
      AccountDestination.emailVerification => EmailVerificationScreen(
        onVerified: (context) => replaceWithNext(context, clearStack: true),
      ),
      AccountDestination.role => const ChooseRoleScreen(),
      AccountDestination.profile => ProfileSetupScreen(selectedRole: role!),
      AccountDestination.preferences => LanguageAccessibilityScreen(
        selectedRole: role!,
      ),
      AccountDestination.consent => PrivacyConsentScreen(selectedRole: role!),
      AccountDestination.studentVerification => StudentVerificationScreen(
        selectedRole: role!,
      ),
      AccountDestination.verificationStatus => const VerificationStatusScreen(),
      AccountDestination.welcome => _homeFor(role),
    };
  }

  /// Home screen for a fully set-up account.
  static Widget _homeFor(String? role) => switch (role) {
    'Older Adult' => const ElderHomeScreen(),
    'Family Caregiver' => const FamilyLinkingScreen(),
    'Student Companion' => const StudentCompanionHomeScreen(),
    _ => const WelcomeScreen(),
  };
}
