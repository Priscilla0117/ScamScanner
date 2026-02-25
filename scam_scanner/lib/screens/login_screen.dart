// ============================================================
// lib/screens/login_screen.dart
// ============================================================
// Platform-aware login:
//   Web    → Google signInWithPopup, Phone signInWithPhoneNumber
//   Mobile → google_sign_in package, verifyPhoneNumber
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  // Mobile: stores verificationId string
  String _verificationId = '';
  // Web: stores ConfirmationResult object
  ConfirmationResult? _webConfirmationResult;

  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  // ─── Google Sign-In (works on both web and mobile) ────────
  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      await _firebaseService.signInWithGoogle();
      _navigateToHome();
    } catch (e) {
      _showError('Google sign-in failed: ${e.toString().split(']').last.trim()}');
    }
  }

  // ─── Phone OTP: Step 1 – Send OTP ─────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      _showError('Enter phone with country code e.g. +60123456789');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });

    if (kIsWeb) {
      // ── Web flow ─────────────────────────────────────
      try {
        final confirmationResult = await _firebaseService.sendPhoneOtpWeb(phone);
        setState(() {
          _webConfirmationResult = confirmationResult;
          _otpSent = true;
          _isLoading = false;
        });
      } catch (e) {
        _showError('Failed to send OTP: ${e.toString().split(']').last.trim()}');
      }
    } else {
      // ── Mobile flow ──────────────────────────────────
      await _firebaseService.sendPhoneOtp(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
        },
        onError: (error) => _showError(error),
        onAutoVerified: (_) => _navigateToHome(),
      );
    }
  }

  // ─── Phone OTP: Step 2 – Verify Code ──────────────────────
  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      _showError('Please enter the 6-digit OTP.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      if (kIsWeb) {
        if (_webConfirmationResult == null) {
          _showError('Session expired. Please resend OTP.');
          return;
        }
        await _firebaseService.verifyPhoneOtpWeb(
          confirmationResult: _webConfirmationResult!,
          smsCode: code,
        );
      } else {
        await _firebaseService.verifyPhoneOtp(
          verificationId: _verificationId,
          smsCode: code,
        );
      }
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Invalid OTP. Please try again.');
    } catch (e) {
      _showError('Verification failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              const Icon(Icons.shield_rounded, size: 80, color: Color(0xFFE74C3C)),
              const SizedBox(height: 16),
              const Text(
                'ScamScanner',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your guardian against online scams',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFFBDC3C7)),
              ),

              // ── Web platform notice ──
              if (kIsWeb) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF3498DB)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF3498DB), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '⚠️ Web mode: OCR, Voice & TTS features require Android. Use Android for full features.',
                          style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),

              // ── Google Sign-In Button ──
              _BigButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                icon: Icons.g_mobiledata_rounded,
                label: 'Sign in with Google',
              ),
              const SizedBox(height: 24),

              // ── Divider ──
              Row(children: [
                const Expanded(child: Divider(color: Color(0xFF4A4A6A))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ),
                const Expanded(child: Divider(color: Color(0xFF4A4A6A))),
              ]),
              const SizedBox(height: 24),

              // ── Phone OTP ──
              if (!_otpSent) ...[
                _buildLabel('📱 Phone Number'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                  decoration: _inputDecoration('e.g. +60123456789'),
                ),
                const SizedBox(height: 16),
                _BigButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  backgroundColor: const Color(0xFFE74C3C),
                  foregroundColor: Colors.white,
                  icon: Icons.sms_rounded,
                  label: 'Send OTP Code',
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F3460)),
                  ),
                  child: Column(children: [
                    const Text('✅ OTP sent! Check your SMS.',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    _buildLabel('Enter 6-Digit OTP'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 8),
                      textAlign: TextAlign.center,
                      decoration: _inputDecoration('000000').copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 16),
                    _BigButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      icon: Icons.verified_rounded,
                      label: 'Verify & Login',
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() { _otpSent = false; _webConfirmationResult = null; }),
                      child: const Text('← Change number', style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 16)),
                    ),
                  ]),
                ),
              ],

              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator(color: Color(0xFFE74C3C))),
              ],

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withAlpha(120),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('⚠️ $_errorMessage',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
    style: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 18, fontWeight: FontWeight.w600));

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF6C757D), fontSize: 20),
    filled: true,
    fillColor: const Color(0xFF16213E),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF0F3460), width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  );
}

class _BigButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;

  const _BigButton({required this.onPressed, required this.backgroundColor,
    required this.foregroundColor, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
      ),
    );
  }
}
