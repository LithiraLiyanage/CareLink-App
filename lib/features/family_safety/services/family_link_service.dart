import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum FamilyLinkStatus { pending, accepted, declined }

class FamilyLinkRequest {
  const FamilyLinkRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.elderName,
    required this.relationship,
    required this.status,
    this.createdAt,
    this.respondedAt,
    this.seenByRequester = false,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String elderName;
  final String relationship;
  final FamilyLinkStatus status;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final bool seenByRequester;

  factory FamilyLinkRequest.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    // createdAt is null until the server timestamp lands; callers treat
    // that as "just now".
    final data = doc.data() ?? {};
    return FamilyLinkRequest(
      id: doc.id,
      requesterId: data['requesterId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? 'A family member',
      elderName: data['elderName'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      status: FamilyLinkStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => FamilyLinkStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      seenByRequester: data['requesterSeenAt'] != null,
    );
  }
}

/// Family caregivers send link requests addressed to an older adult by name.
/// The older adult whose first name matches sees them on their dashboard.
class FamilyLinkService {
  FamilyLinkService._();

  static final FamilyLinkService instance = FamilyLinkService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('family_link_requests');

  // Must stay in sync with the first-name match in firestore.rules.
  static String firstNameKey(String name) =>
      name.trim().toLowerCase().split(' ').first;

  Future<void> sendRequest({
    required String elderName,
    required String relationship,
    required String idNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please log in before sending a request.');
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();
    final requesterName = (profile.data()?['fullName'] as String?)?.trim();

    await _requests.add({
      'requesterId': user.uid,
      'requesterName': (requesterName == null || requesterName.isEmpty)
          ? 'A family member'
          : requesterName,
      'elderName': elderName.trim(),
      'elderFirstNameLower': firstNameKey(elderName),
      'relationship': relationship,
      'idNumber': idNumber.trim(),
      'status': FamilyLinkStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });
  }

  /// Pending requests relevant to the signed-in user: requests addressed to
  /// them when they are an older adult, otherwise the requests they sent.
  Stream<List<FamilyLinkRequest>> watchPendingRequests() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield const [];
      return;
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data() ?? {};

    final Query<Map<String, dynamic>> query;
    if (data['role'] == 'Older Adult') {
      final fullName = data['fullName'] as String? ?? '';
      query = _requests.where(
        'elderFirstNameLower',
        isEqualTo: firstNameKey(fullName),
      );
    } else {
      query = _requests.where('requesterId', isEqualTo: user.uid);
    }

    yield* query.snapshots().map((snapshot) {
      final requests = snapshot.docs
          .map(FamilyLinkRequest.fromDocument)
          .where((request) => request.status == FamilyLinkStatus.pending)
          .toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
      return requests;
    });
  }

  /// Requests the signed-in family member sent that an older adult has
  /// accepted, newest approval first.
  Stream<List<FamilyLinkRequest>> watchApprovals() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const []);

    return _requests
        .where('requesterId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(FamilyLinkRequest.fromDocument)
            .where((request) => request.status == FamilyLinkStatus.accepted)
            .toList()
          ..sort((a, b) => (b.respondedAt ?? DateTime.now())
              .compareTo(a.respondedAt ?? DateTime.now())));
  }

  Future<void> markApprovalSeen(String requestId) {
    return _requests.doc(requestId).update({
      'requesterSeenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respond(String requestId, {required bool accept}) {
    return _requests.doc(requestId).update({
      'status': accept
          ? FamilyLinkStatus.accepted.name
          : FamilyLinkStatus.declined.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}
