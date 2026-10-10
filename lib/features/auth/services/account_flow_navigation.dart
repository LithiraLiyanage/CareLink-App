import 'package:flutter/material.dart';

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
      AccountDestination.welcome => const WelcomeScreen(),
    };
  }
}
