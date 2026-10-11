import 'package:flutter/material.dart';

import '../services/account_setup_service.dart';
import '../services/setup_back_navigation.dart';
import 'profile_setup_screen.dart';

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  static const Color background = Color(0xFFF7FBFA);
  static const Color teal = Color(0xFF119A96);
  static const Color darkText = Color(0xFF073F47);
  static const Color mutedText = Color(0xFF718E94);
  // static const Color borderColor = Color(0xFFCDE7E4);
  static const Color backCircle = Color(0xFFE8F7F5);

  final _accountSetupService = AccountSetupService();
  String? _selectedRole;
  bool _isSaving = false;

  void _selectRole(String role) {
    if (_isSaving) return;
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _continue() async {
    final selectedRole = _selectedRole;
    if (selectedRole == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _accountSetupService.saveRole(selectedRole);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(selectedRole: selectedRole),
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
          content: Text('Could not save your role. Please try again.'),
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
            child: CustomPaint(painter: _RoleBottomWavePainter()),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: backCircle,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (!_isSaving) SetupBackNavigation.back(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: darkText,
                        size: 30,
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  const Text(
                    'Choose Your Role',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.7,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Tell us how you’ll be using CareLink.',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 19,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 38),

                  _RoleCard(
                    title: 'Older Adult',
                    description: 'Stay connected, schedule companionship and check in easily.',
                    icon: Icons.elderly_rounded,
                    selected: _selectedRole == 'Older Adult',
                    onTap: () {
                      _selectRole('Older Adult');
                    },
                  ),

                  const SizedBox(height: 18),

                  _RoleCard(
                    title: 'Student Companion',
                    description: 'Connect with older adults and offer meaningful companionship.',
                    icon: Icons.volunteer_activism_rounded,
                    selected: _selectedRole == 'Student Companion',
                    onTap: () {
                      _selectRole('Student Companion');
                    },
                  ),

                  const SizedBox(height: 18),

                  _RoleCard(
                    title: 'Family Caregiver',
                    description: 'Stay reassured and connected with a loved one’s consent.',
                    icon: Icons.family_restroom_rounded,
                    selected: _selectedRole == 'Family Caregiver',
                    onTap: () {
                      _selectRole('Family Caregiver');
                    },
                  ),

                  const SizedBox(height: 38),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _selectedRole == null || _isSaving
                          ? null
                          : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        disabledBackgroundColor: teal.withValues(alpha: 0.35),
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF119A96);
    const darkText = Color(0xFF073F47);
    const mutedText = Color(0xFF718E94);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6F7F5) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? teal : const Color(0xFFCDE7E4),
              width: selected ? 2.2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: teal, size: 32),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: teal, width: 2),
                  color: selected ? teal : Colors.transparent,
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

class _RoleBottomWavePainter extends CustomPainter {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
