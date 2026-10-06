import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onboarding_privacy_control_screen.dart';

class OnboardingTrustedCompanionsScreen extends StatelessWidget {
  const OnboardingTrustedCompanionsScreen({super.key});

  static const Color primaryTeal = Color(0xFF079A98);
  static const Color darkText = Color(0xFF073F47);
  static const Color mutedText = Color(0xFF718E94);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.60,
                child: Image.asset(
                  'assets/images/onboarding_trusted_companions.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE7F5F3),
                      child: const Center(
                        child: Icon(
                          Icons.volunteer_activism_rounded,
                          size: 120,
                          color: Color(0xFF72C9C5),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 54,
                right: 27,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const OnboardingPrivacyControlScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: screenHeight * 0.475,
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipPath(
                  clipper: _OnboardingWaveClipper(),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(26, 132, 26, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trusted Companions',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: -0.8,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Connect with verified\n'
                          'student companions.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            height: 1.48,
                            letterSpacing: -0.2,
                          ),
                        ),

                        const Spacer(),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const _PageDot(active: false),

                            const SizedBox(width: 14),

                            const _PageDot(active: true),

                            const SizedBox(width: 14),

                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OnboardingPrivacyControlScreen(),
                                  ),
                                );
                              },
                              child: const _PageDot(active: false),
                            ),

                            const Spacer(),

                            Material(
                              color: primaryTeal,
                              shape: const CircleBorder(),
                              elevation: 0,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const OnboardingPrivacyControlScreen(),
                                    ),
                                  );
                                },
                                child: const SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 38,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 44),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool active;

  const _PageDot({required this.active});

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: OnboardingTrustedCompanionsScreen.primaryTeal,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: OnboardingTrustedCompanionsScreen.primaryTeal,
          width: 2,
        ),
      ),
    );
  }
}

class _OnboardingWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 55);

    path.cubicTo(
      size.width * 0.18,
      0,
      size.width * 0.40,
      18,
      size.width * 0.58,
      57,
    );

    path.cubicTo(size.width * 0.75, 95, size.width * 0.88, 99, size.width, 58);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
