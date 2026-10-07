import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentVerificationReviewRequest {
  const StudentVerificationReviewRequest({
    required this.userId,
    required this.fullName,
    required this.university,
    required this.studentId,
    required this.universityEmail,
    required this.status,
    required this.submittedAt,
  });

  final String userId;
  final String fullName;
  final String university;
  final String studentId;
  final String universityEmail;
  final String status;
  final DateTime? submittedAt;
}

abstract interface class StudentVerificationReviewRepository {
  Future<bool> isAuthorizedReviewer();

  Stream<List<StudentVerificationReviewRequest>> watchPendingRequests();

  Future<void> reviewRequest({
    required String userId,
    required String status,
    String? rejectionReason,
  });
}

class StudentVerificationReviewService
    implements StudentVerificationReviewRepository {
  StudentVerificationReviewService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<bool> isAuthorizedReviewer() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final claims = (await user.getIdTokenResult()).claims ?? const {};
    if (claims['coordinator'] != true && claims['admin'] != true) return false;
    final account = await _firestore.collection('users').doc(user.uid).get();
    return account.data()?['role'] != 'Student Companion';
  }

  @override
  Stream<List<StudentVerificationReviewRequest>> watchPendingRequests() async* {
    if (!await isAuthorizedReviewer()) {
      throw StateError('Coordinator or Admin access is required.');
    }
    yield* _firestore
        .collection('student_verifications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              final user = await _firestore
                  .collection('users')
                  .doc(doc.id)
                  .get();
              final submittedAt = data['submittedAt'];
              return StudentVerificationReviewRequest(
                userId: doc.id,
                fullName: user.data()?['fullName'] as String? ?? '',
                university: data['university'] as String? ?? '',
                studentId: data['studentId'] as String? ?? '',
                universityEmail: data['universityEmail'] as String? ?? '',
                status: data['status'] as String? ?? 'pending',
                submittedAt: submittedAt is Timestamp
                    ? submittedAt.toDate()
                    : null,
              );
            }),
          );
          requests.sort((a, b) {
            final aDate = a.submittedAt;
            final bDate = b.submittedAt;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });
          return List.unmodifiable(requests);
        });
  }

  @override
  Future<void> reviewRequest({
    required String userId,
    required String status,
    String? rejectionReason,
  }) async {
    if (status != 'verified' && status != 'rejected') {
      throw ArgumentError.value(
        status,
        'status',
        'A verification can only be marked verified or rejected.',
      );
    }
    if (!await isAuthorizedReviewer()) {
      throw StateError('Coordinator or Admin access is required.');
    }
    final reviewerId = _auth.currentUser!.uid;
    if (reviewerId == userId) {
      throw StateError('You cannot review your own student verification.');
    }

    final verification = _firestore
        .collection('student_verifications')
        .doc(userId);
    final user = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final verificationSnapshot = await transaction.get(verification);
      final userSnapshot = await transaction.get(user);
      if (verificationSnapshot.data()?['status'] != 'pending' ||
          userSnapshot.data()?['role'] != 'Student Companion') {
        throw StateError('This student verification is no longer pending.');
      }
      transaction.update(verification, {
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewerId,
        'rejectionReason': status == 'rejected'
            ? (rejectionReason?.trim().isEmpty ?? true)
                  ? null
                  : rejectionReason!.trim()
            : null,
      });
      transaction.update(user, {
        'verificationStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
