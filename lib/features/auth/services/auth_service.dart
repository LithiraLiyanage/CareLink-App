import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthResult {
  final User user;
  final bool needsProfileSetup;

  const GoogleAuthResult({required this.user, required this.needsProfileSetup});
}

class AuthService {
  static Future<void>? _googleInitialization;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<User> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final User? user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return a user after registration.');
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'role': null,
        'phone': '',
        'location': '',
        'language': 'English',
        'accessibilitySettings': {
          'largerText': false,
          'highContrast': false,
          'reduceMotion': false,
        },
        'profileCompleted': false,
        'verificationStatus': 'notSubmitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      try {
        await user.delete();
      } catch (_) {
        // The original Firestore failure is more useful to the caller.
      }
      rethrow;
    }

    return user;
  }

  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return a user after login.');
    }
    return user;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<GoogleAuthResult?> signInWithGoogle() async {
    late final UserCredential credential;

    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      await _initializeGoogleSignIn();

      late final GoogleSignInAccount googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } on GoogleSignInException catch (error) {
        if (error.code == GoogleSignInExceptionCode.canceled) {
          return null;
        }
        rethrow;
      }

      final googleAuthentication = googleUser.authentication;
      final googleCredential = GoogleAuthProvider.credential(
        idToken: googleAuthentication.idToken,
      );
      credential = await _auth.signInWithCredential(googleCredential);
    }

    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return a user after Google sign-in.');
    }

    try {
      final needsProfileSetup = await _syncGoogleUserProfile(user);
      return GoogleAuthResult(user: user, needsProfileSetup: needsProfileSetup);
    } catch (_) {
      if (credential.additionalUserInfo?.isNewUser == true) {
        try {
          await user.delete();
        } catch (_) {
          await _auth.signOut();
        }
      } else {
        await _auth.signOut();
      }
      await _signOutGoogleProvider();
      rethrow;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
    await _signOutGoogleProvider();
  }

  Future<void> _signOutGoogleProvider() async {
    if (!kIsWeb) {
      try {
        await _initializeGoogleSignIn();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase logout has already completed successfully.
      }
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<void> _initializeGoogleSignIn() {
    return _googleInitialization ??= GoogleSignIn.instance.initialize();
  }

  Future<bool> _syncGoogleUserProfile(User user) async {
    final userReference = _firestore.collection('users').doc(user.uid);
    final snapshot = await userReference.get();
    final displayName = user.displayName?.trim() ?? '';
    final email = user.email?.trim() ?? '';

    if (!snapshot.exists) {
      await userReference.set({
        'fullName': displayName,
        'email': email,
        'role': null,
        'phone': '',
        'location': '',
        'language': 'English',
        'accessibilitySettings': {
          'largerText': false,
          'highContrast': false,
          'reduceMotion': false,
        },
        'profileCompleted': false,
        'verificationStatus': 'notSubmitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final updates = <String, Object>{
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if ((data['fullName'] as String? ?? '').trim().isEmpty &&
        displayName.isNotEmpty) {
      updates['fullName'] = displayName;
    }
    await userReference.update(updates);

    return data['profileCompleted'] != true;
  }
}
