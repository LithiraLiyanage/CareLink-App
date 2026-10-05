import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color background = Color(0xFFEFFAF8);
  static const Color teal = Color(0xFF149995);
  static const Color careColor = Color(0xFF2FC2C0);
  static const Color linkColor = Color(0xFFFF6762);
  static const Color darkText = Color(0xFF123C43);
  static const Color mutedText = Color(0xFF789196);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;

          return Stack(
            children: [
              // --------------------------------------------------
              // BOTTOM LANDSCAPE IMAGE
              // --------------------------------------------------
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: height * 0.39,
                child: Image.asset(
                  'assets/images/welcome_bottom.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: const Color(0xFFDFF5F2));
                  },
                ),
              ),

              // Soft fade above bottom image
              Positioned(
                left: 0,
                right: 0,
                bottom: height * 0.30,
                height: height * 0.12,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          background,
                          background.withValues(alpha: 0.92),
                          background.withValues(alpha: 0.40),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 42),

                      // ------------------------------------------
                      // LOGO
                      // ------------------------------------------
                      Image.asset(
                        'assets/images/carelink_logo.png',
                        width: 152,
                        height: 152,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),

                      const SizedBox(height: 18),

                      // ------------------------------------------
                      // CARELINK BRAND TEXT
                      // ------------------------------------------
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Care',
                              style: TextStyle(
                                color: careColor,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: 'Link',
                              style: TextStyle(
                                color: linkColor,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'CONNECT',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.3,
                              ),
                            ),
                            TextSpan(
                              text: '  •  ',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'CARE',
                              style: TextStyle(
                                color: linkColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.3,
                              ),
                            ),
                            TextSpan(
                              text: '  •  ',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'COMFORT',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.3,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 38),

                      // ------------------------------------------
                      // TAGLINE
                      // ------------------------------------------
                      const Text(
                        'A safer, kinder community\nfor our seniors.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: darkText,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ------------------------------------------
                      // GET STARTED BUTTON
                      // ------------------------------------------
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.arrow_forward_rounded, size: 27),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ------------------------------------------
                      // LOGIN TEXT
                      // ------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                color: teal,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),
                    ],
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
