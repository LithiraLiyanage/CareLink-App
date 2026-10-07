import 'package:flutter/material.dart';

import '../services/student_verification_service.dart';
import '../services/student_verification_validator.dart';
import 'verification_status_screen.dart';

class StudentVerificationScreen extends StatefulWidget {
  final String selectedRole;
  final StudentVerificationRepository? verificationRepository;

  const StudentVerificationScreen({
    super.key,
    required this.selectedRole,
    this.verificationRepository,
  });

  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  static const Color background = Color(0xFFF7FBFA);
  static const Color teal = Color(0xFF119A96);
  static const Color darkText = Color(0xFF073F47);
  static const Color mutedText = Color(0xFF718E94);
  static const Color borderColor = Color(0xFFCDE7E4);
  static const Color backCircle = Color(0xFFE8F7F5);

  final _formKey = GlobalKey<FormState>();
  final _universityController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _universityEmailController = TextEditingController();
  late final StudentVerificationRepository _verificationService;

  bool _confirmedAccurate = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _verificationService =
        widget.verificationRepository ?? StudentVerificationService();
    _universityController.addListener(_onFormChanged);
    _studentIdController.addListener(_onFormChanged);
    _universityEmailController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _universityController.removeListener(_onFormChanged);
    _studentIdController.removeListener(_onFormChanged);
    _universityEmailController.removeListener(_onFormChanged);
    _universityController.dispose();
    _studentIdController.dispose();
    _universityEmailController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _universityController.text.trim().isNotEmpty &&
        _studentIdController.text.trim().isNotEmpty &&
        StudentVerificationValidator.isValidEmail(
          _universityEmailController.text,
        ) &&
        _confirmedAccurate &&
        !_isSubmitting;
  }

  void _onFormChanged() {
    setState(() {});
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: mutedText, fontSize: 16),
      prefixIcon: Icon(icon, color: teal),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_confirmedAccurate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the information is accurate'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _verificationService.submitVerification(
        selectedRole: widget.selectedRole,
        university: _universityController.text,
        studentId: _studentIdController.text,
        universityEmail: _universityEmailController.text,
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationStatusScreen(
            verificationRepository: _verificationService,
          ),
        ),
      );
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Invalid data')),
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit verification. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
            child: CustomPaint(painter: _StudentBottomWavePainter()),
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
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(height: 26),
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7F5),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: teal,
                          size: 58,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Student Verification',
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
                      'Help us keep CareLink safe and trusted.',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 19,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _FieldLabel('University / Institute'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _universityController,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(
                        hintText: 'Enter your university or institute',
                        icon: Icons.account_balance_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your university or institute';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Student ID'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _studentIdController,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(
                        hintText: 'Enter your student ID',
                        icon: Icons.badge_rounded,
                      ),
                      validator: (value) {
                        if (value == null ||
                            !StudentVerificationValidator.isValidStudentId(
                              value,
                            )) {
                          return 'Please enter your student ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('University Email'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _universityEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      decoration: _fieldDecoration(
                        hintText: 'name@university.edu',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your university email';
                        }
                        if (!StudentVerificationValidator.isValidEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    _ConfirmationRow(
                      value: _confirmedAccurate,
                      onChanged: (value) {
                        setState(() {
                          _confirmedAccurate = value;
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          disabledBackgroundColor: teal.withValues(alpha: 0.35),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Submit Verification',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 130),
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

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        color: _StudentVerificationScreenState.backCircle,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: _StudentVerificationScreenState.darkText,
          size: 30,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _StudentVerificationScreenState.darkText,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConfirmationRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: const ValueKey('verification-confirmation-checkbox'),
          onTap: () => onChanged(!value),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: value
                  ? _StudentVerificationScreenState.teal
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: value
                    ? _StudentVerificationScreenState.teal
                    : _StudentVerificationScreenState.borderColor,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
                : null,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3),
            child: Text(
              'I confirm that the information provided is accurate.',
              style: TextStyle(
                color: _StudentVerificationScreenState.darkText,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentBottomWavePainter extends CustomPainter {
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
