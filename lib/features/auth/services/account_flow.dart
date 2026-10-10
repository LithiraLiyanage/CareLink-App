enum AccountDestination {
  emailVerification,
  role,
  profile,
  preferences,
  consent,
  studentVerification,
  verificationStatus,
  welcome,
}

class AccountProgress {
  final bool requiresEmailVerification;
  final String? setupStage;
  final String? role;
  final String? phone;
  final bool consentAccepted;
  final bool profileCompleted;
  final String? verificationStatus;

  const AccountProgress({
    required this.requiresEmailVerification,
    required this.setupStage,
    required this.role,
    required this.phone,
    required this.consentAccepted,
    required this.profileCompleted,
    required this.verificationStatus,
  });
}

class AccountFlowDecision {
  final AccountDestination destination;
  final String? role;

  const AccountFlowDecision({required this.destination, this.role});
}

class AccountFlowResolver {
  static const String studentRole = 'Student Companion';
  static const Set<String> validRoles = {
    'Older Adult',
    studentRole,
    'Family Caregiver',
  };

  const AccountFlowResolver._();

  static AccountFlowDecision resolve(AccountProgress progress) {
    if (progress.requiresEmailVerification) {
      return const AccountFlowDecision(
        destination: AccountDestination.emailVerification,
      );
    }

    final role = progress.role;
    final stage = progress.setupStage;

    if (!validRoles.contains(role) || stage == 'role') {
      return const AccountFlowDecision(destination: AccountDestination.role);
    }

    if (stage == 'profile') {
      return AccountFlowDecision(
        destination: AccountDestination.profile,
        role: role,
      );
    }
    if (stage == 'preferences') {
      return AccountFlowDecision(
        destination: AccountDestination.preferences,
        role: role,
      );
    }
    if (stage == 'consent') {
      return AccountFlowDecision(
        destination: AccountDestination.consent,
        role: role,
      );
    }

    if (!progress.consentAccepted &&
        (stage == 'studentVerification' ||
            stage == 'complete' ||
            progress.profileCompleted)) {
      return AccountFlowDecision(
        destination: AccountDestination.consent,
        role: role,
      );
    }

    if (role == studentRole) {
      if (progress.verificationStatus == 'pending' ||
          progress.verificationStatus == 'approved' ||
          progress.verificationStatus == 'verified') {
        return AccountFlowDecision(
          destination: progress.verificationStatus == 'pending'
              ? AccountDestination.verificationStatus
              : AccountDestination.welcome,
          role: role,
        );
      }
      if (stage == 'studentVerification' ||
          stage == 'complete' ||
          progress.consentAccepted) {
        return AccountFlowDecision(
          destination: AccountDestination.studentVerification,
          role: role,
        );
      }
    }

    if (progress.profileCompleted && progress.consentAccepted) {
      return AccountFlowDecision(
        destination: AccountDestination.welcome,
        role: role,
      );
    }

    if (stage == 'complete') {
      return AccountFlowDecision(
        destination: AccountDestination.consent,
        role: role,
      );
    }

    // Backward-compatible inference for accounts created before setupStage.
    if ((progress.phone ?? '').trim().isEmpty) {
      return AccountFlowDecision(
        destination: AccountDestination.profile,
        role: role,
      );
    }
    if (!progress.consentAccepted) {
      return AccountFlowDecision(
        destination: AccountDestination.preferences,
        role: role,
      );
    }
    if (role == studentRole) {
      return AccountFlowDecision(
        destination: AccountDestination.studentVerification,
        role: role,
      );
    }
    return AccountFlowDecision(
      destination: AccountDestination.welcome,
      role: role,
    );
  }
}
