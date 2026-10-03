import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Color careColor = Color(0xFF31D5D2);
  static const Color linkColor = Color(0xFFFF625F);

  // Match this with the upper area of splash_bottom.png
  static const Color splashBackground = Color(0xFF132C32);

  // Route opened once the splash has been shown.
  static const String nextRoute = '/family-linking';
  static const Duration displayDuration = Duration(seconds: 2);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color careColor = SplashScreen.careColor;
  static const Color linkColor = SplashScreen.linkColor;
  static const Color splashBackground = SplashScreen.splashBackground;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.displayDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(SplashScreen.nextRoute);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashBackground,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ==========================================
            // SAME BACKGROUND COLOR AS BOTTOM IMAGE
            // ==========================================
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF123238),
                      Color(0xFF132D32),
                      Color(0xFF132C32),
                    ],
                    stops: [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // ==========================================
            // BOTTOM ARTWORK
            // Slight overlap prevents a visible seam.
            // ==========================================
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: Transform.translate(
                offset: const Offset(0, -1),
                child: Image.asset(
                  'assets/images/splash_bottom.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),

            // ==========================================
            // LOGO
            // ==========================================
            Positioned(
              top: 190,
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

            // ==========================================
            // CARELINK
            // ==========================================
            Positioned(
              top: 395,
              left: 0,
              right: 0,
              child: Center(
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Care',
                        style: TextStyle(
                          color: careColor,
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: -1,
                        ),
                      ),
                      TextSpan(
                        text: 'Link',
                        style: TextStyle(
                          color: linkColor,
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================
            // TAGLINE
            // ==========================================
            const Positioned(
              top: 450,
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
          ],
        ),
      ),
    );
  }
}
