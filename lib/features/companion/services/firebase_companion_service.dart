import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/companion_connection.dart';
import '../models/companion_profile.dart';
import '../models/conversation_idea.dart';
import '../models/match_preferences.dart';
import '../models/match_recommendation.dart';
import '../models/match_request.dart';
import 'companion_matching.dart';
import 'companion_service.dart';
import 'mock_companion_service.dart';

/// Firestore foundation only. Screens still use the mock service until the
/// security rules and trusted student-profile projection have been reviewed.
class FirebaseCompanionService implements CompanionService {
  FirebaseCompanionService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final MockCompanionService _localIdeas = MockCompanionService();

  static const _elderRole = 'Older Adult';
  static const _studentRole = 'Student Companion';
  static const _verified = 'verified';

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Please sign in before using companion matching.');
    }
    return uid;
  }

  @override
  String get currentElderId => _uid;

  @override
  bool get supportsSimulatedResponses => false;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);
  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _db.collection('companion_profiles').doc(uid);
  DocumentReference<Map<String, dynamic>> _request(String id) =>
      _db.collection('match_requests').doc(id);
  DocumentReference<Map<String, dynamic>> _requestPair(String id) =>
      _db.collection('match_request_pairs').doc(id);
  DocumentReference<Map<String, dynamic>> _connection(String id) =>
      _db.collection('connections').doc(id);

  // A deterministic pair key prevents concurrent duplicate open requests.
  String _pairId(String elderUid, String studentUid) =>
      '${elderUid.length}_$elderUid$studentUid';

  Future<void> _requireElder(String uid) async {
    final user = await _user(uid).get();
    if (user.data()?['role'] != _elderRole) {
      throw StateError('Only an Older Adult can use companion matching.');
    }
  }

  bool _eligible(Map<String, dynamic>? data) =>
      data != null &&
      data['role'] == _studentRole &&
      data['verificationStatus'] == _verified &&
      data['active'] == true &&
      (data['name'] as String?)?.trim().isNotEmpty == true;

  Future<bool> _isVerifiedStudentProfile(
    String uid,
    Map<String, dynamic>? profileData,
  ) async {
    if (!_eligible(profileData)) return false;
    final snapshots = await Future.wait([
      _user(uid).get(),
      _db.collection('student_verifications').doc(uid).get(),
    ]);
    return snapshots[0].data()?['role'] == _studentRole &&
        snapshots[0].data()?['verificationStatus'] == _verified &&
        snapshots[1].data()?['status'] == _verified;
  }

  CompanionProfile _candidate(String uid, Map<String, dynamic> data) {
    final availability = data['availability'];
    final slots = availability is List
        ? availability.whereType<String>().toList()
        : data['availabilitySlots'];
    return CompanionProfile.fromMap({
      ...data,
      'id': uid,
      'userId': uid,
      'verified': true,
      'availability': availability is String
          ? availability
          : slots is List
          ? slots.whereType<String>().join(', ')
          : '',
      'availabilitySlots': slots is List ? slots : const <String>[],
      'profileImagePath': '',
    });
  }

  Map<String, dynamic> _dated(
    Map<String, dynamic> source,
    Iterable<String> keys,
  ) {
    final result = Map<String, dynamic>.of(source);
    for (final key in keys) {
      final value = result[key];
      if (value is Timestamp) result[key] = value.toDate();
    }
    return result;
  }

  MatchRequest _requestModel(String id, Map<String, dynamic> data) =>
      MatchRequest.fromMap({
        ..._dated(data, ['createdAt', 'respondedAt']),
        'id': id,
        'createdAt': data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      });

  CompanionConnection _connectionModel(String id, Map<String, dynamic> data) =>
      CompanionConnection.fromMap({
        ..._dated(data, ['startedAt', 'pausedAt', 'endedAt']),
        'id': id,
        'startedAt': data['startedAt'] is Timestamp
            ? (data['startedAt'] as Timestamp).toDate()
            : DateTime.now(),
      });

  @override
  Future<void> saveMatchPreferences(MatchPreferences preferences) async {
    final uid = _uid;
    await _requireElder(uid);
    await _db.collection('matching_preferences').doc(uid).set({
      ...preferences.toMap(),
      'elderId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<MatchRecommendation>> getRecommendations(
    MatchPreferences preferences,
  ) async {
    final uid = _uid;
    await _requireElder(uid);
    final candidates = await _db
        .collection('companion_profiles')
        .where('role', isEqualTo: _studentRole)
        .where('verificationStatus', isEqualTo: _verified)
        .where('active', isEqualTo: true)
        .get();
    final eligibleProfiles = <CompanionProfile>[];
    for (final doc in candidates.docs) {
      if (doc.id != uid &&
          await _isVerifiedStudentProfile(doc.id, doc.data())) {
        eligibleProfiles.add(_candidate(doc.id, doc.data()));
      }
    }
    return rankCompanions(eligibleProfiles, preferences);
  }

  @override
  Future<CompanionProfile?> getCompanionById(String companionId) async {
    final uid = _uid;
    await _requireElder(uid);
    final doc = await _profile(companionId).get();
    return doc.id != uid && await _isVerifiedStudentProfile(doc.id, doc.data())
        ? _candidate(doc.id, doc.data()!)
        : null;
  }

  @override
  Future<MatchRequest> sendMatchRequest({
    required String elderId,
    required String companionId,
  }) async {
    // The legacy elderId argument is deliberately ignored: never trust a
    // caller-supplied identity, including the controller's current mock ID.
    final uid = _uid;
    if (uid == companionId) throw StateError('You cannot request yourself.');
    final pair = _pairId(uid, companionId);
    final userRef = _user(uid);
    final profileRef = _profile(companionId);
    final pairRef = _requestPair(pair);
    final requestRef = _db.collection('match_requests').doc();
    await _db.runTransaction((tx) async {
      final user = await tx.get(userRef);
      final student = await tx.get(profileRef);
      final studentUser = await tx.get(_user(companionId));
      final verification = await tx.get(
        _db.collection('student_verifications').doc(companionId),
      );
      final pairState = await tx.get(pairRef);
      final previousId = pairState.data()?['currentRequestId'] as String?;
      final previous = previousId == null
          ? null
          : await tx.get(_request(previousId));
      final connectionId = pairState.data()?['currentConnectionId'] as String?;
      final connection = connectionId == null
          ? null
          : await tx.get(_connection(connectionId));
      if (user.data()?['role'] != _elderRole) {
        throw StateError('Only an Older Adult can send match requests.');
      }
      if (!_eligible(student.data()) ||
          studentUser.data()?['role'] != _studentRole ||
          studentUser.data()?['verificationStatus'] != _verified ||
          verification.data()?['status'] != _verified) {
        throw StateError('This student is not available for matching.');
      }
      if (previous?.data()?['status'] == 'pending' ||
          (previous?.data()?['status'] == 'accepted' &&
              connection?.data()?['status'] != 'ended')) {
        throw StateError('A request is already open for this companion.');
      }
      if (connection != null &&
          ['active', 'paused'].contains(connection.data()?['status'])) {
        throw StateError('You are already connected to this companion.');
      }
      tx.set(requestRef, {
        'elderId': uid,
        'companionId': companionId,
        'pairId': pair,
        'status': MatchRequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      });
      tx.set(pairRef, {
        'elderId': uid,
        'companionId': companionId,
        'currentRequestId': requestRef.id,
        'currentConnectionId': connectionId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    final saved = await requestRef.get();
    return _requestModel(saved.id, saved.data()!);
  }

  @override
  Future<MatchRequest> updateMatchRequestStatus({
    required String requestId,
    required MatchRequestStatus status,
  }) async {
    if (status == MatchRequestStatus.pending) {
      throw StateError('A response must accept, decline, or cancel.');
    }
    final uid = _uid;
    final requestRef = _request(requestId);
    final newConnectionRef = _db.collection('connections').doc();
    await _db.runTransaction((tx) async {
      final request = await tx.get(requestRef);
      final data = request.data();
      if (data == null || data['status'] != 'pending') {
        throw StateError('This request is no longer pending.');
      }
      final elderUid = data['elderId'] as String;
      final studentUid = data['companionId'] as String;
      final pairId = _pairId(elderUid, studentUid);
      final pairState = await tx.get(_requestPair(pairId));
      if (data['pairId'] != pairId ||
          pairState.data()?['currentRequestId'] != requestId) {
        throw StateError('Invalid match request.');
      }
      if (status == MatchRequestStatus.cancelled
          ? uid != elderUid
          : uid != studentUid) {
        throw StateError('You cannot respond to this request.');
      }
      if (status == MatchRequestStatus.accepted) {
        final student = await tx.get(_profile(studentUid));
        final studentUser = await tx.get(_user(studentUid));
        final verification = await tx.get(
          _db.collection('student_verifications').doc(studentUid),
        );
        final existingId = pairState.data()?['currentConnectionId'] as String?;
        final existing = existingId == null
            ? null
            : await tx.get(_connection(existingId));
        if (!_eligible(student.data()) ||
            studentUser.data()?['role'] != _studentRole ||
            studentUser.data()?['verificationStatus'] != _verified ||
            verification.data()?['status'] != _verified) {
          throw StateError('The student is no longer verified or active.');
        }
        if (existing != null && existing.data()?['status'] != 'ended') {
          throw StateError('A connection already exists.');
        }
        tx.set(newConnectionRef, {
          'elderId': elderUid,
          'companionId': studentUid,
          'matchRequestId': requestId,
          'pairId': pairId,
          'status': ConnectionStatus.active.name,
          'startedAt': FieldValue.serverTimestamp(),
          'pausedAt': null,
          'endedAt': null,
        });
        tx.update(_requestPair(pairId), {
          'currentConnectionId': newConnectionRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.update(requestRef, {
        'status': status.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
    final saved = await requestRef.get();
    return _requestModel(saved.id, saved.data()!);
  }

  @override
  Stream<MatchRequest?> watchMatchRequest(String requestId) async* {
    final uid = _uid;
    final first = await _request(requestId).get();
    final data = first.data();
    if (data != null && data['elderId'] != uid && data['companionId'] != uid) {
      throw StateError('You cannot view this request.');
    }
    yield* _request(requestId).snapshots().map((doc) {
      final value = doc.data();
      return value == null ? null : _requestModel(doc.id, value);
    });
  }

  @override
  Future<CompanionConnection> createConnectionFromAcceptedRequest(
    MatchRequest request,
  ) async {
    // Acceptance creates the connection atomically. This method retrieves it
    // for the existing controller contract; it never creates from pending.
    final uid = _uid;
    if (request.status != MatchRequestStatus.accepted ||
        (uid != request.elderId && uid != request.companionId)) {
      throw StateError('Only an accepted request can have a connection.');
    }
    final pair = await _requestPair(
      _pairId(request.elderId, request.companionId),
    ).get();
    final connectionId = pair.data()?['currentConnectionId'] as String?;
    if (connectionId == null) {
      throw StateError('The accepted connection is not available yet.');
    }
    final saved = await _connection(connectionId).get();
    final data = saved.data();
    if (data == null ||
        data['matchRequestId'] != request.id ||
        data['elderId'] != request.elderId ||
        data['companionId'] != request.companionId) {
      throw StateError('The accepted connection is not available yet.');
    }
    return _connectionModel(saved.id, data);
  }

  CompanionConnection? _currentConnection(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final current = docs
        .where((doc) => ['active', 'paused'].contains(doc.data()['status']))
        .toList();
    current.sort((a, b) {
      final aDate = a.data()['startedAt'];
      final bDate = b.data()['startedAt'];
      if (aDate is Timestamp && bDate is Timestamp) {
        return bDate.compareTo(aDate);
      }
      return 0;
    });
    return current.isEmpty
        ? null
        : _connectionModel(current.first.id, current.first.data());
  }

  @override
  Future<CompanionConnection?> getCurrentConnection(String elderId) async {
    final uid = _uid;
    await _requireElder(uid);
    final snapshot = await _db
        .collection('connections')
        .where('elderId', isEqualTo: uid)
        .get();
    return _currentConnection(snapshot.docs);
  }

  @override
  Stream<CompanionConnection?> watchCurrentConnection(String elderId) async* {
    final uid = _uid;
    await _requireElder(uid);
    yield* _db
        .collection('connections')
        .where('elderId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => _currentConnection(snapshot.docs));
  }

  Future<CompanionConnection> _changeConnection(
    CompanionConnection connection,
    ConnectionStatus next,
  ) async {
    final uid = _uid;
    final ref = _connection(connection.id);
    await _db.runTransaction((tx) async {
      final saved = await tx.get(ref);
      final data = saved.data();
      if (data == null ||
          data['elderId'] != uid ||
          data['companionId'] != connection.companionId) {
        throw StateError('This connection is not available to you.');
      }
      final current = data['status'];
      final valid = next == ConnectionStatus.paused
          ? current == 'active'
          : next == ConnectionStatus.active
          ? current == 'paused'
          : current == 'active' || current == 'paused';
      if (!valid) throw StateError('This connection cannot be changed.');
      tx.update(ref, {
        'status': next.name,
        if (next == ConnectionStatus.paused)
          'pausedAt': FieldValue.serverTimestamp(),
        if (next == ConnectionStatus.active) 'pausedAt': null,
        if (next == ConnectionStatus.ended)
          'endedAt': FieldValue.serverTimestamp(),
      });
    });
    final saved = await ref.get();
    return _connectionModel(saved.id, saved.data()!);
  }

  @override
  Future<CompanionConnection> pauseConnection(CompanionConnection connection) =>
      _changeConnection(connection, ConnectionStatus.paused);

  @override
  Future<CompanionConnection> resumeConnection(
    CompanionConnection connection,
  ) => _changeConnection(connection, ConnectionStatus.active);

  @override
  Future<CompanionConnection> endConnection(CompanionConnection connection) =>
      _changeConnection(connection, ConnectionStatus.ended);

  @override
  Future<List<ConversationIdea>> getConversationIdeas(
    List<String> elderInterests,
  ) => _localIdeas.getConversationIdeas(elderInterests);
}
