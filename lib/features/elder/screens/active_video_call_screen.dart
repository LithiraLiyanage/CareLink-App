import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';

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
    this.elderImageUrl,
    required this.onEndCall,
  });

  final String elderId;
  final String elderName;
  final String? elderImageUrl;
  final String companionId;
  final String connectionId;
  final String checkInId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String callType;
  final Future<void> Function() onEndCall;

  @override
  State<ActiveVideoCallScreen> createState() => _ActiveVideoCallScreenState();
}

class _ActiveVideoCallScreenState extends State<ActiveVideoCallScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _muted = false;
  bool _speaker = true;
  bool _camera = true;
  bool _ending = false;

  bool get _voiceOnly => widget.callType.toLowerCase() == 'voice';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsedLabel {
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _endCall() async {
    final confirmed = await elderConfirm(
      context,
      title: 'End call?',
      message: 'This will finish the current check-in.',
      confirmLabel: 'End call',
      destructive: true,
    );
    if (!confirmed || !mounted || _ending) return;
    setState(() => _ending = true);
    try {
      await widget.onEndCall();
      _timer?.cancel();
    } catch (error) {
      if (!mounted) return;
      setState(() => _ending = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not complete check-in: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: const Color(0xFF7C9B8A),
      darkStatusBar: false,
      child: Column(
        children: [
          _hero(context),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: const BoxDecoration(
                color: ElderColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _identityRow(),
                  Column(
                    children: [
                      const Text(
                        'Call controls',
                        style: TextStyle(
                          color: ElderColors.textDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _control(
                            _muted
                                ? Icons.mic_off_rounded
                                : Icons.mic_none_rounded,
                            'Mute',
                            _muted,
                            () => setState(() => _muted = !_muted),
                          ),
                          _control(
                            _speaker
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            'Speaker',
                            _speaker,
                            () => setState(() => _speaker = !_speaker),
                          ),
                          if (!_voiceOnly)
                            _control(
                              _camera
                                  ? Icons.videocam_outlined
                                  : Icons.videocam_off_outlined,
                              'Camera',
                              _camera,
                              () => setState(() => _camera = !_camera),
                            ),
                        ],
                      ),
                    ],
                  ),
                  ElderPrimaryButton(
                    label: _ending
                        ? 'Ending...'
                        : _voiceOnly
                        ? 'End voice call'
                        : 'End video call',
                    color: ElderColors.coral,
                    height: 54,
                    onPressed: _ending ? () {} : _endCall,
                  ),
                  const _PrivacyNote(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return SizedBox(
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_voiceOnly &&
              widget.elderImageUrl != null &&
              widget.elderImageUrl!.isNotEmpty)
            Image.network(
              widget.elderImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _elderPlaceholder,
            )
          else
            _elderPlaceholder,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.5, 1],
                colors: [Color(0x00000000), Color(0xA3000000)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 12,
            child: ElderBackButton(
              filled: true,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            right: 16,
            top: 14,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: const Color(0xA6000000),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 4,
                    backgroundColor: Color(0xFF6BE3A5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _voiceOnly ? 'CONNECTED' : 'CONNECTED · VIDEO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Text(
              '${localizations.formatMediumDate(widget.scheduledAt)} · '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(widget.scheduledAt))} · '
              '${widget.callType} check-in\n'
              '$_elapsedLabel elapsed · ${widget.durationMinutes} min planned',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _elderPlaceholder => Container(
    color: ElderColors.deepTeal,
    alignment: Alignment.center,
    child: CircleAvatar(
      radius: 64,
      backgroundColor: ElderColors.mintSoft,
      child: Text(
        widget.elderName
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0])
            .join(),
        style: const TextStyle(
          color: ElderColors.darkTeal,
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  Widget _identityRow() {
    final initials = widget.elderName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    return Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: ElderColors.mintSoft,
          child: widget.elderImageUrl == null || widget.elderImageUrl!.isEmpty
              ? Text(
                  initials,
                  style: const TextStyle(
                    color: ElderColors.darkTeal,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : ClipOval(
                  child: Image.network(
                    widget.elderImageUrl!,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Text(
                      initials,
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
                widget.elderName,
                style: const TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _voiceOnly ? 'Elder · Voice call' : 'Elder · Video call',
                style: const TextStyle(
                  color: ElderColors.textMuted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
        const ElderStatusPill('CONNECTED', filled: true),
      ],
    );
  }

  Widget _control(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
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
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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
