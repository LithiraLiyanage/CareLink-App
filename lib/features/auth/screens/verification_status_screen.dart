import 'package:flutter/material.dart';

import '../services/student_verification_service.dart';
import 'student_verification_screen.dart';
import 'welcome_screen.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({
    super.key,
    this.verificationRepository,
    this.statusStream,
  });

  final StudentVerificationRepository? verificationRepository;
  final Stream<String?>? statusStream;

  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  static const Color background = Color(0xFFF7FBFA);
  static const Color teal = Color(0xFF119A96);
  static const Color darkText = Color(0xFF073F47);
  static const Color mutedText = Color(0xFF718E94);
  static const Color borderColor = Color(0xFFCDE7E4);

  late final Stream<String?> _statusStream;

  @override
  void initState() {
    super.initState();
    final stream = widget.statusStream;
    if (stream != null) {
      _statusStream = stream;
    } else {
      final repository =
          widget.verificationRepository ?? StudentVerificationService();
      _statusStream = repository.watchVerificationStatus();
    }
  }

  void _backToWelcome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
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
            child: StreamBuilder<String?>(
              stream: _statusStream,
              builder: (context, snapshot) {
                final status = snapshot.data;
                final isPending = status == 'pending';
                final isVerified = status == 'verified';
                final isRejected = status == 'rejected';
                final title = snapshot.hasError
                    ? 'Could not load verification status'
                    : isVerified
                    ? 'Verification status'
                    : isRejected
                    ? 'Verification needs attention'
                    : isPending
                    ? 'Verification submitted'
                    : 'Checking verification status';
                final message = snapshot.hasError
                    ? 'Please try again later.'
                    : isVerified
                    ? 'Your student account has been verified.'
                    : isRejected
                    ? 'Your verification was not approved. Please review your details and submit again.'
                    : isPending
                    ? 'Your verification is under review.'
                    : 'Please wait while we check your verification.';
                final statusLabel = snapshot.hasError
                    ? 'Unavailable'
                    : isVerified
                    ? 'Verified'
                    : isRejected
                    ? 'Rejected'
                    : isPending
                    ? 'Pending'
                    : 'Loading';

                return SingleChildScrollView(
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
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Icon(
                          isVerified
                              ? Icons.verified_rounded
                              : isRejected
                              ? Icons.info_outline_rounded
                              : Icons.hourglass_top_rounded,
                          color: teal,
                          size: 78,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 33,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const _PendingIndicator(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      color: mutedText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusLabel,
                                    style: const TextStyle(
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
                      const SizedBox(height: 34),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: isRejected
                              ? () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StudentVerificationScreen(
                                          selectedRole: 'Student Companion',
                                        ),
                                  ),
                                )
                              : () => _backToWelcome(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            isRejected ? 'Review details' : 'Back to Welcome',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                );
              },
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
