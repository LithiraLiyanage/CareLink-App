import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
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

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
