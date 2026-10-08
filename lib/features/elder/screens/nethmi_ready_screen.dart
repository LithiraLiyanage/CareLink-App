import 'package:flutter/material.dart';

import '../../companion/models/companion_language.dart';
import '../../companion/models/companion_profile.dart';
import '../../companion/screens/conversation_ideas_screen.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'active_video_call_screen.dart';
import 'checkin_complete_nethmi_screen.dart';

class NethmiReadyScreen extends StatelessWidget {
  const NethmiReadyScreen({
    super.key,
    this.companionName = 'Student Companion',
    this.companionImageUrl,
    this.scheduledAt,
    this.durationMinutes = 30,
    this.mode = 'Video',
    this.onStartCall,
    this.onVoiceCall,
    this.onConversationIdeas,
  });

  final String companionName;
  final String? companionImageUrl;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String mode;
  final VoidCallback? onStartCall;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onConversationIdeas;

  void _startVideoCall(BuildContext context) {
    if (onStartCall != null) {
      onStartCall!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveVideoCallScreen(
          elderId: 'elder-kamala',
          elderName: 'Older Adult',
          companionId: 'companion-1',
          companionName: companionName,
          companionImageUrl: companionImageUrl,
          connectionId: '',
          checkInId: 'checkin-1',
          scheduledAt: scheduledAt ?? DateTime.now(),
          durationMinutes: durationMinutes,
          callType: mode,
          onEndCall: () async {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => CheckInCompleteNethmiScreen(
                  companionName: companionName,
                  companionImageUrl: companionImageUrl,
                  scheduledAt: scheduledAt,
                  durationMinutes: durationMinutes,
                  mode: mode,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startVoiceCall(BuildContext context) {
    if (onVoiceCall != null) {
      onVoiceCall!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveVideoCallScreen(
          elderId: 'elder-kamala',
          elderName: 'Older Adult',
          companionId: 'companion-1',
          companionName: companionName,
          companionImageUrl: companionImageUrl,
          connectionId: '',
          checkInId: 'checkin-1',
          scheduledAt: scheduledAt ?? DateTime.now(),
          durationMinutes: durationMinutes,
          callType: 'Voice',
          onEndCall: () async {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => CheckInCompleteNethmiScreen(
                  companionName: companionName,
                  companionImageUrl: companionImageUrl,
                  scheduledAt: scheduledAt,
                  durationMinutes: durationMinutes,
                  mode: 'Voice',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openConversationIdeas(BuildContext context) {
    if (onConversationIdeas != null) {
      onConversationIdeas!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationIdeasScreen(
          profile: CompanionProfile(
            id: 'companion-1',
            name: companionName,
            imagePath: '',
            profileImageUrl: companionImageUrl,
            verified: true,
            languages: const ['English', 'Sinhala'],
            interests: const ['Gardening', 'Music', 'Stories'],
            availability: 'Available today',
            about: 'Verified Student Companion',
          ),
          selectedLanguage: CompanionLanguage.english,
          openedFromCheckIn: true,
        ),
      ),
    );
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
                      name: companionName,
                      role: 'Verified student companion',
                      imageUrl: companionImageUrl,
                    ),
                    _ReadyMetrics(durationMinutes: durationMinutes, mode: mode),
                    ElderPrimaryButton(
                      label: 'Start video call',
                      height: 54,
                      onPressed: () => _startVideoCall(context),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElderOutlineButton(
                            label: 'Voice only',
                            height: 48,
                            onPressed: () => _startVoiceCall(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElderOutlineButton(
                            label: 'Message instead',
                            height: 48,
                            onPressed: () => ScaffoldMessenger.of(context)
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
                    SizedBox(
                      width: double.infinity,
                      child: ElderOutlineButton(
                        label: 'Conversation Ideas',
                        height: 48,
                        foregroundColor: ElderColors.darkTeal,
                        backgroundColor: const Color(0xFFBDF1F3),
                        onPressed: () => _openConversationIdeas(context),
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
          companionImageUrl == null || companionImageUrl!.isEmpty
              ? _companionPlaceholder
              : Image.network(
                  companionImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _companionPlaceholder,
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
              '$companionName is ready',
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
              scheduledAt == null
                  ? '$durationMinutes min · $mode check-in'
                  : '${MaterialLocalizations.of(context).formatMediumDate(scheduledAt!)} · '
                        '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(scheduledAt!))} · '
                        '$durationMinutes min · $mode',
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

  Widget get _companionPlaceholder => Container(
    color: ElderColors.deepTeal,
    alignment: Alignment.center,
    child: CircleAvatar(
      radius: 58,
      backgroundColor: ElderColors.mintSoft,
      child: Text(
        companionName
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
  final String? imageUrl;

  const _IdentityRow({
    required this.name,
    required this.role,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: ElderColors.mintSoft,
          child: imageUrl == null || imageUrl!.isEmpty
              ? _initials
              : ClipOval(
                  child: Image.network(
                    imageUrl!,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initials,
                  ),
                ),
        ),
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
        const ElderStatusPill('VERIFIED'),
      ],
    );
  }

  Widget get _initials => Text(
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
