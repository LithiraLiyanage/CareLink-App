import 'dart:async';



import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';



import '../models/check_in.dart';

import '../services/firebase_elder_service.dart';
import '../screens/student_checkin_complete_screen.dart';



/// Actual peer-to-peer audio/video. Firestore is used for SDP and ICE signaling,

/// NOT for transmitting audio or video. Media is sent via WebRTC (SRTP).

/// Both parties must be logged in on different browser sessions/devices.

class CareLinkLiveCallScreen extends StatefulWidget {

  const CareLinkLiveCallScreen({

    super.key,

    required this.checkIn,

    required this.flow,

    required this.mode,

    this.incomingRoomId,

  });



  final CheckIn checkIn;

  final ElderFlowContext flow;

  final String mode; // Video or Voice

  final String? incomingRoomId;



  @override

  State<CareLinkLiveCallScreen> createState() => _CareLinkLiveCallScreenState();

}



class _CareLinkLiveCallScreenState extends State<CareLinkLiveCallScreen> {

  final _firestore = FirebaseFirestore.instance;

  final _auth = FirebaseAuth.instance;

  final _service = FirebaseElderService.instance;



  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peer;

  MediaStream? _localStream;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _iceSub;

  DocumentReference<Map<String, dynamic>>? _room;

  final List<RTCIceCandidate> _pendingRemoteIce = [];

  final List<RTCIceCandidate> _pendingLocalIce = [];

  bool _renderersReady = false;

  bool _roomCreated = false;

  bool _remoteDescriptionSet = false;

  bool _settingRemoteDescription = false;

  bool _inCall = false;

  // Freeze the participant role when this call starts. Never decide where
  // End Call goes by re-reading FirebaseAuth after asynchronous cleanup.
  String? _participantIdAtStart;

  Future<void>? _startingStatusUpdate;

  bool _ending = false;

  bool _closed = false;

  bool _muted = false;

  bool _cameraOff = false;

  String _state = 'Preparing secure connection...';

  String? _error;



  bool get _video => widget.mode.toLowerCase() != 'voice';

  bool get _incoming => widget.incomingRoomId != null;

  String get _myId => _auth.currentUser?.uid ?? '';

  String get _otherName => _myId == widget.flow.elderId

      ? widget.flow.companionName

      : widget.flow.elderName;



  @override

  void initState() {

    super.initState();

    // No MediaDevices or Firebase calls run during ordinary widget tests

    // unless the test explicitly opens this real-call route.

    unawaited(_initialize());

  }



  List<Map<String, dynamic>> _iceServers() {

    // STUN works on some networks. Production calls across restrictive NATs

    // require a real, authenticated TURN service configured by the team.

    const turnUrl = String.fromEnvironment('CARELINK_TURN_URL');

    const turnUser = String.fromEnvironment('CARELINK_TURN_USER');

    const turnPass = String.fromEnvironment('CARELINK_TURN_PASS');

    return [

      {'urls': 'stun:stun.l.google.com:19302'},

      if (turnUrl.isNotEmpty)

        {'urls': turnUrl, 'username': turnUser, 'credential': turnPass},

    ];

  }



  Future<void> _initialize() async {

    try {

      if (_myId != widget.flow.elderId &&

          _myId != widget.flow.companionId) {

        throw StateError('You are not a member of this CareLink connection.');

      }

      // Verified participant at the moment the call is opened.
      _participantIdAtStart = _myId;

      await _localRenderer.initialize();

      await _remoteRenderer.initialize();

      _renderersReady = true;

      _localStream = await navigator.mediaDevices.getUserMedia({

        'audio': true,

        'video': _video ? {'facingMode': 'user'} : false,

      });

      _localRenderer.srcObject = _localStream;

      _peer = await createPeerConnection({

        'iceServers': _iceServers(),

        'sdpSemantics': 'unified-plan',

      });

      final peer = _peer!;

      for (final track in _localStream!.getTracks()) {

        await peer.addTrack(track, _localStream!);

      }

      peer.onTrack = (event) {

        if (_closed) return;

        if (event.streams.isNotEmpty) {

          _remoteRenderer.srcObject = event.streams.first;

          if (mounted) setState(() {});

        }

      };

      peer.onIceCandidate = (candidate) {

        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;

        if (_roomCreated) {

          unawaited(_writeIce(candidate));

        } else {

          _pendingLocalIce.add(candidate);

        }

      };

      peer.onConnectionState = (state) {

        if (!mounted || _closed) return;

        final stateName = state.toString().split('.').last.toLowerCase();

        // flutter_webrtc enum value is often RTC...StateConnected,

        // not the literal string "connected".

        final connected = stateName.endsWith('connected') &&

            !stateName.endsWith('disconnected');

        final wasConnected = _inCall;

        setState(() {

          _state = connected ? 'Connected securely' : 'Connection: $stateName';

          if (connected) _inCall = true;

        });

        if (connected && !wasConnected) {

          _startingStatusUpdate = _markStarted();

        }

      };

      if (_incoming) {

        await _answer();

      } else {

        await _startCall();

      }

    } catch (error) {

      if (mounted && !_closed) {

        setState(() {

          _error = error.toString();

          _state = 'Call could not connect';

        });

      }

      // Camera/mic permission denial or signaling failure must not complete

      // a check-in or pretend that the call has connected.

    }

  }



  Future<void> _writeIce(RTCIceCandidate candidate) async {

    final room = _room;

    if (room == null || _closed) return;

    final collection = _incoming ? 'answerCandidates' : 'offerCandidates';

    try {

      await room.collection(collection).add({

        'candidate': candidate.candidate,

        'sdpMid': candidate.sdpMid,

        'sdpMLineIndex': candidate.sdpMLineIndex,

        'createdAt': FieldValue.serverTimestamp(),

      });

    } catch (error) {

      debugPrint('CareLink WebRTC ICE write failed: $error');

    }

  }



  Future<void> _flushLocalIce() async {

    _roomCreated = true;

    for (final candidate in List<RTCIceCandidate>.of(_pendingLocalIce)) {

      await _writeIce(candidate);

    }

    _pendingLocalIce.clear();

  }



  Future<void> _startCall() async {

    final current = _auth.currentUser;

    if (current == null) throw StateError('Sign in to start a call.');

    final callerId = current.uid;

    final calleeId = callerId == widget.flow.elderId

        ? widget.flow.companionId

        : widget.flow.elderId;

    final offer = await _peer!.createOffer({

      'offerToReceiveAudio': 1,

      'offerToReceiveVideo': _video ? 1 : 0,

    });

    await _peer!.setLocalDescription(offer);

    _room = _firestore.collection('carelink_live_calls').doc();

    await _room!.set({

      'connectionId': widget.flow.connectionId,

      'matchRequestId': widget.flow.matchRequestId,

      'checkInId': widget.checkIn.id,

      'elderId': widget.flow.elderId,

      'companionId': widget.flow.companionId,

      'callerId': callerId,

      'calleeId': calleeId,

      'mode': _video ? 'Video' : 'Voice',

      'status': 'ringing',

      'offer': {'type': offer.type, 'sdp': offer.sdp},

      'answer': null,

      'createdAt': FieldValue.serverTimestamp(),

      'answeredAt': null,

      'endedAt': null,

      'endedBy': null,

    });

    await _flushLocalIce();

    _listenIce('answerCandidates');

    _listenRoom();

    if (mounted) setState(() => _state = 'Ringing $_otherName...');

  }



  Future<void> _answer() async {

    _room = _firestore.collection('carelink_live_calls').doc(widget.incomingRoomId);

    final snap = await _room!.get();

    final data = snap.data();

    if (data == null || data['status'] != 'ringing' ||

        data['calleeId'] != _myId || data['checkInId'] != widget.checkIn.id ||

        data['connectionId'] != widget.flow.connectionId) {

      throw StateError('This incoming call is no longer available.');

    }

    final rawOffer = data['offer'] as Map<String, dynamic>;

    await _peer!.setRemoteDescription(

      RTCSessionDescription(rawOffer['sdp'] as String, rawOffer['type'] as String),

    );

    _remoteDescriptionSet = true;

    _listenIce('offerCandidates');

    final answer = await _peer!.createAnswer();

    await _peer!.setLocalDescription(answer);

    await _room!.update({

      'status': 'answered',

      'answer': {'type': answer.type, 'sdp': answer.sdp},

      'answeredAt': FieldValue.serverTimestamp(),

    });

    await _flushLocalIce();

    _listenRoom();

    if (mounted) setState(() => _state = 'Connecting to $_otherName...');

  }



  void _listenRoom() {

    _roomSub = _room!.snapshots().listen((snapshot) async {

      if (_closed) return;

      final data = snapshot.data();

      if (data == null || data['status'] == 'ended') {

        await _finish();

        return;

      }

      if (_incoming || _remoteDescriptionSet || _settingRemoteDescription ||

          data['status'] != 'answered') {

        return;

      }

      final answer = data['answer'];

      if (answer is! Map) return;

      _settingRemoteDescription = true;

      try {

        await _peer?.setRemoteDescription(RTCSessionDescription(

          answer['sdp'] as String, answer['type'] as String,

        ));

        _remoteDescriptionSet = true;

        for (final candidate in List<RTCIceCandidate>.of(_pendingRemoteIce)) {

          await _peer?.addCandidate(candidate);

        }

        _pendingRemoteIce.clear();

        if (mounted) setState(() => _state = 'Connecting media...');

      } catch (error) {

        if (mounted) setState(() => _error = 'Remote session failed: $error');

      } finally {

        _settingRemoteDescription = false;

      }

    }, onError: (Object error) {

      if (mounted) setState(() => _error = 'Call signaling: $error');

    });

  }



  void _listenIce(String collection) {

    _iceSub = _room!.collection(collection).snapshots().listen((snapshot) async {

      for (final change in snapshot.docChanges) {

        if (_closed || change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();

        if (data == null || data['candidate'] is! String) continue;

        final candidate = RTCIceCandidate(

          data['candidate'] as String,

          data['sdpMid'] as String?,

          data['sdpMLineIndex'] as int?,

        );

        if (_remoteDescriptionSet) {

          try {

            await _peer?.addCandidate(candidate);

          } catch (error) {

            debugPrint('CareLink ICE candidate rejected: $error');

          }

        } else {

          _pendingRemoteIce.add(candidate);

        }

      }

    }, onError: (Object error) {

      if (mounted) setState(() => _error = 'ICE signaling: $error');

    });

  }



  Future<void> _markStarted() async {

    try {

      await _service.updateCheckInStatus(

        widget.checkIn.id, CheckInStatus.inProgress,

      );

    } catch (error) {

      debugPrint('CareLink connected; check-in status update failed: $error');

    }

  }



  Future<void> _hangUp() async {

    if (_ending) return;

    debugPrint('[CALL FLOW] End Call pressed');
    setState(() => _ending = true);

    try {

      if (_roomCreated) {

        await _room?.update({

          'status': 'ended',

          'endedAt': FieldValue.serverTimestamp(),

          'endedBy': _myId,

        });

      }

    } catch (error) {

      debugPrint('CareLink call end signaling failed: $error');

    }

    await _finish();

  }



  Future<void> _finish() async {
    if (_closed) return;
    _closed = true;

    await _roomSub?.cancel();
    await _iceSub?.cancel();
    await _peer?.close();
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await _localStream?.dispose();
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    // A ringing/failed call is not a completed check-in.
    // Do not show a successful completion unless the Firestore update succeeds.
    var callCompleted = false;
    if (_inCall) {
      try {
        final startingUpdate = _startingStatusUpdate;
        if (startingUpdate != null) await startingUpdate;
        await _service.updateCheckInStatus(
          widget.checkIn.id,
          CheckInStatus.completed,
        );
        callCompleted = true;
      } catch (error) {
        debugPrint('CareLink check-in completion failed: $error');
      }
    }

    if (!mounted) return;
    setState(() {}); // Allow the route to be replaced after PopScope rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // A signed-in user may change while WebRTC cleanup is in progress,
      // particularly when two accounts are tested in different Chrome tabs.
      // The ID captured when the call opened determines the exit route.
      final openedAsElder = _participantIdAtStart == widget.flow.elderId;
      if (!openedAsElder) {
        debugPrint('[CALL FLOW] Opening Student Check-in Complete '
            '(connected=$_inCall, completed=$callCompleted)');
        // Always show the end screen, including when still ringing. Only
        // claim successful completion if WebRTC and Firestore succeeded.
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            builder: (_) => StudentCheckInCompleteScreen(
              elderName: widget.checkIn.elderName,
              elderId: widget.flow.elderId,
              elderImageUrl: widget.checkIn.elderImageUrl,
              companionId: widget.flow.companionId,
              connectionId: widget.flow.connectionId,
              checkInId: widget.checkIn.id,
              scheduledAt: widget.checkIn.scheduledAt,
              durationMinutes: widget.checkIn.durationMinutes,
              callType: _video ? 'Video' : 'Voice',
              callCompleted: callCompleted,
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        debugPrint('[CALL FLOW] Ending Older Adult call');
        // Existing Elder exit behaviour is preserved by this targeted patch.
        Navigator.of(context).pop();
      }
    });
  }


  @override

  void dispose() {

    // A back-navigation must also stop camera/microphone and end signaling.

    if (!_closed) {

      unawaited(_hangUp());

    }

    if (_renderersReady) {

      _localRenderer.dispose();

      _remoteRenderer.dispose();

    }

    super.dispose();

  }



  void _toggleMic() {

    setState(() => _muted = !_muted);

    for (final track in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {

      track.enabled = !_muted;

    }

  }



  void _toggleCamera() {

    setState(() => _cameraOff = !_cameraOff);

    for (final track in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {

      track.enabled = !_cameraOff;

    }

  }



  @override

  Widget build(BuildContext context) {

    final hasRemoteVideo = _video && _remoteRenderer.srcObject != null;

    return PopScope(

      canPop: _closed,

      onPopInvokedWithResult: (didPop, result) {

        if (!didPop) unawaited(_hangUp());

      },

      child: Scaffold(

        backgroundColor: const Color(0xFF082D30),

        appBar: AppBar(

          title: Text('${_video ? 'Video' : 'Voice'} call with $_otherName'),

          backgroundColor: const Color(0xFF082D30),

          foregroundColor: Colors.white,

          automaticallyImplyLeading: false,

        ),

        body: SafeArea(

          child: Column(children: [

            Expanded(

              child: Stack(children: [

                Positioned.fill(

                  child: hasRemoteVideo

                      ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)

                      : Center(child: Column(

                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [

                            const Icon(Icons.person, size: 92, color: Colors.white70),

                            const SizedBox(height: 12),

                            Text(_otherName,

                                style: const TextStyle(fontSize: 24, color: Colors.white)),

                            const SizedBox(height: 8),

                            Text(_state, style: const TextStyle(color: Colors.white70)),

                          ],

                        )),

                ),

                // An actual attached RTC video element is required on some

                // Flutter Web builds to play the remote AUDIO track too.

                // Keep it rendered, but visually hidden for Voice-only calls.

                if (!_video && _renderersReady)

                  Positioned(

                    left: 0, top: 0, width: 1, height: 1,

                    child: IgnorePointer(

                      child: Opacity(

                        opacity: 0,

                        child: RTCVideoView(_remoteRenderer),

                      ),

                    ),

                  ),

                if (_video && _renderersReady)

                  Positioned(

                    right: 14, top: 16, width: 106, height: 156,

                    child: ClipRRect(

                      borderRadius: BorderRadius.circular(14),

                      child: ColoredBox(

                        color: Colors.black,

                        child: RTCVideoView(_localRenderer, mirror: true),

                      ),

                    ),

                  ),

                if (_error != null)

                  Positioned(

                    left: 12, right: 12, bottom: 16,

                    child: Card(color: const Color(0xFFFFE9E6),

                        child: Padding(

                            padding: const EdgeInsets.all(12),

                            child: Text(_error!, style: const TextStyle(color: Colors.black87)))),

                  ),

              ]),

            ),

            Padding(

              padding: const EdgeInsets.fromLTRB(10, 16, 10, 24),

              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [

                IconButton.filledTonal(

                  tooltip: _muted ? 'Unmute' : 'Mute',

                  onPressed: _toggleMic,

                  icon: Icon(_muted ? Icons.mic_off : Icons.mic),

                ),

                if (_video)

                  IconButton.filledTonal(

                    tooltip: _cameraOff ? 'Turn camera on' : 'Turn camera off',

                    onPressed: _toggleCamera,

                    icon: Icon(_cameraOff ? Icons.videocam_off : Icons.videocam),

                  ),

                FilledButton.icon(

                  style: FilledButton.styleFrom(backgroundColor: Colors.red),

                  onPressed: _ending ? null : _hangUp,

                  icon: const Icon(Icons.call_end),

                  label: const Text('End call'),

                ),

              ]),

            ),

          ]),

        ),

      ),

    );

  }

}
