import 'package:flutter/material.dart';

import '../services/account_setup_service.dart';
import 'student_verification_screen.dart';
import 'welcome_screen.dart';

class PrivacyConsentScreen extends StatefulWidget {
  final String selectedRole;

  const PrivacyConsentScreen({super.key, required this.selectedRole});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  static const Color background = Color(0xFFF7FBFA);
  static const Color teal = Color(0xFF119A96);
  static const Color darkText = Color(0xFF073F47);
  static const Color mutedText = Color(0xFF718E94);
  static const Color borderColor = Color(0xFFCDE7E4);
  static const Color backCircle = Color(0xFFE8F7F5);

  final _accountSetupService = AccountSetupService();
  bool _privacyAccepted = false;
  bool _familySharing = false;
  bool _communication = true;
  bool _isSaving = false;

  void _completeSetup() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Setup Complete'),
          content: const Text('Your CareLink profile setup is complete.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Done',
                style: TextStyle(color: teal, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _continue() async {
    if (!_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Privacy Policy to continue'),
        ),
      );
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _accountSetupService.saveConsents(
        role: widget.selectedRole,
        privacyAccepted: _privacyAccepted,
        familyLinkConsent: _familySharing,
        communicationConsent: _communication,
      );
      if (!mounted) return;

      if (widget.selectedRole == 'Student Companion') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentVerificationScreen(selectedRole: widget.selectedRole),
          ),
        );
        return;
      }

      _completeSetup();
    } on AuthenticationRequiredException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your consent choices. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 190,
            child: CustomPaint(painter: _PrivacyBottomWavePainter()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onPressed: () => Navigator.pop(context)),
                  const SizedBox(height: 28),
                  Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F5),
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: teal,
                        size: 58,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Privacy & Consent',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 33,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "You're always in control of what you share.",
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 19,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ConsentCard(
                    title: 'Privacy Policy',
                    description:
                        'I understand how CareLink uses my information.',
                    icon: Icons.privacy_tip_rounded,
                    value: _privacyAccepted,
                    onChanged: (value) {
                      setState(() {
                        _privacyAccepted = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _ConsentCard(
                    title: 'Family Sharing',
                    description: 'Allow approved family members to see limited CareLink status information.',
                    icon: Icons.family_restroom_rounded,
                    value: _familySharing,
                    onChanged: (value) {
                      setState(() {
                        _familySharing = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _ConsentCard(
                    title: 'Communication',
                    description: 'Allow CareLink to send important account and companionship updates.',
                    icon: Icons.notifications_active_rounded,
                    value: _communication,
                    onChanged: (value) {
                      setState(() {
                        _communication = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'CareLink does not continuously monitor you or make medical or emergency decisions.',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 26),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 130),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        color: _PrivacyConsentScreenState.backCircle,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: _PrivacyConsentScreenState.darkText,
          size: 30,
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConsentCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _PrivacyConsentScreenState.borderColor,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: _PrivacyConsentScreenState.teal,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _PrivacyConsentScreenState.darkText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: _PrivacyConsentScreenState.mutedText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: value,
                activeColor: _PrivacyConsentScreenState.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (checked) => onChanged(checked ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyBottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFFDDF5F2);
    final paint2 = Paint()..color = const Color(0xFFC9EFEC);

    final path1 = Path()
      ..moveTo(0, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.25,
        0,
        size.width * 0.55,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.25,
        size.width * 0.65,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
