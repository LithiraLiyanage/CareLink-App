import 'package:flutter/material.dart';

import '../screens/welcome_screen.dart';
import 'auth_service.dart';

class SetupBackNavigation {
  static bool _isExiting = false;
  const SetupBackNavigation._();

  static Future<void> back(BuildContext context) async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    if (_isExiting) return;
    _isExiting = true;
    try {
      // Resumed setup screens can be the only route in the stack.
      await AuthService().logoutUser();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    } finally {
      _isExiting = false;
    }
  }
}
