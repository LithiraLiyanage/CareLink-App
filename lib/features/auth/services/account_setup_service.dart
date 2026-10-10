import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'accessibility_controller.dart';
import 'account_flow.dart';

class AccountSetupService {
  static const Set<String> validRoles = AccountFlowResolver.validRoles;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AccountSetupService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> loadProfile() async {
    final user = _requireCurrentUser();
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    return snapshot.data() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loadConsents() async {
    final user = _requireCurrentUser();
    final snapshot = await _firestore
        .collection('consents')
        .doc(user.uid)
        .get();
    return snapshot.data() ?? <String, dynamic>{};
  }

  Future<void> saveRole(String role) async {
    _validateRole(role);
    final user = _requireCurrentUser();

    await _firestore.collection('users').doc(user.uid).update({
      'role': role,
      'setupStage': 'profile',
      'profileCompleted': false,
      'verificationStatus': 'notSubmitted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveProfile({
    required String fullName,
    required String phone,
    required String location,
    required String role,
  }) async {
    _validateRole(role);
    final user = _requireCurrentUser();

    await _firestore.collection('users').doc(user.uid).update({
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'location': location.trim(),
      'role': role,
      'setupStage': 'preferences',
      'profileCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveLanguageAndAccessibility({
    required String language,
    required bool largerText,
    required bool highContrast,
    required bool reduceMotion,
  }) async {
    final user = _requireCurrentUser();

    await _firestore.collection('users').doc(user.uid).update({
      'language': language,
      'accessibilitySettings': {
        'largerText': largerText,
        'highContrast': highContrast,
        'reduceMotion': reduceMotion,
      },
      'setupStage': 'consent',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AccessibilityController.instance.apply(
      largerText: largerText,
      highContrast: highContrast,
      reduceMotion: reduceMotion,
    );
  }

  Future<void> saveConsents({
    required String role,
    required bool privacyAccepted,
    required bool familyLinkConsent,
    required bool communicationConsent,
  }) async {
    _validateRole(role);
    if (!privacyAccepted) {
      throw ArgumentError('Privacy Policy acceptance is required.');
    }

    final user = _requireCurrentUser();
    final consentReference = _firestore.collection('consents').doc(user.uid);
    final userReference = _firestore.collection('users').doc(user.uid);
    final existingProfile = await userReference.get();
    final existingStatus = existingProfile.data()?['verificationStatus'];
    final batch = _firestore.batch();

    batch.set(consentReference, {
      'userId': user.uid,
      'privacyAccepted': privacyAccepted,
      'familyLinkConsent': familyLinkConsent,
      'communicationConsent': communicationConsent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final isStudent = role == AccountFlowResolver.studentRole;
    final hasSubmission =
        isStudent &&
        ['pending', 'approved', 'verified'].contains(existingStatus);
    final userUpdates = <String, Object>{
      'role': role,
      'profileCompleted': !isStudent || hasSubmission,
      'setupStage': isStudent && !hasSubmission
          ? 'studentVerification'
          : 'complete',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isStudent) {
      userUpdates['verificationStatus'] = hasSubmission
          ? existingStatus as String
          : 'notSubmitted';
    } else {
      userUpdates['verificationStatus'] = 'notRequired';
    }
    batch.update(userReference, userUpdates);

    await batch.commit();
  }

  Future<AccountFlowDecision> loadAccountFlow() async {
    await _requireCurrentUser().reload();
    final user = _requireCurrentUser();
    final userReference = _firestore.collection('users').doc(user.uid);
    var userSnapshot = await userReference.get();

    if (!userSnapshot.exists) {
      final requiresVerification = _requiresEmailVerification(user);
      await userReference.set({
        'fullName': user.displayName?.trim() ?? '',
        'email': user.email?.trim() ?? '',
        'role': null,
        'phone': '',
        'location': '',
        'language': 'English',
        'accessibilitySettings': {
          'largerText': false,
          'highContrast': false,
          'reduceMotion': false,
        },
        'emailVerified': user.emailVerified,
        'setupStage': requiresVerification ? 'emailVerification' : 'role',
        'profileCompleted': false,
        'verificationStatus': 'notSubmitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      userSnapshot = await userReference.get();
    }

    final data = userSnapshot.data() ?? <String, dynamic>{};
    final rawSettings = data['accessibilitySettings'];
    AccessibilityController.instance.applyFromMap(
      rawSettings is Map<String, dynamic>
          ? rawSettings
          : rawSettings is Map
          ? Map<String, dynamic>.from(rawSettings)
          : null,
    );

    final consentSnapshot = await _firestore
        .collection('consents')
        .doc(user.uid)
        .get();
    final consentAccepted = consentSnapshot.data()?['privacyAccepted'] == true;

    return AccountFlowResolver.resolve(
      AccountProgress(
        requiresEmailVerification: _requiresEmailVerification(user),
        setupStage: data['setupStage'] as String?,
        role: data['role'] as String?,
        phone: data['phone'] as String?,
        consentAccepted: consentAccepted,
        profileCompleted: data['profileCompleted'] == true,
        verificationStatus: data['verificationStatus'] as String?,
      ),
    );
  }

  Future<void> recordVerifiedEmail() async {
    final user = _requireCurrentUser();
    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      throw StateError('Please verify your email before continuing.');
    }
    await refreshedUser.getIdToken(true);

    final userReference = _firestore.collection('users').doc(user.uid);
    final snapshot = await userReference.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final updates = <String, Object>{
      'emailVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (data['setupStage'] == 'emailVerification') {
      updates['setupStage'] = 'role';
    }
    await userReference.set(updates, SetOptions(merge: true));
  }

  bool _requiresEmailVerification(User user) {
    final usesPassword = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    return usesPassword && !user.emailVerified;
  }

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationRequiredException();
    }
    return user;
  }

  void _validateRole(String role) {
    if (!validRoles.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Unsupported CareLink role');
    }
  }
}

class AuthenticationRequiredException implements Exception {
  const AuthenticationRequiredException();

  @override
  String toString() => 'You must be signed in to complete account setup.';
}
