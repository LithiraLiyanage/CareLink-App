import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import '../models/check_in.dart';
import '../services/firebase_elder_service.dart';
import 'checkin_complete_kamala_screen.dart';

class ActiveVideoCallKamalaScreen extends StatefulWidget {
  const ActiveVideoCallKamalaScreen({super.key, this.checkInId = ''});

  final String checkInId;

  @override
  State<ActiveVideoCallKamalaScreen> createState() =>
      _ActiveVideoCallKamalaScreenState();
}

class _ActiveVideoCallKamalaScreenState
    extends State<ActiveVideoCallKamalaScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;
  bool muted = false;
  bool speaker = true;
  bool camera = true;
  bool _ending = false;
  bool _loadedRoute = false;
  String _checkInId = '';
  CheckIn? _checkIn;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRoute) return;
    _loadedRoute = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _checkInId = widget.checkInId.isNotEmpty
        ? widget.checkInId
        : (args is String ? args : '');
    if (_checkInId.isNotEmpty) {
      _loadCheckIn();
    } else {
      _error = 'Please start a check-in from My Schedule.';
    }
  }

  Future<void> _loadCheckIn() async {
    try {
      final item = await _service.getCheckInById(_checkInId);
      if (item == null) throw StateError('Check-in not found.');
      if (item.status != CheckInStatus.inProgress) {
        throw StateError('This check-in has not been started.');
      }
      if (mounted) setState(() => _checkIn = item);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  String _timeText(DateTime date) {
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _endCall() async {
    if (_ending) return;
    if (_error != null || _checkIn == null || _checkInId.isEmpty) {
      _message(_error ?? 'Please wait for the check-in to load.');
      return;
    }
    final ok = await elderConfirm(
      context,
      title: 'End video call?',
      message: 'This will finish the current check-in.',
      confirmLabel: 'End call',
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _ending = true);
    try {
      await _service.updateCheckInStatus(_checkInId, CheckInStatus.completed);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          settings: RouteSettings(arguments: _checkInId),
          builder: (_) => const CheckInCompleteKamalaScreen(),
        ),
      );
    } catch (error) {
      _message('Could not complete check-in: $error');
    } finally {
      if (mounted) setState(() => _ending = false);
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
                  _IdentityRow(
                    name: _checkIn?.elderName ?? 'Kamala Perera',
                    role: 'Elder',
                    avatar: ElderAssets.kamalaAvatar,
                  ),
                  _controlsSection(),
                  ElderPrimaryButton(
                    label: _ending ? 'Finishing...' : 'End video call',
                    color: ElderColors.coral,
                    height: 54,
                    onPressed: _endCall,
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
    return SizedBox(
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ElderAssets.activeCall, fit: BoxFit.cover),
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
            child: ElderBackButton(filled: true, onPressed: _endCall),
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF6BE3A5)),
                  SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: TextStyle(
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
            bottom: 22,
            child: Text(
              _checkIn == null
                  ? 'Video check-in'
                  : '${_timeText(_checkIn!.scheduledAt)} • Video check-in',
              style: TextStyle(
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

  Widget _controlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _control(
              muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
              'Mute',
              muted,
              () => setState(() => muted = !muted),
            ),
            _control(
              speaker ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              'Speaker',
              speaker,
              () => setState(() => speaker = !speaker),
            ),
            _control(
              camera ? Icons.videocam_outlined : Icons.videocam_off_outlined,
              'Camera',
              camera,
              () => setState(() => camera = !camera),
            ),
            _control(
              Icons.cameraswitch_outlined,
              'Switch',
              false,
              () =>
                  _message('Camera switching requires a live video provider.'),
            ),
          ],
        ),
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

class _IdentityRow extends StatelessWidget {
  final String name;
  final String role;
  final String avatar;

  const _IdentityRow({
    required this.name,
    required this.role,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElderAvatar(asset: avatar, size: 54, border: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
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
