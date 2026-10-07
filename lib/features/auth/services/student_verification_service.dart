import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_verification_validator.dart';

abstract interface class StudentVerificationRepository {
  Future<void> submitVerification({
    required String selectedRole,
    required String university,
    required String studentId,
    required String universityEmail,
  });

  Stream<String?> watchVerificationStatus();
}

class StudentVerificationService implements StudentVerificationRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StudentVerificationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitVerification({
    required String selectedRole,
    required String university,
    required String studentId,
    required String universityEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to submit verification.');
    }
    if (selectedRole != 'Student Companion') {
      throw ArgumentError.value(
        selectedRole,
        'selectedRole',
        'Only Student Companions can submit student verification.',
      );
    }
    if (university.trim().isEmpty) {
      throw ArgumentError('University or Institute is required.');
    }
    if (!StudentVerificationValidator.isValidStudentId(studentId)) {
      throw ArgumentError('Student ID is required.');
    }
    if (!StudentVerificationValidator.isValidEmail(universityEmail)) {
      throw ArgumentError.value(
        universityEmail,
        'universityEmail',
        'A valid university email is required.',
      );
    }

    final userReference = _firestore.collection('users').doc(user.uid);
    final verificationReference = _firestore
        .collection('student_verifications')
        .doc(user.uid);
    final snapshots = await Future.wait([
      userReference.get(),
      verificationReference.get(),
    ]);
    final userData = snapshots[0].data();
    final verificationData = snapshots[1].data();
    if (userData?['role'] != 'Student Companion') {
      throw StateError(
        'Your account role must be Student Companion to submit verification.',
      );
    }
    if (userData?['verificationStatus'] == 'verified' ||
        verificationData?['status'] == 'verified') {
      throw StateError('Your student verification is already verified.');
    }

    final batch = _firestore.batch();
    batch.set(verificationReference, {
      'userId': user.uid,
      'university': university.trim(),
      'studentId': studentId.trim(),
      'universityEmail': universityEmail.trim(),
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': null,
      'rejectionReason': null,
    });
    batch.update(userReference, {
      'verificationStatus': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Stream<String?> watchVerificationStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to view verification status.');
    }
    return _firestore
        .collection('student_verifications')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['status'] as String?);
  }
}
