import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/account_setup_service.dart';
import '../services/auth_service.dart';
import '../services/setup_back_navigation.dart';

class EmailVerificationScreen extends StatefulWidget {
  final Future<void> Function(BuildContext context) onVerified;

  const EmailVerificationScreen({super.key, required this.onVerified});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const background = Color(0xFFF7FBFA);
  static const teal = Color(0xFF119A96);
  static const darkText = Color(0xFF073F47);
  static const mutedText = Color(0xFF718E94);
  static const borderColor = Color(0xFFCDE7E4);

  final _authService = AuthService();
  final _accountSetupService = AccountSetupService();
  bool _isChecking = false;
  bool _isSending = false;

  String get _email => _authService.currentUser?.email ?? 'your email address';

  Future<void> _checkVerification() async {
    if (_isChecking || _isSending) return;
    setState(() => _isChecking = true);

    try {
      await _accountSetupService.recordVerifiedEmail();
      if (!mounted) return;
      await widget.onVerified(context);
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not check verification. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    if (_isChecking || _isSending) return;
    setState(() => _isSending = true);

    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Check your inbox and spam.'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not resend the email. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _cancel() async {
    if (_isChecking || _isSending) return;
    setState(() => _isChecking = true);
    try {
      await SetupBackNavigation.back(context);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  String _firebaseMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'too-many-requests' => 'Too many requests. Please wait and try again.',
      'network-request-failed' =>
        'Please check your internet connection and try again.',
      'user-disabled' => 'This account has been disabled.',
      _ => 'Email verification could not be completed.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 36),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton.filled(
                  onPressed: _cancel,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F7F5),
                    foregroundColor: darkText,
                    fixedSize: const Size(54, 54),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 29),
                ),
              ),
              const SizedBox(height: 58),
              Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: teal,
                  size: 66,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkText,
                  fontSize: 33,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Verify the email address\n$_email',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 18,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 34),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: teal),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Open the link in your email, then return here to continue.',
                        style: TextStyle(
                          color: darkText,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _isChecking || _isSending
                      ? null
                      : _checkVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: const Text(
                    "I've Verified My Email",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _isChecking || _isSending ? null : _resend,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: teal,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Resend Email'),
                style: TextButton.styleFrom(foregroundColor: teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
