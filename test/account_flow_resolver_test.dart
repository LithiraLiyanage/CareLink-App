import 'package:carelink_app/features/auth/services/account_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AccountProgress progress({
    bool requiresEmailVerification = false,
    String? setupStage,
    String? role,
    String? phone = '0771234567',
    bool consentAccepted = false,
    bool profileCompleted = false,
    String? verificationStatus = 'notSubmitted',
  }) {
    return AccountProgress(
      requiresEmailVerification: requiresEmailVerification,
      setupStage: setupStage,
      role: role,
      phone: phone,
      consentAccepted: consentAccepted,
      profileCompleted: profileCompleted,
      verificationStatus: verificationStatus,
    );
  }

  group('AccountFlowResolver', () {
    test('supports existing trusted verified accounts', () {
      final result = AccountFlowResolver.resolve(
        progress(
          role: 'Student Companion',
          setupStage: 'complete',
          consentAccepted: true,
          profileCompleted: true,
          verificationStatus: 'verified',
        ),
      );
      expect(result.destination, AccountDestination.welcome);
    });
    test('unknown roles return to role selection', () {
      final result = AccountFlowResolver.resolve(
        progress(role: 'Unknown', setupStage: 'complete'),
      );
      expect(result.destination, AccountDestination.role);
    });

    test('completed and pending profiles still require privacy consent', () {
      for (final role in ['Older Adult', 'Student Companion']) {
        final result = AccountFlowResolver.resolve(
          progress(
            role: role,
            setupStage: 'complete',
            profileCompleted: true,
            verificationStatus: role == 'Student Companion'
                ? 'pending'
                : 'notRequired',
          ),
        );
        expect(result.destination, AccountDestination.consent);
      }
    });

    test('rejected students resume submission without being approved', () {
      final result = AccountFlowResolver.resolve(
        progress(
          role: 'Student Companion',
          setupStage: 'complete',
          consentAccepted: true,
          profileCompleted: true,
          verificationStatus: 'rejected',
        ),
      );
      expect(result.destination, AccountDestination.studentVerification);
    });

    test('requires password users to verify their email first', () {
      final result = AccountFlowResolver.resolve(
        progress(requiresEmailVerification: true, setupStage: 'role'),
      );

      expect(result.destination, AccountDestination.emailVerification);
    });

    test('routes a new account to role selection', () {
      final result = AccountFlowResolver.resolve(progress(setupStage: 'role'));

      expect(result.destination, AccountDestination.role);
    });

    test('resumes every persisted setup stage', () {
      const role = 'Older Adult';

      expect(
        AccountFlowResolver.resolve(progress(setupStage: 'profile', role: role))
            .destination,
        AccountDestination.profile,
      );
      expect(
        AccountFlowResolver.resolve(
          progress(setupStage: 'preferences', role: role),
        ).destination,
        AccountDestination.preferences,
      );
      expect(
        AccountFlowResolver.resolve(progress(setupStage: 'consent', role: role))
            .destination,
        AccountDestination.consent,
      );
    });

    test('requires student verification after consent', () {
      final result = AccountFlowResolver.resolve(
        progress(
          setupStage: 'studentVerification',
          role: 'Student Companion',
          consentAccepted: true,
        ),
      );

      expect(result.destination, AccountDestination.studentVerification);
    });

    test('routes a pending student to verification status', () {
      final result = AccountFlowResolver.resolve(
        progress(
          setupStage: 'complete',
          role: 'Student Companion',
          consentAccepted: true,
          profileCompleted: true,
          verificationStatus: 'pending',
        ),
      );

      expect(result.destination, AccountDestination.verificationStatus);
    });

    test('routes a completed non-student to welcome', () {
      final result = AccountFlowResolver.resolve(
        progress(
          setupStage: 'complete',
          role: 'Family Caregiver',
          consentAccepted: true,
          profileCompleted: true,
          verificationStatus: 'notRequired',
        ),
      );

      expect(result.destination, AccountDestination.welcome);
    });

    test('infers a safe route for legacy accounts without setupStage', () {
      final result = AccountFlowResolver.resolve(
        progress(
          role: 'Older Adult',
          phone: '',
          verificationStatus: 'notRequired',
        ),
      );

      expect(result.destination, AccountDestination.profile);
    });
  });
}
