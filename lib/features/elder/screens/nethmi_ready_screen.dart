import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'active_video_call_kamala_screen.dart';

class NethmiReadyScreen extends StatelessWidget {
  const NethmiReadyScreen({super.key});

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
              offset: const Offset(0, -8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                decoration: const BoxDecoration(
                  color: ElderColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const _IdentityRow(
                      name: 'Nethmi Jayasooriya',
                      role: 'Verified student companion',
                      avatar: ElderAssets.nethmiAvatar,
                    ),
                    const SizedBox(height: 18),
                    const _ReadyMetrics(),
                    const SizedBox(height: 16),
                    ElderPrimaryButton(
                      label: 'Start video call',
                      height: 54,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ActiveVideoCallKamalaScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElderOutlineButton(
                            label: 'Voice only',
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElderOutlineButton(
                            label: 'Message instead',
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElderOutlineButton(
                        label: 'Conversation Ideas',
                        foregroundColor: ElderColors.darkTeal,
                        backgroundColor: const Color(0xFFBDF1F3),
                        onPressed: () {},
                      ),
                    ),
                    const Spacer(),
                    const ElderInfoCard(
                      icon: Icons.check_rounded,
                      title: 'You stay in control',
                      subtitle: 'End, retry or ask for help at any time.',
                    ),
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
      height: 288,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            ElderAssets.nethmiReady,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x99000000),
                ],
              ),
            ),
          ),
          Positioned(
            left: 13,
            top: 10,
            child: ElderBackButton(
              filled: true,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 38,
            child: Text(
              'Nethmi is ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 22,
            child: Text(
              'Today • 6:30 PM • Video check-in',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9.5,
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
        ElderAvatar(asset: avatar, size: 44, border: false),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: const TextStyle(
                  color: ElderColors.textMuted,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadyMetrics extends StatelessWidget {
  const _ReadyMetrics();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.deepTeal),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          Expanded(child: _Metric('30 min', 'planned duration')),
          Expanded(child: _Metric('Video', 'private call')),
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
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: ElderColors.textMuted,
            fontSize: 7.5,
          ),
        ),
      ],
    );
  }
}
