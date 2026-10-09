import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../calls/services/carelink_webrtc_service.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'checkin_complete_nethmi_screen.dart';

enum _PendingCallChoice { keep, cancel, demo }

class ActiveVideoCallScreen extends StatefulWidget {
  const ActiveVideoCallScreen({
    super.key,
    required this.elderId,
    required this.elderName,
    required this.companionId,
    required this.connectionId,
    required this.checkInId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.callType,
    required this.onEndCall,
    this.elderImageUrl,
    this.companionName,
    this.companionImageUrl,
    this.onConnected,
    this.rtcServiceFactory,
  });
  final String elderId;
  final String elderName;
  final String? elderImageUrl;
  final String companionId;
  final String? companionName;
  final String? companionImageUrl;
  final String connectionId;
  final String checkInId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String callType;
  final Future<void> Function()? onConnected;

  /// Optional injection point for isolated widget tests.
  /// Production uses the real Firebase-backed WebRTC service.
  final CareLinkWebRtcService Function()? rtcServiceFactory;
  final Future<void> Function() onEndCall;
  @override
  State<ActiveVideoCallScreen> createState() => _ActiveVideoCallScreenState();
}

class _ActiveVideoCallScreenState extends State<ActiveVideoCallScreen> {
  late final CareLinkWebRtcService _rtc;
  Timer? _timer;
  Future<void>? _activationFuture;
  Duration _elapsed = Duration.zero;
  bool _initialized = false;
  bool _callStartCompleted = false;
  bool _connectedOnce = false;
  bool _muted = false;
  bool _speaker = true;
  bool _camera = true;
  bool _ending = false;
  bool _allowPop = false;
  String? _error;
  bool get _voiceOnly => widget.callType.toLowerCase() == 'voice';
  String get _remoteName => widget.companionName ?? 'Student Companion';
  String get _initials {
    final value = _remoteName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return value.isEmpty ? '?' : value;
  }

  bool get _speakerSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  // ==========================================================
  // INITIALIZATION
  // ==========================================================
  @override
  void initState() {
    super.initState();
    _rtc = widget.rtcServiceFactory?.call() ?? CareLinkWebRtcService();
    _rtc.state.addListener(_onRtcStateChanged);
    _rtc.onConnected = _onPeerConnected;
    _rtc.onRemoteEnded = () {
      unawaited(_finishCall(remoteEnded: true));
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_initializeCall());
      }
    });
  }

  Future<void> _initializeCall() async {
    try {
      await _rtc.initialize();
      if (!mounted || _ending) return;
      setState(() {
        _initialized = true;
      });
      await _rtc.startCaller(
        checkInId: widget.checkInId,
        elderId: widget.elderId,
        companionId: widget.companionId,
        connectionId: widget.connectionId,
        mode: _voiceOnly ? 'Voice' : 'Video',
      );
      if (!mounted || _ending) return;
      setState(() {
        _camera = _rtc.hasVideo;
        _callStartCompleted = true;
      });
    } catch (error) {
      if (!mounted || _ending) return;
      setState(() {
        _error = error.toString();
      });
      try {
        await _rtc.stop();
      } catch (cleanupError) {
        debugPrint('Call cleanup error: $cleanupError');
      }
    }
  }

  // ==========================================================
  // WEBRTC STATUS
  // ==========================================================
  void _onRtcStateChanged() {
    if (!mounted || _ending) return;
    setState(() {});
  }

  String get _statusLabel {
    if (_error != null) {
      return 'CALL FAILED';
    }
    switch (_rtc.state.value) {
      case 'idle':
        return 'PREPARING';
      case 'requesting-permission':
        return 'CAMERA / MIC';
      case 'ringing':
        return 'CALLING...';
      case 'connecting':
        return 'CONNECTING...';
      case 'connected':
        return _voiceOnly ? 'CONNECTED · VOICE' : 'CONNECTED · VIDEO';
      case 'disconnected':
        return 'RECONNECTING...';
      case 'failed':
        return 'CONNECTION FAILED';
      case 'ended':
        return 'ENDED';
      default:
        return 'WAITING...';
    }
  }

  String get _elapsedLabel {
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ==========================================================
  // REAL PEER CONNECTION
  // ==========================================================
  void _onPeerConnected() {
    if (!mounted || _ending || _connectedOnce) return;
    setState(() {
      _connectedOnce = true;
      _elapsed = Duration.zero;
    });
    final connectedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ending) return;
      setState(() {
        _elapsed = DateTime.now().difference(connectedAt);
      });
    });
    _activationFuture = _recordConnected();
  }

  Future<void> _recordConnected() async {
    try {
      if (widget.onConnected != null) {
        await widget.onConnected!();
      }
    } catch (error) {
      debugPrint('Check-in activation failed: $error');
      if (mounted && !_ending) {
        _showMessage(
          'Call connected, but check-in status '
          'could not be updated: $error',
        );
      }
    }
  }

  // ==========================================================
  // MICROPHONE
  // ==========================================================
  void _toggleMicrophone() {
    if (!_initialized || !_rtc.hasAudio) return;
    final enabled = _rtc.toggleMicrophone();
    setState(() {
      _muted = !enabled;
    });
  }

  // ==========================================================
  // CAMERA
  // ==========================================================
  void _toggleCamera() {
    if (!_initialized || !_rtc.hasVideo) return;
    final enabled = _rtc.toggleCamera();
    setState(() {
      _camera = enabled;
    });
  }

  // ==========================================================
  // SPEAKER
  // ==========================================================
  Future<void> _toggleSpeaker() async {
    if (!_speakerSupported) {
      _showMessage(
        'Use browser or device audio settings '
        'to choose the speaker.',
      );
      return;
    }
    try {
      final nextValue = !_speaker;
      await Helper.setSpeakerphoneOn(nextValue);
      if (!mounted) return;
      setState(() {
        _speaker = nextValue;
      });
    } catch (error) {
      _showMessage('Could not switch speaker: $error');
    }
  }

  // ==========================================================
  // CONFIRM END CALL
  // ==========================================================
  Future<void> _confirmEndCall() async {
    if (_ending) return;
    // Real connected calls follow the original completion flow.
    if (_connectedOnce) {
      final confirmed = await elderConfirm(
        context,
        title: 'End call?',
        message: 'This will finish your check-in.',
        confirmLabel: 'End call',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
      await _finishCall();
      return;
    }
    // Unanswered calls can be cancelled normally.
    // In debug builds, an additional UI demo path is available.
    final choice = await showDialog<_PendingCallChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFFF3EDF6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cancel call?',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  '$_remoteName has not connected yet. '
                  'Cancel this call attempt?',
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext)
                            .pop(_PendingCallChoice.keep);
                      },
                      child: const Text('Keep'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ElderColors.coral,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext)
                            .pop(_PendingCallChoice.cancel);
                      },
                      child: const Text('Cancel call'),
                    ),
                  ],
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _callStartCompleted && _error == null
                          ? () {
                              Navigator.of(dialogContext)
                                  .pop(_PendingCallChoice.demo);
                            }
                          : null,
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: const Text('End call (Demo)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ElderColors.deepTeal,
                        side: const BorderSide(color: ElderColors.deepTeal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preview the post-call screens without '
                    'marking the check-in completed in Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || _ending || choice == null) return;
    switch (choice) {
      case _PendingCallChoice.keep:
        return;
      case _PendingCallChoice.cancel:
        await _finishCall();
        return;
      case _PendingCallChoice.demo:
        await _finishDemoCall();
        return;
    }
  }

  // ==========================================================
  // NEW: END CALL (DEMO)
  // ==========================================================
  Future<void> _finishDemoCall() async {
    if (!kDebugMode ||
        !mounted ||
        _ending ||
        _connectedOnce ||
        !_callStartCompleted) {
      return;
    }
    setState(() {
      _ending = true;
    });
    _timer?.cancel();
    try {
      // Stop the real unanswered signaling session,
      // microphone and camera.
      await _rtc.stop(notifyRemote: true);
      if (!mounted) return;
      // IMPORTANT:
      // Do not call widget.onConnected or widget.onEndCall.
      // This is a UI demo, not a real completed check-in.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => CheckInCompleteNethmiScreen(
            companionName: _remoteName,
            companionImageUrl: widget.companionImageUrl,
            scheduledAt: widget.scheduledAt,
            durationMinutes: widget.durationMinutes,
            mode: widget.callType,
            previewOnly: true,
          ),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ending = false;
        _error = error.toString();
      });
      _showMessage('Could not open post-call demo: $error');
    }
  }

  // ==========================================================
  // REAL END / CANCEL CALL
  // ==========================================================
  Future<void> _finishCall({bool remoteEnded = false}) async {
    if (_ending || !mounted) return;
    setState(() {
      _ending = true;
    });
    _timer?.cancel();
    try {
      await _rtc.stop(notifyRemote: !remoteEnded);
      await _activationFuture;
      if (!mounted) return;
      if (_connectedOnce) {
        // Only a real connected call completes the check-in.
        await widget.onEndCall();
      } else {
        // Unanswered calls remain READY.
        setState(() {
          _allowPop = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ending = false;
        _error = error.toString();
      });
      _showMessage('Could not finish call: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rtc.state.removeListener(_onRtcStateChanged);
    _rtc.onConnected = null;
    _rtc.onRemoteEnded = null;
    unawaited(_rtc.dispose());
    super.dispose();
  }

  // ==========================================================
  // FULL-SCREEN COMPANION-INSPIRED CALL UI
  // Only presentation changes; signaling and lifecycle stay above.
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_ending) unawaited(_confirmEndCall());
      },
      child: ElderPhoneScaffold(
        backgroundColor: const Color(0xFF062E30),
        statusBarColor: const Color(0xFF062E30),
        darkStatusBar: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _remoteVideo(),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x44000000),
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0xB9000000),
                        ],
                        stops: [0, .26, .58, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                    child: Column(
                      children: [
                        _topBar(),
                        const SizedBox(height: 12),
                        if (_error != null) _errorBanner(),
                        const Spacer(),
                        _callDetails(),
                        const SizedBox(height: 26),
                        _callControls(),
                      ],
                    ),
                  ),
                ),
                if (!_voiceOnly && _initialized && _rtc.hasVideo)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 66, right: 18),
                        child: _localPreview(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        Material(
          color: const Color(0xFFE0F5F0),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: const Color(0xFF075A59),
            onPressed: () => unawaited(_confirmEndCall()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Call with $_remoteName',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xDB001C1D),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            _statusLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _localPreview() {
    return Container(
      width: 98,
      height: 135,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0E5555),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RTCVideoView(
            _rtc.localRenderer,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          const Positioned(
            bottom: 6,
            left: 7,
            child: Text(
              'You',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_voiceOnly) return _remotePlaceholder();
    return AnimatedBuilder(
      animation: _rtc.remoteRenderer,
      builder: (context, child) {
        final available =
            _rtc.remoteRenderer.srcObject != null && _rtc.isConnected;
        if (!available) return _remotePlaceholder();
        return RTCVideoView(
          _rtc.remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      },
    );
  }

  Widget _remotePlaceholder() {
    return ColoredBox(
      color: const Color(0xFF063A3C),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFE4F5F0),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF075C5D),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _remoteName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _connectedOnce
                    ? (_voiceOnly
                          ? 'Voice call connected'
                          : 'Waiting for remote video...')
                    : 'Calling $_remoteName...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFBAD5D2), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _callDetails() {
    final localizations = MaterialLocalizations.of(context);
    final formattedDate = localizations.formatMediumDate(widget.scheduledAt);
    final formattedTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(widget.scheduledAt),
    );
    return Column(
      children: [
        Text(
          _rtc.isConnected ? 'CONNECTED' : 'WAITING',
          style: const TextStyle(
            color: Color(0xFFA9F5DF),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$formattedDate · $formattedTime',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          '${_connectedOnce ? '$_elapsedLabel elapsed' : 'Waiting to connect'} · ${widget.durationMinutes} min planned',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        // Keep the elder identity available to accessibility and existing flows.
        const SizedBox(height: 5),
        Text(
          widget.elderName,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _callControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Call controls',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _roundControl(
              icon: _muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
              label: _muted ? 'Unmute' : 'Mute',
              selected: _muted,
              onTap: _toggleMicrophone,
            ),
            _roundControl(
              icon: _speaker
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: 'Speaker',
              selected: _speaker,
              onTap: () => unawaited(_toggleSpeaker()),
            ),
            if (!_voiceOnly)
              _roundControl(
                icon: _camera
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                label: 'Camera',
                selected: !_camera,
                onTap: _toggleCamera,
              ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _ending ? null : () => unawaited(_confirmEndCall()),
            icon: const Icon(Icons.call_end_rounded),
            label: Text(
              _ending
                  ? 'Ending...'
                  : _connectedOnce
                  ? (_voiceOnly ? 'End voice call' : 'End video call')
                  : 'Cancel call',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF84F65),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFAA555C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your conversation is private.',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _roundControl({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            shape: const CircleBorder(),
            color: selected ? const Color(0xFFE9F8F5) : const Color(0xFFBFE4E0),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _ending ? null : onTap,
              child: SizedBox(
                width: 58,
                height: 58,
                child: Icon(icon, color: const Color(0xFF063E40), size: 27),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF873A45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Could not connect the call. $_error',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
