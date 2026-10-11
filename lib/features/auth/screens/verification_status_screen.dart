import 'package:flutter/material.dart';

import 'welcome_screen.dart';

class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  static const Color background = Color(0xFFF7FBFA);
  static const Color teal = Color(0xFF119A96);
  static const Color darkText = Color(0xFF073F47);
  static const Color mutedText = Color(0xFF718E94);
  static const Color borderColor = Color(0xFFCDE7E4);

  void _backToWelcome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
      (route) => false,
    );
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
            height: 210,
            child: CustomPaint(painter: _StatusBottomWavePainter()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 42),
                  Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: teal,
                      size: 78,
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Verification Submitted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkText,
                      fontSize: 33,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Thanks! We'll review your student verification details.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 19,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      children: [
                        _PendingIndicator(),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pending Review',
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "You'll be able to continue as a verified Student Companion once your verification has been approved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 34),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _backToWelcome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Back to Welcome',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingIndicator extends StatelessWidget {
  const _PendingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.pending_actions_rounded,
        color: Color(0xFFD98216),
        size: 28,
      ),
    );
  }
}

class _StatusBottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFFDDF5F2);
    final paint2 = Paint()..color = const Color(0xFFC9EFEC);

    final path1 = Path()
      ..moveTo(0, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.05,
        size.width * 0.50,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.95,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.25,
        size.width * 0.55,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height,
        size.width,
        size.height * 0.68,
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
