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

  static const String familyLinking = '/family-linking';
  static const String familyPending = '/family-pending';
  static const String familyApproved = '/family-approved';
  static const String familyDashboard = '/family-dashboard';
  static const String missedSession = '/missed-session';

  // Coordinator
  static const String coordinatorCaseList = '/coordinator-case';
  static const String coordinatorCaseDetail = '/coordinator-case-details';
  static const String consentContextReview = '/consent-context';
  static const String approvedContactAction = '/approved-contact';
  static const String auditOutcomeCloseCase = '/case-outcome';
  static const String caseClosed = '/case-closed';
}
  static const String familyHome = '/family-home';
  static const String safetyDashboard = '/safety-dashboard';
}
