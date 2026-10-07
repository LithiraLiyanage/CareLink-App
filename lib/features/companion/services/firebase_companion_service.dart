import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/companion_connection.dart';
import '../models/companion_incoming_request.dart';
import '../models/companion_profile.dart';
import '../models/conversation_idea.dart';
import '../models/match_preferences.dart';
import '../models/match_recommendation.dart';
import '../models/match_request.dart';
import 'companion_matching.dart';
import 'companion_service.dart';
import 'mock_companion_service.dart';

/// Firestore-backed matching and connection lifecycle for authenticated users.
class FirebaseCompanionService implements CompanionService {
  FirebaseCompanionService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _injectedAuth = auth,
      _injectedFirestore = firestore;

  final FirebaseAuth? _injectedAuth;
  final FirebaseFirestore? _injectedFirestore;
  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _injectedFirestore ?? FirebaseFirestore.instance;
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

  Future<T> _traceFirestoreStep<T>(
    String step,
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      if (kDebugMode) debugPrint('$step succeeded');
      return result;
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('$step failed: ${error.code}: ${error.message}');
        debugPrintStack(stackTrace: stackTrace, label: '$step stack trace');
      }
      rethrow;
    }
  }

  void _traceTransactionWrite(String step) {
    if (kDebugMode) debugPrint('$step queued in Accept transaction');
  }

  // A deterministic pair key prevents concurrent duplicate open requests.
  String _pairId(String elderUid, String studentUid) =>
      '${elderUid.length}_$elderUid$studentUid';

  Future<void> _requireRole(String uid, String role) async {
    final user = await _traceFirestoreStep(
      'STEP 1 current user read',
      () => _user(uid).get(),
    );
    if (kDebugMode) {
      debugPrint(
        'Companion authenticated UID=$uid, '
        'Firestore role=${user.data()?['role']}',
      );
    }
    if (user.data()?['role'] != role) {
      throw StateError('Only a $role account can use this companion action.');
    }
    if (role == _studentRole &&
        user.data()?['verificationStatus'] != _verified) {
      throw StateError('Student verification must be verified to participate.');
    }
  }

  bool _eligible(Map<String, dynamic>? data) =>
      data != null &&
      data['active'] == true &&
      data['verificationStatus'] == _verified &&
      (data['fullName'] as String?)?.trim().isNotEmpty == true;

  bool _isEligibleStudentProfile(
    String uid,
    Map<String, dynamic>? profileData,
  ) => _eligible(profileData) && profileData?['userId'] == uid;

  CompanionProfile _candidate(String uid, Map<String, dynamic> data) {
    final availability = data['availability'];
    final availabilitySlots = availability is List
        ? availability.whereType<String>().toList()
        : availability is String && availability.trim().isNotEmpty
        ? [availability]
        : <String>[];
    final preferredTimes = data['preferredTimes'] is List
        ? (data['preferredTimes'] as List).whereType<String>().toList()
        : <String>[];
    return CompanionProfile.fromMap({
      'id': uid,
      'userId': data['userId'] as String? ?? uid,
      'fullName': data['fullName'] as String? ?? '',
      'bio': data['bio'] as String? ?? '',
      'languages': data['languages'] is List
          ? data['languages']
          : const <String>[],
      'interests': data['interests'] is List
          ? data['interests']
          : const <String>[],
      'availability': availability is String
          ? availability
          : availabilitySlots.join(', '),
      'availabilitySlots': availabilitySlots,
      'preferredTimes': preferredTimes,
      'profileImageUrl': data['profileImageUrl'] as String?,
      'verified': true,
      'active': true,
      'profileImagePath': '',
    });
  }

  static bool _matchesPreference(String wanted, Iterable<String> options) {
    final normalizedWanted = wanted.trim().toLowerCase();
    if (normalizedWanted.isEmpty) return false;
    final normalizedOptions = options.join(' ').toLowerCase();
    return switch (normalizedWanted) {
      'weekday' || 'weekdays' =>
        normalizedOptions.contains('weekday') ||
            normalizedOptions.contains('monday') ||
            normalizedOptions.contains('tuesday') ||
            normalizedOptions.contains('wednesday') ||
            normalizedOptions.contains('thursday') ||
            normalizedOptions.contains('friday'),
      'weekend' || 'weekends' =>
        normalizedOptions.contains('weekend') ||
            normalizedOptions.contains('saturday') ||
            normalizedOptions.contains('sunday'),
      _ => normalizedOptions.contains(normalizedWanted),
    };
  }

  CompanionIncomingRequest _incomingRequest(MatchRequest request) {
    return CompanionIncomingRequest(
      request: request,
      elderDisplayName: request.elderDisplayName,
      preferredLanguage: request.preferredLanguage,
      sharedInterests: request.sharedInterests,
      compatibleAvailability: request.compatibleAvailability,
    );
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
      });

  CompanionConnection _connectionModel(String id, Map<String, dynamic> data) =>
      CompanionConnection.fromMap({
        ..._dated(data, ['startedAt', 'pausedAt', 'endedAt']),
        'id': id,
      });

  @override
  Future<void> saveMatchPreferences(MatchPreferences preferences) async {
    final uid = _uid;
    await _requireRole(uid, _elderRole);
    await _traceFirestoreStep(
      'STEP 2 matching preferences write',
      () => _db.collection('matching_preferences').doc(uid).set({
        ...preferences.toMap(),
        'elderId': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<List<MatchRecommendation>> getRecommendations(
    MatchPreferences preferences,
  ) async {
    final uid = _uid;
    await _requireRole(uid, _elderRole);
    if (kDebugMode) {
      debugPrint(
        'W02 matching preferences: '
        'preferredLanguage=${preferences.preferredLanguage}, '
        'interests=${preferences.interests}, '
        'availability=${preferences.availability}, '
        'preferredTime=${preferences.preferredTime}',
      );
      debugPrint(
        'W02 Firestore project: ${_db.app.options.projectId}; '
        'collection: companion_profiles',
      );
      try {
        final rawProfiles = await _db
            .collection('companion_profiles')
            .get(const GetOptions(source: Source.server));
        debugPrint(
          'RAW companion_profiles document count: ${rawProfiles.docs.length}',
        );
        for (final doc in rawProfiles.docs) {
          final data = doc.data();
          debugPrint('RAW doc.id: ${doc.id}');
          debugPrint('RAW keys: ${data.keys.toList()}');
          debugPrint('RAW data: $data');
          debugPrint("RAW active: ${data['active']}");
          debugPrint("RAW verificationStatus: ${data['verificationStatus']}");
        }
      } on FirebaseException catch (error, stackTrace) {
        debugPrint(
          'RAW companion_profiles query failed: '
          '${error.code}: ${error.message}',
        );
        debugPrintStack(
          stackTrace: stackTrace,
          label: 'RAW companion_profiles query stack trace',
        );
      }
      const diagnosticStudentUid = 'tuEHoDT34KTwuS6pJvd858QjqS93';
      try {
        final diagnosticProfile = await _profile(diagnosticStudentUid)
            .get(const GetOptions(source: Source.server));
        debugPrint(
          'W02 diagnostic direct GET '
          'companion_profiles/$diagnosticStudentUid: '
          'exists=${diagnosticProfile.exists}, permissionDenied=false',
        );
      } on FirebaseException catch (error, stackTrace) {
        debugPrint(
          'W02 diagnostic direct GET '
          'companion_profiles/$diagnosticStudentUid failed: '
          'exists=unknown, permissionDenied=${error.code == 'permission-denied'}, '
          '${error.code}: ${error.message}',
        );
        debugPrintStack(
          stackTrace: stackTrace,
          label: 'W02 diagnostic direct GET stack trace',
        );
      }
    }
    final candidates = await _traceFirestoreStep(
      'STEP 3 companion profiles query',
      () => _db
          .collection('companion_profiles')
          .where('active', isEqualTo: true)
          .where('verificationStatus', isEqualTo: _verified)
          .get(const GetOptions(source: Source.server)),
    );
    if (kDebugMode) {
      debugPrint(
        'W02 companion_profiles query returned '
        '${candidates.docs.length} matching profile(s)',
      );
    }
    final eligibleProfiles = <CompanionProfile>[];
    for (final doc in candidates.docs) {
      final data = doc.data();
      final excludedFor = <String>[];
      if (doc.id == uid) excludedFor.add('profile belongs to current user');
      if (data['active'] != true) excludedFor.add('active is not true');
      if (data['verificationStatus'] != _verified) {
        excludedFor.add('verificationStatus is not verified');
      }
      if (data['fullName'] is! String ||
          (data['fullName'] as String).trim().isEmpty) {
        excludedFor.add('fullName is missing or empty');
      }
      if (data['userId'] != doc.id) {
        excludedFor.add('userId does not match document ID');
      }
      if (kDebugMode) {
        debugPrint(
          'W02 profile ${doc.id}: '
          'active=${data['active']}, '
          'verificationStatus=${data['verificationStatus']}, '
          'languages=${data['languages']}, '
          'interests=${data['interests']}, '
          'availability=${data['availability']}, '
          'preferredTimes=${data['preferredTimes']}, '
          'userId=${data['userId']}, fullName=${data['fullName']}',
        );
      }
      if (excludedFor.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            'W02 profile ${doc.id} excluded: ${excludedFor.join('; ')}',
          );
        }
        continue;
      }
      if (!_isEligibleStudentProfile(doc.id, data)) {
        if (kDebugMode) {
          debugPrint(
            'W02 profile ${doc.id} excluded: failed student-profile eligibility',
          );
        }
        continue;
      }
      eligibleProfiles.add(_candidate(doc.id, data));
    }
    return rankCompanions(
      eligibleProfiles,
      preferences,
      debugLog: kDebugMode ? debugPrint : null,
    );
  }

  @override
  Future<CompanionProfile?> getCompanionById(String companionId) async {
    final uid = _uid;
    await _requireRole(uid, _elderRole);
    final doc = await _profile(companionId).get();
    return doc.id != uid && _isEligibleStudentProfile(doc.id, doc.data())
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
    await _requireRole(uid, _elderRole);
    final pair = _pairId(uid, companionId);
    final userRef = _user(uid);
    final profileRef = _profile(companionId);
    final pairRef = _requestPair(pair);
    final requestRef = _db.collection('match_requests').doc();
    await _db.runTransaction((tx) async {
      final user = await tx.get(userRef);
      final student = await tx.get(profileRef);
      final preferences = await tx.get(
        _db.collection('matching_preferences').doc(uid),
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
          student.data()?['userId'] != companionId) {
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
      final preferenceData = preferences.data() ?? const <String, dynamic>{};
      final elderInterests = preferenceData['interests'] is List
          ? (preferenceData['interests'] as List).whereType<String>().toList(
              growable: false,
            )
          : const <String>[];
      final studentInterests = student.data()?['interests'] is List
          ? (student.data()!['interests'] as List).whereType<String>().toList(
              growable: false,
            )
          : const <String>[];
      final availability = student.data()?['availability'];
      final availabilityOptions = availability is List
          ? availability.whereType<String>().toList()
          : availability is String
          ? [availability]
          : const <String>[];
      final preferredTimes = student.data()?['preferredTimes'] is List
          ? (student.data()!['preferredTimes'] as List)
                .whereType<String>()
                .toList()
          : const <String>[];
      final wantedDay = preferenceData['availability'] as String? ?? '';
      final wantedTime = preferenceData['preferredTime'] as String? ?? '';
      final dayMatches = _matchesPreference(wantedDay, availabilityOptions);
      final timeMatches = _matchesPreference(wantedTime, [
        ...availabilityOptions,
        ...preferredTimes,
      ]);
      final compatibleAvailability = [
        if (dayMatches) wantedDay,
        if (timeMatches) wantedTime,
      ].where((value) => value.isNotEmpty).join(' · ');
      tx.set(requestRef, {
        'elderId': uid,
        'companionId': companionId,
        'status': MatchRequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'elderDisplayName': user.data()?['fullName'] as String? ?? '',
        'preferredLanguage':
            preferenceData['preferredLanguage'] as String? ?? '',
        'sharedInterests': elderInterests
            .where(
              (interest) => studentInterests.any(
                (other) => other.toLowerCase() == interest.toLowerCase(),
              ),
            )
            .toSet()
            .toList(growable: false),
        'compatibleAvailability': compatibleAvailability,
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
    if (kDebugMode) {
      debugPrint(
        'Accept STEP 1 current Firebase UID: $uid; '
        'requestId=$requestId; requestedStatus=${status.name}',
      );
    }
    final requestRef = _request(requestId);
    final newConnectionRef = _db.collection('connections').doc();
    final queuedWrites = <String>[];
    try {
      await _db.runTransaction((tx) async {
        final request = await _traceFirestoreStep(
          'Accept STEP 2 request document read',
          () => tx.get(requestRef),
        );
        final data = request.data();
        if (kDebugMode) {
          debugPrint(
            'Accept STEP 2 request status=${data?['status']}, '
            'elderId=${data?['elderId']}, '
            'companionId=${data?['companionId']}',
          );
        }
        if (data == null || data['status'] != 'pending') {
          throw StateError('This request is no longer pending.');
        }
        final elderUid = data['elderId'] as String;
        final studentUid = data['companionId'] as String;
        final pairId = _pairId(elderUid, studentUid);
        final currentUser = await _traceFirestoreStep(
          'Accept STEP 3 current user document read',
          () => tx.get(_user(uid)),
        );
        if (kDebugMode) {
          debugPrint(
            'Accept STEP 3 user role=${currentUser.data()?['role']}, '
            'verificationStatus=${currentUser.data()?['verificationStatus']}',
          );
        }
        DocumentSnapshot<Map<String, dynamic>>? verification;
        if (status == MatchRequestStatus.accepted) {
          final verificationSnapshot = await _traceFirestoreStep(
            'Accept STEP 4 student_verifications document read',
            () =>
                tx.get(_db.collection('student_verifications').doc(studentUid)),
          );
          verification = verificationSnapshot;
          if (kDebugMode) {
            debugPrint(
              'Accept STEP 4 verification '
              'exists=${verificationSnapshot.exists}, '
              'status=${verificationSnapshot.data()?['status']}',
            );
          }
        }
        final pairState = await _traceFirestoreStep(
          'Accept match_request_pairs current connection pointer read',
          () => tx.get(_requestPair(pairId)),
        );
        if (pairState.data()?['currentRequestId'] != requestId) {
          throw StateError('Invalid match request.');
        }
        final isCancellation = status == MatchRequestStatus.cancelled;
        if ((isCancellation &&
                (uid != elderUid ||
                    currentUser.data()?['role'] != _elderRole)) ||
            (!isCancellation &&
                (uid != studentUid ||
                    currentUser.data()?['role'] != _studentRole ||
                    currentUser.data()?['verificationStatus'] != _verified))) {
          throw StateError('You cannot respond to this request.');
        }
        if (status == MatchRequestStatus.accepted) {
          final student = await _traceFirestoreStep(
            'Accept STEP 5 companion profile read',
            () => tx.get(_profile(studentUid)),
          );
          if (kDebugMode) {
            debugPrint(
              'Accept STEP 5 profile active=${student.data()?['active']}, '
              'verificationStatus=${student.data()?['verificationStatus']}',
            );
          }
          if (!_eligible(student.data()) ||
              student.data()?['userId'] != studentUid ||
              (verification?.exists == true &&
                  verification?.data()?['status'] != _verified)) {
            throw StateError(
              'The student profile is no longer active/verified.',
            );
          }
          final existingId =
              pairState.data()?['currentConnectionId'] as String?;
          final existing = existingId == null
              ? null
              : await _traceFirestoreStep(
                  'Accept STEP 6 existing connection lookup',
                  () => tx.get(_connection(existingId)),
                );
          if (kDebugMode) {
            debugPrint(
              'Accept STEP 6 existing connection ID=$existingId, '
              'status=${existing?.data()?['status'] ?? 'none'}',
            );
          }
          if (existing != null && existing.data()?['status'] != 'ended') {
            throw StateError('A connection already exists.');
          }
          tx.update(requestRef, {
            'status': status.name,
            'respondedAt': FieldValue.serverTimestamp(),
          });
          queuedWrites.add('match_requests update');
          _traceTransactionWrite(
            'Accept STEP 7 match_requests update '
            '(status=${status.name}, respondedAt=serverTimestamp)',
          );
          tx.update(_requestPair(pairId), {
            'currentConnectionId': newConnectionRef.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          queuedWrites.add('match_request_pairs update');
          _traceTransactionWrite('Accept STEP 8 match_request_pairs update');
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
          queuedWrites.add('connections create');
          _traceTransactionWrite('Accept STEP 9 connections document create');
        } else {
          tx.update(requestRef, {
            'status': status.name,
            'respondedAt': FieldValue.serverTimestamp(),
          });
          queuedWrites.add('match_requests update');
          _traceTransactionWrite(
            'Accept STEP 7 match_requests update '
            '(status=${status.name}, respondedAt=serverTimestamp)',
          );
        }
      });
    } on FirebaseException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Accept transaction ${queuedWrites.isEmpty ? 'read phase' : 'commit'} '
          'failed${queuedWrites.isEmpty ? '' : ' after queued writes ${queuedWrites.join(', ')}'}: '
          '${error.code}: ${error.message}',
        );
        debugPrintStack(
          stackTrace: stackTrace,
          label: 'Accept transaction commit stack trace',
        );
      }
      rethrow;
    }
    final saved = await _traceFirestoreStep(
      'Accept STEP 11 accepted request post-transaction read',
      () => requestRef.get(),
    );
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
  Stream<List<CompanionIncomingRequest>> watchIncomingRequests() async* {
    final uid = _uid;
    await _requireRole(uid, _studentRole);
    yield* _db
        .collection('match_requests')
        .where('companionId', isEqualTo: uid)
        .where('status', isEqualTo: MatchRequestStatus.pending.name)
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = snapshot.docs.map(
            (doc) => _incomingRequest(_requestModel(doc.id, doc.data())),
          );
          return List.unmodifiable(requests);
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
    final pair = await _traceFirestoreStep(
      'Accept STEP 12 accepted pair post-transaction read',
      () => _requestPair(_pairId(request.elderId, request.companionId)).get(),
    );
    final connectionId = pair.data()?['currentConnectionId'] as String?;
    if (connectionId == null) {
      throw StateError('The accepted connection is not available yet.');
    }
    final saved = await _traceFirestoreStep(
      'Accept STEP 13 created connection post-transaction read',
      () => _connection(connectionId).get(),
    );
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
    await _requireRole(uid, _elderRole);
    final snapshot = await _db
        .collection('connections')
        .where('elderId', isEqualTo: uid)
        .get();
    return _currentConnection(snapshot.docs);
  }

  @override
  Stream<CompanionConnection?> watchCurrentConnection(String elderId) async* {
    final uid = _uid;
    await _requireRole(uid, _elderRole);
    yield* _db
        .collection('connections')
        .where('elderId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => _currentConnection(snapshot.docs));
  }

  @override
  Stream<CompanionConnection?> watchCompanionConnection() async* {
    final uid = _uid;
    await _requireRole(uid, _studentRole);
    yield* _db
        .collection('connections')
        .where('companionId', isEqualTo: uid)
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
