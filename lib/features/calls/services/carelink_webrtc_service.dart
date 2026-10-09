import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CareLinkWebRtcService {
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  final ValueNotifier<String> state = ValueNotifier('idle');
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  DocumentReference<Map<String, dynamic>>? _room;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _candidateSubscription;
  final List<RTCIceCandidate> _pendingLocal = [];
  final List<RTCIceCandidate> _pendingRemote = [];
  bool _caller = false;
  bool _roomReady = false;
  bool _remoteDescriptionReady = false;
  bool _applyingAnswer = false;
  bool _connected = false;
  bool _stopping = false;
  bool _initialized = false;
  bool _disposed = false;
  VoidCallback? onConnected;
  VoidCallback? onRemoteEnded;
  String? get callId => _room?.id;
  bool get isConnected => _connected;
  bool get hasAudio => _localStream?.getAudioTracks().isNotEmpty ?? false;
  bool get hasVideo => _localStream?.getVideoTracks().isNotEmpty ?? false;
  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in to CareLink first.');
    }
    return uid;
  }

  void _setState(String next) {
    if (!_disposed) {
      state.value = next;
    }
  }

  // ==========================================================
  // INITIALIZE CAMERA RENDERERS
  // ==========================================================
  Future<void> initialize() async {
    if (_initialized) return;
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    localRenderer.muted = true;
    _initialized = true;
  }

  // ==========================================================
  // PREPARE MICROPHONE, CAMERA AND PEER CONNECTION
  // ==========================================================
  Future<void> _preparePeer({required bool video}) async {
    if (!_initialized) {
      await initialize();
    }
    _setState('requesting-permission');
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? <String, dynamic>{'facingMode': 'user'} : false,
    });
    localRenderer.srcObject = _localStream;
    _peer = await createPeerConnection({
      'iceServers': [
        {
          'urls': ['stun:stun.l.google.com:19302'],
        },
      ],
      'sdpSemantics': 'unified-plan',
    });
    final peer = _peer!;
    peer.onTrack = (event) {
      if (_stopping) return;
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };
    peer.onIceCandidate = (candidate) {
      if (_stopping) return;
      if (candidate.candidate != null) {
        unawaited(_sendLocalCandidate(candidate));
      }
    };
    peer.onConnectionState = (connectionState) {
      if (_stopping) return;
      if (connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _setState('connected');
        if (!_connected) {
          _connected = true;
          onConnected?.call();
        }
      } else if (connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        _setState('connecting');
      } else if (connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _setState('disconnected');
      } else if (connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _setState('failed');
      }
    };
    for (final track in _localStream!.getTracks()) {
      await peer.addTrack(track, _localStream!);
    }
  }

  // ==========================================================
  // VALIDATE REAL CHECK-IN AND CONNECTION
  // ==========================================================
  Future<void> _validateCheckIn({
    required String checkInId,
    required String connectionId,
    required String elderId,
    required String companionId,
    required String mode,
  }) async {
    final checkIn = await _db.collection('check_ins').doc(checkInId).get();
    final data = checkIn.data();
    if (data == null ||
        data['elderId'] != elderId ||
        data['companionId'] != companionId) {
      throw StateError('Invalid check-in participants.');
    }
    if (data['status'] != 'ready') {
      throw StateError('The Student Companion has not confirmed readiness.');
    }
    final bookedMode = data['mode'];
    if (bookedMode != 'Video' && bookedMode != 'Voice') {
      throw StateError('Invalid booked call mode.');
    }
    // Voice-only is allowed for a Video booking.
    // A Voice booking cannot be upgraded to Video.
    if (bookedMode == 'Voice' && mode != 'Voice') {
      throw StateError('This is a voice-only check-in.');
    }
    if (mode != 'Voice' && mode != 'Video') {
      throw StateError('Invalid call mode.');
    }
    final rawTime = data['scheduledAt'];
    final rawDuration = data['durationMinutes'];
    if (rawTime is! Timestamp || rawDuration is! num || rawDuration <= 0) {
      throw StateError('Invalid check-in time or duration.');
    }
    final scheduledAt = rawTime.toDate();
    final endsAt = scheduledAt.add(Duration(minutes: rawDuration.toInt()));
    final now = DateTime.now();
    if (now.isBefore(scheduledAt) || !now.isBefore(endsAt)) {
      throw StateError('The scheduled call window is not open.');
    }
    final connection = await _db
        .collection('connections')
        .doc(connectionId)
        .get();
    final connectionData = connection.data();
    if (connectionData == null ||
        connectionData['elderId'] != elderId ||
        connectionData['companionId'] != companionId ||
        connectionData['status'] != 'active') {
      throw StateError('The Elder and Student connection is not active.');
    }
  }

  // ==========================================================
  // ELDER: START CALL
  // ==========================================================
  Future<String> startCaller({
    required String checkInId,
    required String connectionId,
    required String elderId,
    required String companionId,
    required String mode,
  }) async {
    if (_uid != elderId) {
      throw StateError('Only the Elder can start this call.');
    }
    if (_room != null) {
      throw StateError('A call attempt is already active.');
    }
    _caller = true;
    await _validateCheckIn(
      checkInId: checkInId,
      connectionId: connectionId,
      elderId: elderId,
      companionId: companionId,
      mode: mode,
    );
    await _preparePeer(video: mode == 'Video');
    final offer = await _peer!.createOffer();
    await _peer!.setLocalDescription(offer);
    // Each call attempt gets a unique document.
    // A cancelled attempt does not reuse old ICE candidates.
    final room = _db.collection('video_calls').doc();
    _room = room;
    await room.set({
      'checkInId': checkInId,
      'connectionId': connectionId,
      'elderId': elderId,
      'companionId': companionId,
      'mode': mode,
      'status': 'ringing',
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'answer': null,
      'createdAt': FieldValue.serverTimestamp(),
      'answeredAt': null,
      'endedAt': null,
      'endedBy': null,
    });
    _roomReady = true;
    await _flushLocalCandidates();
    _listenForCandidates('calleeCandidates');
    _listenToRoom();
    _setState('ringing');
    return room.id;
  }

  // ==========================================================
  // STUDENT: ANSWER CALL
  // ==========================================================
  Future<void> answerCall({required String callId}) async {
    if (_room != null) {
      throw StateError('A call is already active.');
    }
    _caller = false;
    final room = _db.collection('video_calls').doc(callId);
    final snapshot = await room.get();
    final data = snapshot.data();
    if (data == null ||
        data['companionId'] != _uid ||
        data['status'] != 'ringing' ||
        data['answer'] != null) {
      throw StateError('No available incoming call.');
    }
    final checkInId = data['checkInId'] as String?;
    final connectionId = data['connectionId'] as String?;
    final elderId = data['elderId'] as String?;
    final companionId = data['companionId'] as String?;
    final mode = data['mode'] as String?;
    if (checkInId == null ||
        connectionId == null ||
        elderId == null ||
        companionId == null ||
        mode == null) {
      throw StateError('Incomplete call details.');
    }
    await _validateCheckIn(
      checkInId: checkInId,
      connectionId: connectionId,
      elderId: elderId,
      companionId: companionId,
      mode: mode,
    );
    final offerData = data['offer'];
    if (offerData is! Map) {
      throw StateError('Incoming call offer is missing.');
    }
    _room = room;
    await _preparePeer(video: mode == 'Video');
    await _peer!.setRemoteDescription(
      RTCSessionDescription(
        offerData['sdp'] as String,
        offerData['type'] as String,
      ),
    );
    _remoteDescriptionReady = true;
    _listenForCandidates('callerCandidates');
    final answer = await _peer!.createAnswer();
    await _peer!.setLocalDescription(answer);
    await room.update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
    });
    _roomReady = true;
    await _flushLocalCandidates();
    await _flushRemoteCandidates();
    _listenToRoom();
    _setState('connecting');
  }

  // ==========================================================
  // LISTEN TO SIGNALING
  // ==========================================================
  void _listenToRoom() {
    final room = _room;
    if (room == null) return;
    _roomSubscription = room.snapshots().listen(
      (snapshot) async {
        if (_stopping) return;
        final data = snapshot.data();
        if (data == null) return;
        if (data['status'] == 'ended') {
          await stop(notifyRemote: false);
          onRemoteEnded?.call();
          return;
        }
        if (!_caller || _remoteDescriptionReady || _applyingAnswer) {
          return;
        }
        final answerData = data['answer'];
        if (answerData is! Map) return;
        _applyingAnswer = true;
        try {
          await _peer!.setRemoteDescription(
            RTCSessionDescription(
              answerData['sdp'] as String,
              answerData['type'] as String,
            ),
          );
          _remoteDescriptionReady = true;
          await _flushRemoteCandidates();
          _setState('connecting');
        } catch (error) {
          _setState('error: $error');
        } finally {
          _applyingAnswer = false;
        }
      },
      onError: (Object error) {
        _setState('error: $error');
      },
    );
  }

  // ==========================================================
  // SEND ICE CANDIDATES
  // ==========================================================
  Future<void> _sendLocalCandidate(RTCIceCandidate candidate) async {
    if (_stopping) return;
    if (!_roomReady || _room == null) {
      _pendingLocal.add(candidate);
      return;
    }
    final collection = _caller ? 'callerCandidates' : 'calleeCandidates';
    try {
      await _room!.collection(collection).add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      _setState('error: $error');
    }
  }

  Future<void> _flushLocalCandidates() async {
    final candidates = List<RTCIceCandidate>.from(_pendingLocal);
    _pendingLocal.clear();
    for (final candidate in candidates) {
      await _sendLocalCandidate(candidate);
    }
  }

  // ==========================================================
  // RECEIVE ICE CANDIDATES
  // ==========================================================
  void _listenForCandidates(String collection) {
    final room = _room;
    if (room == null) return;
    _candidateSubscription = room
        .collection(collection)
        .snapshots()
        .listen(
          (snapshot) async {
            if (_stopping) return;
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) {
                continue;
              }
              final data = change.doc.data();
              if (data == null) continue;
              final candidate = RTCIceCandidate(
                data['candidate'] as String?,
                data['sdpMid'] as String?,
                (data['sdpMLineIndex'] as num?)?.toInt(),
              );
              if (!_remoteDescriptionReady) {
                _pendingRemote.add(candidate);
              } else {
                try {
                  await _peer?.addCandidate(candidate);
                } catch (error) {
                  _setState('error: $error');
                }
              }
            }
          },
          onError: (Object error) {
            _setState('error: $error');
          },
        );
  }

  Future<void> _flushRemoteCandidates() async {
    final candidates = List<RTCIceCandidate>.from(_pendingRemote);
    _pendingRemote.clear();
    for (final candidate in candidates) {
      await _peer?.addCandidate(candidate);
    }
  }

  // ==========================================================
  // REAL MICROPHONE CONTROL
  // ==========================================================
  bool toggleMicrophone() {
    final tracks = _localStream?.getAudioTracks() ?? [];
    if (tracks.isEmpty) return false;
    final enabled = !tracks.first.enabled;
    for (final track in tracks) {
      track.enabled = enabled;
    }
    return enabled;
  }

  // ==========================================================
  // REAL CAMERA CONTROL
  // ==========================================================
  bool toggleCamera() {
    final tracks = _localStream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return false;
    final enabled = !tracks.first.enabled;
    for (final track in tracks) {
      track.enabled = enabled;
    }
    return enabled;
  }

  // ==========================================================
  // HANG UP / CLEANUP
  // ==========================================================
  Future<void> stop({bool notifyRemote = true}) async {
    if (_stopping) return;
    _stopping = true;
    if (notifyRemote && _roomReady && _room != null) {
      try {
        await _room!.update({
          'status': 'ended',
          'endedBy': _uid,
          'endedAt': FieldValue.serverTimestamp(),
        });
      } catch (error) {
        debugPrint('Call signaling cleanup error: $error');
      }
    }
    await _roomSubscription?.cancel();
    await _candidateSubscription?.cancel();
    await _peer?.close();
    _peer = null;
    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
      _localStream = null;
    }
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    _pendingLocal.clear();
    _pendingRemote.clear();
    _setState('ended');
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await stop(notifyRemote: false);
    if (_initialized) {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    }
    _disposed = true;
    state.dispose();
  }
}
