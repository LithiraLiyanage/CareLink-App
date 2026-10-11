import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'student_verification_validator.dart';

/// Saves Student Companion verification requests in Firebase.
/// This is a service, not a Flutter screen.
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
    String? documentName,
    Uint8List? documentBytes,
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
      throw ArgumentError('Enter a valid university email address.');
    }
    // Require a complete, valid pair only when optional proof is provided.
    final hasName = documentName != null && documentName.trim().isNotEmpty;
    final hasBytes = documentBytes != null && documentBytes.isNotEmpty;
    if (hasName != hasBytes) {
      throw ArgumentError('Attach both document name and contents, or neither.');
    }
    if (hasBytes) {
      if (!StudentVerificationValidator.isAllowedDocument(documentName!)) {
        throw ArgumentError('Only JPG, JPEG, PNG and PDF documents are supported.');
      }
      if (!StudentVerificationValidator.isWithinSizeLimit(documentBytes.length)) {
        throw ArgumentError('The document must be between 1 byte and 10 MB.');
      }
    }

    final userReference = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userReference.get();
    if (userSnapshot.data()?['role'] != 'Student Companion') {
      throw StateError(
        'Your account role must be Student Companion to submit verification.',
      );
    }

    final verificationReference =
        _firestore.collection('student_verifications').doc(user.uid);
    final existingVerification = await verificationReference.get();
    if (['approved', 'verified'].contains(existingVerification.data()?['status'])) {
      throw StateError('Your student verification has already been approved.');
    }
    final previousDocumentPath =
        existingVerification.data()?['documentPath'] as String?;

    Reference? uploadedReference;
    try {
      String? newDocumentUrl;
      String? newDocumentPath;
      if (hasBytes) {
        final safeFileName = documentName!.replaceAll(
          RegExp(r'[^A-Za-z0-9._-]'), '_');
        uploadedReference = _storage.ref().child(
          'student_verifications/${user.uid}/'
          '${_firestore.collection('student_verifications').doc().id}_$safeFileName',
        );
        await uploadedReference.putData(
          documentBytes,
          SettableMetadata(
            contentType: StudentVerificationValidator.contentTypeFor(documentName),
          ),
        );
        newDocumentUrl = await uploadedReference.getDownloadURL();
        newDocumentPath = uploadedReference.fullPath;
      }

      final batch = _firestore.batch();
      batch.set(verificationReference, {
        'userId': user.uid,
        'role': selectedRole,
        'university': university.trim(),
        'studentId': studentId.trim(),
        'universityEmail': universityEmail.trim(),
        'documentName': hasBytes ? documentName : null,
        'documentUrl': newDocumentUrl,
        'documentPath': newDocumentPath,
        'status': 'pending',
        'reviewedAt': null,
        'reviewedBy': null,
        'rejectionReason': null,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.update(userReference, {
        'verificationStatus': 'pending',
        'profileCompleted': true,
        'setupStage': 'complete',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      if (previousDocumentPath != null &&
          previousDocumentPath != newDocumentPath &&
          previousDocumentPath.startsWith('student_verifications/${user.uid}/')) {
        try {
          await _storage.ref(previousDocumentPath).delete();
        } catch (_) {
          // Best-effort cleanup; Firestore submission has already succeeded.
        }
      }
    } catch (_) {
      if (uploadedReference != null) {
        try {
          await uploadedReference.delete();
        } catch (_) {
          // Preserve original upload/submission error.
        }
      }
      rethrow;
    }
  }
}
