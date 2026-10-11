import 'package:firebase_auth/firebase_auth.dart';

import 'student_verification_review_service.dart';

/// Whether the signed-in user is a Coordinator/Admin, for routing after login.
///
/// Forces an ID token refresh first so a coordinator claim set by
/// `tools/set_coordinator_claim.cjs` after the user last signed in is seen
/// without signing out and back in. Coordinator authority comes only from
/// custom claims, never from the client-writable Firestore `role` field.
Future<bool> isCoordinatorSession({FirebaseAuth? auth}) async {
  final firebaseAuth = auth ?? FirebaseAuth.instance;
  final user = firebaseAuth.currentUser;
  if (user == null) return false;
  await user.getIdToken(true);
  return StudentVerificationReviewService(auth: firebaseAuth)
      .isAuthorizedReviewer();
}
