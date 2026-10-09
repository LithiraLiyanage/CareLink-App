import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import '../models/check_in.dart';
import '../services/firebase_elder_service.dart';
import '../calling/carelink_live_call_screen.dart';
import 'checkin_complete_kamala_screen.dart';

class KamalaReadyScreen extends StatefulWidget {
  const KamalaReadyScreen({
    super.key,
    this.checkInId = '',
    this.elderName = 'Older Adult',
    this.elderId,
    this.elderImageUrl,
    this.scheduledAt,
    this.durationMinutes = 30,
    this.mode = 'Video',
    this.companionId,
    this.connectionId,
    this.onStartCall,
    this.onVoiceCall,
    this.onMessageInstead,
    this.onConversationIdeas,
  });

  // The preceding Reschedule screen can also pass this in RouteSettings.arguments.
  final String checkInId;
  final String elderName;
  final String? elderId;
  final String? elderImageUrl;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String mode;
  final String? companionId;
  final String? connectionId;
  final VoidCallback? onStartCall;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onMessageInstead;
  final VoidCallback? onConversationIdeas;

  @override
  State<KamalaReadyScreen> createState() => _KamalaReadyScreenState();
}

class _KamalaReadyScreenState extends State<KamalaReadyScreen> {
  late final FirebaseElderService _service = FirebaseElderService.instance;
  bool _routeResolved = false;
  bool _loading = false;
  bool _starting = false;
  String _checkInId = '';
  String? _loadError;
  CheckIn? _checkIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeResolved) return;
    _routeResolved = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _checkInId = widget.checkInId.isNotEmpty
        ? widget.checkInId
        : (args is String ? args : '');
    if (_checkInId.isNotEmpty) {
      _loadCheckIn();
    } else {
      _loadError = 'Open this screen from My Schedule.';
    }
  }

  Future<void> _loadCheckIn() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final checkIn = await _service.getCheckInById(_checkInId);
      if (checkIn == null) throw StateError('Check-in not found.');
      if (checkIn.status == CheckInStatus.cancelled ||
          checkIn.status == CheckInStatus.completed) {
        throw StateError('This check-in is no longer available.');
      }
      if (!mounted) return;
      setState(() => _checkIn = checkIn);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load check-in: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _dateAndTime(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${isToday ? 'Today' : days[date.weekday - 1]} '
        '• $hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'} '
        '• Video check-in';
  }

  Future<void> _startVideoCall() async {
    // Widget-test callbacks remain intact. Production uses actual WebRTC.
    if (widget.onStartCall != null) {
      widget.onStartCall!();
      return;
    }
    await _startRealCall('Video');
  }

  Future<void> _startRealCall(String mode) async {
    if (_starting || _loading) return;
    if (_loadError != null || _checkIn == null || _checkInId.isEmpty) {
      _message(_loadError ?? 'Select a real check-in from My Schedule.');
      return;
    }
    setState(() => _starting = true);
    try {
      final flow = await _service.getCurrentFlowContext();
      // Never mark a session completed or inProgress just because a button
      // was pressed. Real status changes only after WebRTC connects.
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CareLinkLiveCallScreen(
            checkIn: _checkIn!,
            flow: flow,
            mode: mode,
          ),
        ),
      );
      if (!mounted) return;
      final afterCall = await _service.getCheckInById(_checkInId);
      if (!mounted) return;
      if (afterCall?.status == CheckInStatus.completed) {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => CheckInCompleteKamalaScreen(checkInId: _checkInId),
          ),
        );
      } else {
        await _loadCheckIn();
      }
    } catch (error) {
      _message('Could not start $mode call: $error');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: const Color(0xFF8DA890),
      darkStatusBar: false,
      child: Column(
        children: [
          _hero(context),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                decoration: const BoxDecoration(
                  color: ElderColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IdentityRow(
                      name: _checkIn?.elderName ?? widget.elderName,
                      role: 'Older Adult',
                      avatar: ElderAssets.kamalaAvatar,
                    ),
                    _ReadyMetrics(
                      minutes:
                          _checkIn?.durationMinutes ?? widget.durationMinutes,
                    ),
                    ElderPrimaryButton(
                      label: _starting ? 'Starting...' : 'Start video call',
                      height: 54,
                      onPressed: _startVideoCall,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElderOutlineButton(
                            label: 'Voice only',
                            height: 48,
                            onPressed:
                                widget.onVoiceCall ??
                                () => _startRealCall('Voice'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElderOutlineButton(
                            label: 'Message instead',
                            height: 48,
                            onPressed:
                                widget.onMessageInstead ??
                                () =>
                                    _message('Messaging is not connected yet.'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElderOutlineButton(
                        label: 'Conversation Ideas',
                        height: 48,
                        foregroundColor: ElderColors.darkTeal,
                        backgroundColor: const Color(0xFFBDF1F3),
                        onPressed:
                            widget.onConversationIdeas ??
                            () => _message(
                              'Conversation ideas are not connected here yet.',
                            ),
                      ),
                    ),
                    const _ControlInfo(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ElderAssets.kamalaReady, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.35, 1],
                colors: [Color(0x05000000), Color(0xB0000000)],
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
            left: 18,
            right: 18,
            bottom: 48,
            child: Text(
              '${_checkIn?.elderName ?? widget.elderName} is ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 27,
            child: Text(
              _checkIn == null
                  ? 'Today • 6:30 PM • Video check-in'
                  : _dateAndTime(_checkIn!.scheduledAt),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const ElderStatusPill('READY', filled: true),
      ],
    );
  }
}

class _ReadyMetrics extends StatelessWidget {
  const _ReadyMetrics({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.deepTeal),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _Metric('$minutes min', 'planned')),
          const VerticalDivider(width: 1, color: ElderColors.border),
          const Expanded(child: _Metric('Video', 'private call')),
          const VerticalDivider(width: 1, color: ElderColors.border),
          const Expanded(child: _Metric('Safe', 'controls on')),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: ElderColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: ElderColors.textMuted, fontSize: 8.5),
        ),
      ],
    );
  }
}

class _ControlInfo extends StatelessWidget {
  const _ControlInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white,
            child: Icon(Icons.check_rounded, color: ElderColors.deepTeal),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You stay in control',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'End, retry or ask for help at any time.',
                  style: TextStyle(color: ElderColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
