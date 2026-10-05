import 'package:flutter/material.dart';

import '../services/account_setup_service.dart';
import 'privacy_consent_screen.dart';

class LanguageAccessibilityScreen extends StatefulWidget {
  final String selectedRole;

  const LanguageAccessibilityScreen({super.key, required this.selectedRole});

  @override
  State<LanguageAccessibilityScreen> createState() =>
      _LanguageAccessibilityScreenState();
}

class _LanguageAccessibilityScreenState
    extends State<LanguageAccessibilityScreen> {
  static const Color background = Color(0xFFF7FBFA);
  static const Color teal = Color(0xFF119A96);
  static const Color darkText = Color(0xFF073F47);
  static const Color mutedText = Color(0xFF718E94);
  static const Color borderColor = Color(0xFFCDE7E4);
  static const Color backCircle = Color(0xFFE8F7F5);

  final _accountSetupService = AccountSetupService();
  String _selectedLanguage = 'English';
  bool _largerText = false;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _accountSetupService.saveLanguageAndAccessibility(
        language: _selectedLanguage,
        largerText: _largerText,
        highContrast: _highContrast,
        reduceMotion: _reduceMotion,
      );
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PrivacyConsentScreen(selectedRole: widget.selectedRole),
        ),
      );
    } on AuthenticationRequiredException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your preferences. Please try again.'),
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
            child: CustomPaint(painter: _LanguageBottomWavePainter()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onPressed: () => Navigator.pop(context)),
                  const SizedBox(height: 30),
                  const Text(
                    'Language & Accessibility',
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
                    'Make CareLink comfortable for you.',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 19,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _SectionTitle(
                    icon: Icons.language_rounded,
                    title: 'Language',
                  ),
                  const SizedBox(height: 14),
                  _LanguageOption(
                    title: 'English',
                    selected: _selectedLanguage == 'English',
                    onTap: () {
                      setState(() {
                        _selectedLanguage = 'English';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _LanguageOption(
                    title: 'සිංහල',
                    selected: _selectedLanguage == 'සිංහල',
                    onTap: () {
                      setState(() {
                        _selectedLanguage = 'සිංහල';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _LanguageOption(
                    title: 'தமிழ்',
                    selected: _selectedLanguage == 'தமிழ்',
                    onTap: () {
                      setState(() {
                        _selectedLanguage = 'தமிழ்';
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Accessibility',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AccessibilitySwitchRow(
                    title: 'Larger Text',
                    icon: Icons.text_fields_rounded,
                    value: _largerText,
                    onChanged: (value) {
                      setState(() {
                        _largerText = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _AccessibilitySwitchRow(
                    title: 'High Contrast',
                    icon: Icons.contrast_rounded,
                    value: _highContrast,
                    onChanged: (value) {
                      setState(() {
                        _highContrast = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _AccessibilitySwitchRow(
                    title: 'Reduce Motion',
                    icon: Icons.motion_photos_off_rounded,
                    value: _reduceMotion,
                    onChanged: (value) {
                      setState(() {
                        _reduceMotion = value;
                      });
                    },
                  ),
                  const SizedBox(height: 34),
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
        color: _LanguageAccessibilityScreenState.backCircle,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: _LanguageAccessibilityScreenState.darkText,
          size: 30,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _LanguageAccessibilityScreenState.teal, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _LanguageAccessibilityScreenState.darkText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6F7F5) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? _LanguageAccessibilityScreenState.teal
                  : _LanguageAccessibilityScreenState.borderColor,
              width: selected ? 2.1 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _LanguageAccessibilityScreenState.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? _LanguageAccessibilityScreenState.teal
                      : Colors.transparent,
                  border: Border.all(
                    color: _LanguageAccessibilityScreenState.teal,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibilitySwitchRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AccessibilitySwitchRow({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _LanguageAccessibilityScreenState.borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
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
              color: _LanguageAccessibilityScreenState.teal,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _LanguageAccessibilityScreenState.darkText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: value,
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _LanguageAccessibilityScreenState.teal;
              }

              return const Color(0xFFCFE3E1);
            }),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LanguageBottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFFDDF5F2);
    final paint2 = Paint()..color = const Color(0xFFC9EFEC);

    final path1 = Path()
      ..moveTo(0, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.28,
        0,
        size.width * 0.55,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height,
        size.width,
        size.height * 0.32,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.25,
        size.width * 0.67,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height,
        size.width,
        size.height * 0.70,
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
