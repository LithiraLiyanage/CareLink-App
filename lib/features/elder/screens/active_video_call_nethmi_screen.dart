import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'checkin_complete_kamala_screen.dart';

class ActiveVideoCallNethmiScreen extends StatefulWidget {
  const ActiveVideoCallNethmiScreen({super.key});

  @override
  State<ActiveVideoCallNethmiScreen> createState() =>
      _ActiveVideoCallNethmiScreenState();
}

class _ActiveVideoCallNethmiScreenState
    extends State<ActiveVideoCallNethmiScreen> {
  bool muted = false;
  bool speaker = true;
  bool camera = true;

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
                  const _IdentityRow(
                    name: 'Nethmi Jayasooriya',
                    role: 'Verified student companion',
                    avatar: ElderAssets.nethmiAvatar,
                  ),
                  _controlsSection(),
                  ElderPrimaryButton(
                    label: 'End video call',
                    color: ElderColors.coral,
                    height: 54,
                    onPressed: () async {
                      final ok = await elderConfirm(
                        context,
                        title: 'End video call?',
                        message: 'This will finish the current check-in.',
                        confirmLabel: 'End call',
                        destructive: true,
                      );
                      if (!ok || !context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const CheckInCompleteKamalaScreen(),
                        ),
                      );
                    },
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
          const Positioned(
            left: 18,
            bottom: 22,
            child: Text(
              'Today • 6:30 PM • Video check-in',
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
            _control(Icons.cameraswitch_outlined, 'Switch', false, () {}),
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
