import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSetupService {
  static const Set<String> validRoles = {
    'Older Adult',
    'Student Companion',
    'Family Caregiver',
  };

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AccountSetupService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveRole(String role) async {
    _validateRole(role);
    final user = _requireCurrentUser();

    await _firestore.collection('users').doc(user.uid).update({
      'role': role,
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    final batch = _firestore.batch();

    batch.set(consentReference, {
      'userId': user.uid,
      'privacyAccepted': privacyAccepted,
      'familyLinkConsent': familyLinkConsent,
      'communicationConsent': communicationConsent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final userUpdates = <String, Object>{
      'role': role,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (role != 'Student Companion') {
      userUpdates['verificationStatus'] = 'notRequired';
    }
    batch.update(userReference, userUpdates);

    await batch.commit();
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
