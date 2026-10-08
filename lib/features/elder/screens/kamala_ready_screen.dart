import 'package:flutter/material.dart';

import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';

class KamalaReadyScreen extends StatelessWidget {
  const KamalaReadyScreen({
    super.key,
    this.elderName = 'Older Adult',
    this.elderId,
    this.elderImageUrl,
    this.scheduledAt,
    this.durationMinutes = 30,
    this.mode = 'Video',
    this.companionId,
    this.connectionId,
    this.checkInId,
    this.onStartCall,
    this.onVoiceCall,
    this.onMessageInstead,
    this.onConversationIdeas,
  });

  final String elderName;
  final String? elderId;
  final String? elderImageUrl;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String mode;
  final String? companionId;
  final String? connectionId;
  final String? checkInId;
  final VoidCallback? onStartCall;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onMessageInstead;
  final VoidCallback? onConversationIdeas;

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
                      name: elderName,
                      role: 'Older Adult',
                      avatar: '',
                      imageUrl: elderImageUrl,
                    ),
                    _ReadyMetrics(durationMinutes: durationMinutes, mode: mode),
                    ElderPrimaryButton(
                      label: mode.toLowerCase() == 'voice'
                          ? 'Start voice call'
                          : 'Start video call',
                      height: 54,
                      onPressed:
                          onStartCall ??
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Calling is not available in CareLink yet.',
                              ),
                            ),
                          ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElderOutlineButton(
                            label: 'Voice only',
                            height: 48,
                            onPressed: onVoiceCall ?? () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElderOutlineButton(
                            label: 'Message instead',
                            height: 48,
                            onPressed:
                                onMessageInstead ??
                                onConversationIdeas ??
                                () => ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Messaging is not available in CareLink yet.',
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
          elderImageUrl == null || elderImageUrl!.isEmpty
              ? _elderPlaceholder
              : Image.network(
                  elderImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _elderPlaceholder,
                ),
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
              '$elderName is ready',
              style: const TextStyle(
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
              '${_scheduleDate(context)} · ${_scheduleTime(context)} · $mode check-in',
              style: const TextStyle(
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

  String _scheduleDate(BuildContext context) {
    final scheduled = scheduledAt;
    if (scheduled == null) return '';
    final now = DateTime.now();
    if (scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day) {
      return 'Today';
    }
    return MaterialLocalizations.of(context).formatMediumDate(scheduled);
  }

  String _scheduleTime(BuildContext context) {
    final scheduled = scheduledAt;
    if (scheduled == null) return '';
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(scheduled));
  }

  Widget get _elderPlaceholder => Container(
    color: ElderColors.deepTeal,
    alignment: Alignment.center,
    child: CircleAvatar(
      radius: 58,
      backgroundColor: ElderColors.mintSoft,
      child: Text(
        elderName
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0])
            .join(),
        style: const TextStyle(
          color: ElderColors.darkTeal,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _IdentityRow extends StatelessWidget {
  final String name;
  final String role;
  final String avatar;
  final String? imageUrl;

  const _IdentityRow({
    required this.name,
    required this.role,
    required this.avatar,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        imageUrl != null && imageUrl!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  imageUrl!,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initials(name),
                ),
              )
            : avatar.isEmpty
            ? CircleAvatar(
                radius: 27,
                backgroundColor: ElderColors.mintSoft,
                child: _initials(name),
              )
            : ElderAvatar(asset: avatar, size: 54, border: false),
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

  Widget _initials(String name) => Text(
    name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join(),
    style: const TextStyle(
      color: ElderColors.darkTeal,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _ReadyMetrics extends StatelessWidget {
  const _ReadyMetrics({required this.durationMinutes, required this.mode});

  final int durationMinutes;
  final String mode;

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
          Expanded(child: _Metric('$durationMinutes min', 'planned')),
          VerticalDivider(width: 1, color: ElderColors.border),
          Expanded(child: _Metric(mode, 'check-in type')),
          VerticalDivider(width: 1, color: ElderColors.border),
          Expanded(child: _Metric('Safe', 'controls on')),
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
