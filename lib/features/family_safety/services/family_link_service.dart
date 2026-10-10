import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum FamilyLinkStatus { pending, accepted, declined }

enum FamilyLinkErrorCode {
  notSignedIn,
  wrongRole,
  missingProfileName,
  invalidRelationship,
  requestNotPending,
  permissionDenied,
  network,
  unknown,
}

class FamilyLinkException implements Exception {
  const FamilyLinkException(this.code, this.message);

  final FamilyLinkErrorCode code;

  /// User-facing explanation, safe to show as-is.
  final String message;

  @override
  String toString() => 'FamilyLinkException(${code.name}): $message';
}

class FamilyLinkRequest {
  const FamilyLinkRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.elderName,
    required this.relationship,
    required this.status,
    this.idNumber = '',
    this.elderId,
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

  /// The older adult's ID number as the family member typed it, so the
  /// older adult can confirm the request is really for them.
  final String idNumber;

  /// Set when the older adult accepts; null while pending or declined.
  final String? elderId;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final bool seenByRequester;

  factory FamilyLinkRequest.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    // createdAt is null until the server timestamp lands; callers treat
    // that as "just now".
    final data = doc.data() ?? {};
    final elderId = data['elderId'];
    return FamilyLinkRequest(
      id: doc.id,
      requesterId: data['requesterId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? 'A family member',
      elderName: data['elderName'] as String? ??
          data['elderDisplayName'] as String? ??
          '',
      relationship: data['relationship'] as String? ?? '',
      status: FamilyLinkStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => FamilyLinkStatus.pending,
      ),
      idNumber: data['idNumber'] as String? ?? '',
      elderId: elderId is String && elderId.isNotEmpty ? elderId : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      seenByRequester: data['requesterSeenAt'] != null,
    );
  }
}

/// Family caregivers send link requests addressed to an older adult by full
/// name and ID number. Older adults whose CareLink first name matches see
/// them on their home screen, with the ID number to confirm the request is
/// theirs; accepting creates the family link.
///
/// Field names must match the name-request rules for family_link_requests
/// in firestore.rules.
class FamilyLinkService {
  FamilyLinkService._();

  static final FamilyLinkService instance = FamilyLinkService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('family_link_requests');
  CollectionReference<Map<String, dynamic>> get _links =>
      _firestore.collection('family_links');

  static const String olderAdultRole = 'Older Adult';
  static const String caregiverRole = 'Family Caregiver';

  // Must match `data.relationship in [...]` in firestore.rules.
  static const List<String> relationships = ['Daughter', 'Son'];

  /// Mirrors familyLinkId() in firestore.rules.
  static String linkId(String elderId, String caregiverId) =>
      '${elderId.length}_$elderId$caregiverId';

  static const int maxNameLength = 100;
  static const int maxIdNumberLength = 20;

  /// Lowercase full name with runs of whitespace collapsed. Must stay in
  /// sync with familyNameKey() in firestore.rules.
  static String fullNameKey(String name) =>
      name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  /// First word of [fullNameKey]. Must stay in sync with familyFirstNameKey()
  /// in firestore.rules. Requests sent before full-name keys were added
  /// carry the same field.
  static String firstNameKey(String name) => fullNameKey(name).split(' ').first;

  Future<void> sendRequest({
    required String elderName,
    required String relationship,
    required String idNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.notSignedIn,
        'Please log in to continue.',
      );
    }
    final name = elderName.trim();
    final id = idNumber.trim();
    if (name.isEmpty || name.length > maxNameLength) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.unknown,
        'Please enter the older adult\'s full name.',
      );
    }
    if (id.isEmpty || id.length > maxIdNumberLength) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.unknown,
        'Please enter the older adult\'s ID number.',
      );
    }
    if (!relationships.contains(relationship)) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.invalidRelationship,
        'Please choose your relationship to the older adult.',
      );
    }

    final profile = await _guard(
      () => _firestore.collection('users').doc(user.uid).get(),
    );
    final data = profile.data() ?? const <String, dynamic>{};
    if (data['role'] != caregiverRole) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.wrongRole,
        'Only family caregiver accounts can send link requests.',
      );
    }
    final requesterName = data['fullName'];
    if (requesterName is! String || requesterName.trim().isEmpty) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.missingProfileName,
        'Please add your full name to your profile first.',
      );
    }

    await _guard(
      () => _requests.add({
        'requesterId': user.uid,
        // Stored exactly as in the profile; the rules compare it verbatim.
        'requesterName': requesterName,
        'elderName': name,
        'elderNameKey': fullNameKey(name),
        'elderFirstNameLower': firstNameKey(name),
        'idNumber': id,
        'relationship': relationship,
        'status': FamilyLinkStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      }),
      deniedMessage: 'We couldn\'t send your request. Please try again.',
    );
  }

  /// Pending requests relevant to the signed-in user: requests addressed to
  /// their first name when they are an older adult, otherwise the requests
  /// they sent.
  Stream<List<FamilyLinkRequest>> watchPendingRequests() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield const [];
      return;
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data() ?? {};

    final Query<Map<String, dynamic>> query;
    if (data['role'] == olderAdultRole) {
      final fullName = data['fullName'] as String? ?? '';
      if (fullName.trim().isEmpty) {
        yield const [];
        return;
      }
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

  /// Accepting binds the request to the older adult and creates the family
  /// link in the same batch, as the rules require. Declining touches only
  /// the request.
  Future<void> respond(String requestId, {required bool accept}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.notSignedIn,
        'Please log in to continue.',
      );
    }

    if (!accept) {
      await _guard(
        () => _requests.doc(requestId).update({
          'status': FamilyLinkStatus.declined.name,
          'respondedAt': FieldValue.serverTimestamp(),
        }),
        deniedMessage: 'This request has already been answered.',
      );
      return;
    }

    final profile = await _guard(
      () => _firestore.collection('users').doc(user.uid).get(),
    );
    final elderDisplayName = profile.data()?['fullName'];
    if (elderDisplayName is! String || elderDisplayName.trim().isEmpty) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.missingProfileName,
        'Please add your full name to your profile first.',
      );
    }

    final snapshot = await _guard(
      () => _requests
          .doc(requestId)
          .get(const GetOptions(source: Source.server)),
      deniedMessage: 'This request isn\'t addressed to you.',
    );
    final request = snapshot.data();
    if (request == null || request['status'] != FamilyLinkStatus.pending.name) {
      throw const FamilyLinkException(
        FamilyLinkErrorCode.requestNotPending,
        'This request has already been answered.',
      );
    }
    final caregiverId = request['requesterId'] as String;
    final acceptRequest = <String, dynamic>{
      'status': FamilyLinkStatus.accepted.name,
      'elderId': user.uid,
      'elderDisplayName': elderDisplayName,
      'respondedAt': FieldValue.serverTimestamp(),
    };

    // Links are immutable, so a second request from someone already linked
    // (e.g. a resend) is accepted without touching the existing link.
    final existingLinks = await _guard(
      () => _links
          .where('elderId', isEqualTo: user.uid)
          .where('caregiverId', isEqualTo: caregiverId)
          .limit(1)
          .get(const GetOptions(source: Source.server)),
    );
    if (existingLinks.docs.isNotEmpty) {
      await _guard(
        () => _requests.doc(requestId).update(acceptRequest),
        deniedMessage: 'We couldn\'t accept this request. Please try again.',
      );
      return;
    }

    final batch = _firestore.batch()
      ..update(_requests.doc(requestId), acceptRequest)
      ..set(_links.doc(linkId(user.uid, caregiverId)), {
        'elderId': user.uid,
        'caregiverId': caregiverId,
        'requestId': requestId,
        'elderDisplayName': elderDisplayName,
        'caregiverName': request['requesterName'],
        'relationship': request['relationship'],
        'createdAt': FieldValue.serverTimestamp(),
      });

    await _guard(
      batch.commit,
      deniedMessage: 'We couldn\'t accept this request. This family member '
          'may already be linked to you.',
    );
  }

  Future<T> _guard<T>(
    Future<T> Function() action, {
    String? deniedMessage,
  }) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      debugPrint('FamilyLinkService: ${error.code}: ${error.message}');
      throw switch (error.code) {
        'permission-denied' => FamilyLinkException(
            FamilyLinkErrorCode.permissionDenied,
            deniedMessage ?? 'You don\'t have permission to do that.',
          ),
        'unavailable' || 'network-request-failed' || 'deadline-exceeded' =>
          const FamilyLinkException(
            FamilyLinkErrorCode.network,
            'You appear to be offline. Please check your connection and try '
            'again.',
          ),
        _ => const FamilyLinkException(
            FamilyLinkErrorCode.unknown,
            'Something went wrong. Please try again.',
          ),
      };
    }
  }
}
