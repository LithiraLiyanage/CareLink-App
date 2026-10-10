import 'package:flutter/material.dart';

import '../services/account_setup_service.dart';
import '../services/setup_back_navigation.dart';
import 'language_accessibility_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String selectedRole;

  const ProfileSetupScreen({super.key, required this.selectedRole});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const Color background = Color(0xFFF7FBFA);
  static const Color teal = Color(0xFF119A96);
  static const Color darkText = Color(0xFF073F47);
  static const Color mutedText = Color(0xFF718E94);
  static const Color borderColor = Color(0xFFCDE7E4);
  static const Color backCircle = Color(0xFFE8F7F5);

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _accountSetupService = AccountSetupService();

  bool _isSaving = false;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final data = await _accountSetupService.loadProfile();
      if (!mounted) return;
      _fullNameController.text = data['fullName'] as String? ?? '';
      _phoneController.text = data['phone'] as String? ?? '';
      _locationController.text = data['location'] as String? ?? '';
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isLoading ||
        _loadFailed ||
        _isSaving ||
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _accountSetupService.saveProfile(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        location: _locationController.text,
        role: widget.selectedRole,
      );
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LanguageAccessibilityScreen(selectedRole: widget.selectedRole),
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
          content: Text('Could not save your profile. Please try again.'),
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

  InputDecoration _fieldDecoration({required String hintText, IconData? icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: mutedText, fontSize: 17),
      prefixIcon: icon == null ? null : Icon(icon, color: teal),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: darkText,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
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
            height: 190,
            child: CustomPaint(painter: _ProfileBottomWavePainter()),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 34),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back
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

                    if (_isLoading) const LinearProgressIndicator(color: teal),
                    if (_loadFailed)
                      TextButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry loading saved profile'),
                      ),
                    const SizedBox(height: 30),

                    const Text(
                      'Set Up Your Profile',
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
                      'Tell us a little about yourself.',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 19,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Selected role
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: teal,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.selectedRole,
                            style: const TextStyle(
                              color: teal,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Profile image
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7F5),
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: teal,
                              size: 68,
                            ),
                          ),

                          Positioned(
                            right: 0,
                            bottom: 2,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: teal,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  // Later:
                                  // profile photo picker
                                },
                                icon: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    _label('Full Name'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _fullNameController,
                      enabled: !_isLoading && !_isSaving,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(
                        hintText: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    _label('Phone Number'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isLoading && !_isSaving,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(
                        hintText: '+94 77 123 4567',
                        icon: Icons.phone_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    _label('Location'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _locationController,
                      enabled: !_isLoading && !_isSaving,
                      textInputAction: TextInputAction.done,
                      decoration: _fieldDecoration(
                        hintText: 'Colombo, Sri Lanka',
                        icon: Icons.location_on_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 34),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isSaving || _isLoading || _loadFailed
                            ? null
                            : _continue,
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

                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBottomWavePainter extends CustomPainter {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
