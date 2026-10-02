import 'package:flutter/material.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/family_safety/screens/family_linking_screen.dart';
import '../features/family_safety/screens/family_pending_screen.dart';
import '../features/family_safety/screens/family_approved_screen.dart';
import '../features/family_safety/screens/family_dashboard_screen.dart';
import '../features/family_safety/screens/missed_session_notification_screen.dart';
import 'theme.dart';

class CareLinkApp extends StatelessWidget {
  const CareLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink',
      debugShowCheckedModeBanner: false,
      theme: CareLinkTheme.lightTheme,
      initialRoute: '/family-linking',
      routes: {
        '/': (context) => const SplashScreen(),
        '/family-linking': (context) => const FamilyLinkingScreen(),
        '/family-pending': (context) => const FamilyPendingScreen(),
        '/family-approved': (context) => const FamilyApprovedScreen(),
        '/family-dashboard': (context) => const FamilyDashboardScreen(),
        '/missed-session': (context) => const MissedSessionNotificationScreen(),
      },
    );
  }
}
