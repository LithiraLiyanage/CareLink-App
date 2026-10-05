import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'student_verification_validator.dart';

class StudentVerificationService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  StudentVerificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  Future<void> submitVerification({
    required String selectedRole,
    required String university,
    required String studentId,
    required String universityEmail,
    required String documentName,
    required Uint8List documentBytes,
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
    if (university.trim().isEmpty || studentId.trim().isEmpty) {
      throw ArgumentError('University and Student ID are required.');
    }
    if (!StudentVerificationValidator.isValidEmail(universityEmail)) {
      throw ArgumentError.value(
        universityEmail,
        'universityEmail',
        'A valid university email is required.',
      );
    }
    if (!StudentVerificationValidator.isAllowedDocument(documentName)) {
      throw ArgumentError.value(
        documentName,
        'documentName',
        'Only JPG, JPEG, PNG, and PDF documents are supported.',
      );
    }
    if (!StudentVerificationValidator.isWithinSizeLimit(documentBytes.length)) {
      throw ArgumentError.value(
        documentBytes.length,
        'documentBytes',
        'The document must be between 1 byte and 10 MB.',
      );
    }

    final userReference = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userReference.get();
    if (userSnapshot.data()?['role'] != 'Student Companion') {
      throw StateError(
        'Your account role must be Student Companion to submit verification.',
      );
    }

    final verificationReference = _firestore
        .collection('student_verifications')
        .doc(user.uid);
    final existingVerification = await verificationReference.get();
    final previousDocumentPath =
        existingVerification.data()?['documentPath'] as String?;

    final safeFileName = documentName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    final storageReference = _storage.ref().child(
      'student_verifications/${user.uid}/'
      '${DateTime.now().millisecondsSinceEpoch}_$safeFileName',
    );

    await storageReference.putData(
      documentBytes,
      SettableMetadata(
        contentType: StudentVerificationValidator.contentTypeFor(documentName),
      ),
    );

    try {
      final downloadUrl = await storageReference.getDownloadURL();
      final batch = _firestore.batch();

      batch.set(verificationReference, {
        'userId': user.uid,
        'role': selectedRole,
        'university': university.trim(),
        'studentId': studentId.trim(),
        'universityEmail': universityEmail.trim(),
        'documentName': documentName,
        'documentUrl': downloadUrl,
        'documentPath': storageReference.fullPath,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.update(userReference, {
        'verificationStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (previousDocumentPath != null &&
          previousDocumentPath != storageReference.fullPath &&
          previousDocumentPath.startsWith(
            'student_verifications/${user.uid}/',
          )) {
        try {
          await _storage.ref(previousDocumentPath).delete();
        } catch (_) {
          // The new submission is valid even if old-file cleanup is denied.
        }
      }
    } catch (_) {
      await storageReference.delete().catchError((_) {});
      rethrow;
    }
  }
}
