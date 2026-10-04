import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'checkin_complete_nethmi_screen.dart';

class ActiveVideoCallKamalaScreen extends StatefulWidget {
  const ActiveVideoCallKamalaScreen({super.key});

  @override
  State<ActiveVideoCallKamalaScreen> createState() =>
      _ActiveVideoCallKamalaScreenState();
}

class _ActiveVideoCallKamalaScreenState
    extends State<ActiveVideoCallKamalaScreen> {
  bool muted = false;
  bool speaker = true;
  bool camera = true;

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      statusBarColor: const Color(0xFF7C9B8A),
      darkStatusBar: false,
      child: Column(
        children: [
          _hero(context),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 8),
              color: ElderColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _IdentityRow(
                    name: 'Kamala Perera',
                    role: 'Elder',
                    avatar: ElderAssets.kamalaAvatar,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Call controls',
                    style: TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _control(
                        muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_none_rounded,
                        'Mute',
                        () => setState(() => muted = !muted),
                      ),
                      _control(
                        speaker
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        'Speaker',
                        () => setState(() => speaker = !speaker),
                      ),
                      _control(
                        camera
                            ? Icons.videocam_outlined
                            : Icons.videocam_off_outlined,
                        'Camera',
                        () => setState(() => camera = !camera),
                      ),
                      _control(
                        Icons.cameraswitch_outlined,
                        'Switch',
                        () {},
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElderPrimaryButton(
                    label: 'End video call',
                    color: ElderColors.coral,
                    height: 54,
                    onPressed: () async {
                      final ok = await elderConfirm(
                        context,
                        title: 'End video call?',
                        message:
                            'This will finish the current check-in.',
                        confirmLabel: 'End call',
                        destructive: true,
                      );
                      if (!ok || !context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              const CheckInCompleteNethmiScreen(),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: ElderColors.deepTeal,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Your conversation is private.',
                          style: TextStyle(
                            color: ElderColors.deepTeal,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
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
      height: 318,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ElderAssets.activeCall, fit: BoxFit.cover),
          Positioned(
            left: 13,
            top: 10,
            child: ElderBackButton(
              filled: true,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Positioned(
            left: 15,
            bottom: 13,
            child: Text(
              'Today • 6:30 PM • Video check-in',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _control(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: ElderColors.deepTeal),
            ),
            child: Icon(icon, color: ElderColors.deepTeal, size: 23),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: ElderColors.textDark,
            fontSize: 8,
          ),
        ),
      ],
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
        ElderAvatar(asset: avatar, size: 42, border: false),
        const SizedBox(width: 9),
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
