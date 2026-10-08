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

    _rtc = CareLinkWebRtcService();
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
  // MAIN UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_ending) {
          unawaited(_confirmEndCall());
        }
      },
      child: ElderPhoneScaffold(
        backgroundColor: ElderColors.background,
        statusBarColor: ElderColors.deepTeal,
        darkStatusBar: false,
        child: Column(
          children: [
            _videoHero(),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: const BoxDecoration(
                  color: ElderColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: ListView(
                  children: [
                    _identityRow(),

                    const SizedBox(height: 26),

                    if (_error != null) _errorCard() else _connectionMessage(),

                    const SizedBox(height: 32),

                    const Text(
                      'Call controls',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ElderColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _control(
                          icon: _muted
                              ? Icons.mic_off_rounded
                              : Icons.mic_none_rounded,
                          label: _muted ? 'Unmute' : 'Mute',
                          active: _muted,
                          onTap: _toggleMicrophone,
                        ),

                        _control(
                          icon: _speaker
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          label: 'Speaker',
                          active: _speaker,
                          onTap: () {
                            unawaited(_toggleSpeaker());
                          },
                        ),

                        if (!_voiceOnly)
                          _control(
                            icon: _camera
                                ? Icons.videocam_rounded
                                : Icons.videocam_off_rounded,
                            label: 'Camera',
                            active: !_camera,
                            onTap: _toggleCamera,
                          ),
                      ],
                    ),

                    const SizedBox(height: 45),

                    ElderPrimaryButton(
                      label: _ending
                          ? 'Ending...'
                          : _connectedOnce
                          ? (_voiceOnly ? 'End voice call' : 'End video call')
                          : 'Cancel call',
                      color: ElderColors.coral,
                      height: 54,
                      onPressed: _ending
                          ? () {}
                          : () {
                              unawaited(_confirmEndCall());
                            },
                    ),

                    const SizedBox(height: 45),

                    const _PrivacyNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // VIDEO AREA
  // ==========================================================

  Widget _videoHero() {
    final localizations = MaterialLocalizations.of(context);

    return SizedBox(
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _remoteVideo(),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1],
                colors: [Color(0x00000000), Color(0xA3000000)],
              ),
            ),
          ),

          // Local camera preview.
          if (!_voiceOnly && _initialized && _rtc.hasVideo)
            Positioned(
              right: 14,
              bottom: 60,
              child: Container(
                width: 96,
                height: 126,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: ElderColors.deepTeal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RTCVideoView(
                      _rtc.localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                    const Positioned(
                      bottom: 6,
                      left: 7,
                      child: Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            left: 14,
            top: 12,
            child: ElderBackButton(
              filled: true,
              onPressed: () {
                unawaited(_confirmEndCall());
              },
            ),
          ),

          Positioned(
            right: 14,
            top: 13,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xB0000000),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 122,
            bottom: 16,
            child: Text(
              '${localizations.formatMediumDate(widget.scheduledAt)} · '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(widget.scheduledAt))}\n'
              '${_connectedOnce ? '$_elapsedLabel elapsed' : 'Waiting to connect'} '
              '· ${widget.durationMinutes} min planned',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_voiceOnly) {
      return _remotePlaceholder();
    }

    return AnimatedBuilder(
      animation: _rtc.remoteRenderer,
      builder: (context, child) {
        final available =
            _rtc.remoteRenderer.srcObject != null && _rtc.isConnected;

        if (!available) {
          return _remotePlaceholder();
        }

        return RTCVideoView(
          _rtc.remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      },
    );
  }

  Widget _remotePlaceholder() {
    return Container(
      color: ElderColors.deepTeal,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 62,
            backgroundColor: ElderColors.mintSoft,
            child: Text(
              _initials,
              style: const TextStyle(
                color: ElderColors.darkTeal,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _connectedOnce
                ? (_voiceOnly
                      ? 'Voice call connected'
                      : 'Waiting for remote video...')
                : 'Calling $_remoteName...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMPANION INFORMATION
  // ==========================================================

  Widget _identityRow() {
    final imageUrl = widget.companionImageUrl;

    return Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: ElderColors.mintSoft,
          child: imageUrl == null || imageUrl.isEmpty
              ? Text(
                  _initials,
                  style: const TextStyle(
                    color: ElderColors.darkTeal,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Text(
                      _initials,
                      style: const TextStyle(
                        color: ElderColors.darkTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _remoteName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Student Companion · '
                '${_voiceOnly ? 'Voice' : 'Video'} call',
                style: const TextStyle(
                  color: ElderColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        ElderStatusPill(
          _rtc.isConnected ? 'CONNECTED' : 'WAITING',
          filled: _rtc.isConnected,
        ),
      ],
    );
  }

  Widget _connectionMessage() {
    final message = _rtc.isConnected
        ? 'You are connected with $_remoteName.'
        : 'Waiting for $_remoteName to answer your call.';

    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: ElderColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: ElderColors.coral),

          const SizedBox(height: 8),

          Text(
            'Could not connect the call.\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: ElderColors.textDark, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _control({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          InkWell(
            onTap: _ending ? null : onTap,
            borderRadius: BorderRadius.circular(40),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: active ? ElderColors.darkTeal : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: ElderColors.deepTeal),
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : ElderColors.deepTeal,
                size: 25,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            label,
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRIVACY NOTE
// ============================================================

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: ElderColors.deepTeal,
          ),
          SizedBox(width: 7),
          Text(
            'Your conversation is private.',
            style: TextStyle(
              color: ElderColors.deepTeal,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
