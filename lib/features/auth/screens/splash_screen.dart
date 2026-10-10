import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/account_flow_navigation.dart';
import 'onboarding_stay_connected_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser != null) {
        _goToOnboarding();
      }
    });
  }

  Future<void> _goToOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingStayConnectedScreen(),
        ),
      );
      return;
    }

    try {
      await AccountFlowNavigation.replaceWithNext(context, clearStack: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load your account. Check your connection and tap to retry.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D43),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToOnboarding,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom decorative image
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/images/splash_bottom.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                filterQuality: FilterQuality.high,
              ),
            ),

            // Main logo
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/carelink_logo.png',
                  width: 165,
                  height: 165,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),

            // CareLink text
            const Positioned(
              top: 382,
              left: 0,
              right: 0,
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Care',
                        style: TextStyle(
                          color: Color(0xFF31D5D2),
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      TextSpan(
                        text: 'Link',
                        style: TextStyle(
                          color: Color(0xFFFF625F),
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tag line
            const Positioned(
              top: 440,
              left: 0,
              right: 0,
              child: Text(
                'CONNECT  •  CARE  •  COMFORT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFA8DEDE),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.1,
                ),
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 90,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF31D5D2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
