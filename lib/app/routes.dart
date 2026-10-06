class AppRoutes {
  AppRoutes._();

  // =========================
  // AUTH & TRUST
  // =========================

  static const String roleSelection = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String language = '/language';
  static const String accessibility = '/accessibility';
  static const String consent = '/consent';
  static const String studentVerification = '/student-verification';

  // =========================
  // ELDER
  // =========================

  static const String elderHome = '/elder-home';
  static const String elderCheckIn = '/elder-check-in';
  static const String elderSchedule = '/elder-schedule';
  static const String memoryLane = '/memory-lane';

  // =========================
  // COMPANION
  // =========================

  static const String companionHome = '/companion-home';
  static const String companionMatching = '/companion-matching';
  static const String companionIncomingRequests =
      '/companion-incoming-requests';

  // =========================
  // FAMILY & SAFETY
  // =========================

  static const String familyHome = '/family-home';
  static const String safetyDashboard = '/safety-dashboard';
}
