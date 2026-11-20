import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'doctor_dashboard_page.dart';
import 'doctor_profile_setup_page.dart';
import 'doctor_service.dart';

class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isRegisteredEmail = false;
  Timer? _resendTimer;
  int _secondsRemaining = 0;

  static const Color _primaryColor = Color(0xFF197278);
  static const Color _secondaryColor = Color(0xFF283D3B);

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _resendTimer?.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final result = await DoctorService.sendOtp(email);
      if (!mounted) return;

      final isRegistered = result['isRegistered'] as bool? ?? false;
      final serverMessage = result['message'] as String? ??
          (isRegistered
              ? 'This email ID is already registered. Verification code sent.'
              : 'New doctor registration. Verification code sent.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isRegistered ? Icons.check_circle_outline : Icons.mark_email_read_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  serverMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isRegistered ? _primaryColor : Colors.indigo.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      setState(() {
        _isRegisteredEmail = isRegistered;
        _isOtpSent = true;
      });
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    final email = _emailController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit verification code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await DoctorService.verifyOtp(email, otp);
      if (!mounted) return;

      final isProfileComplete = result['isProfileComplete'] as bool? ?? false;
      final user = result['user'] as Map<String, dynamic>? ?? {};
      final doctorData = {
        'id': user['id'],
        'email': user['email'] ?? email,
        'name': email.split('@')[0],
      };

      if (!isProfileComplete) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => DoctorProfileSetupPage(
              email: email,
              doctorId: user['id'] as String?,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => DoctorDashboardPage(initialDoctor: doctorData),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Novtek ATK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Doctor Portal & Clinical Review',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Form(
                        key: _formKey,
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_outlined, size: 16, color: _primaryColor),
                                SizedBox(width: 6),
                                Text(
                                  'Authorized Clinician Access',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Doctor Sign In',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your registered doctor email to view assigned patients and assessment scores.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isOtpSent && !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              return newValue.copyWith(
                                text: newValue.text.toLowerCase(),
                              );
                            }),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Doctor Email Address (Lowercase)',
                            hintText: 'doctor@hospital.org',
                            prefixIcon: const Icon(Icons.local_hospital_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          validator: (v) {
                            final email = (v ?? '').trim();
                            if (email.isEmpty) {
                              return 'Doctor email address is required';
                            }
                            if (email.contains(RegExp(r'[A-Z]'))) {
                              return 'Email must not contain uppercase letters';
                            }
                            if (email.contains(' ')) {
                              return 'Email cannot contain spaces';
                            }
                            final emailRegex = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
                            if (!emailRegex.hasMatch(email)) {
                              return 'Enter a valid lowercase email (e.g. doctor@hospital.org)';
                            }
                            return null;
                          },
                        ),
                        if (_isOtpSent) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: (_isRegisteredEmail ? _primaryColor : Colors.indigo).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (_isRegisteredEmail ? _primaryColor : Colors.indigo).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isRegisteredEmail
                                      ? Icons.verified_user_outlined
                                      : Icons.person_add_alt_1_outlined,
                                  color: _isRegisteredEmail ? _primaryColor : Colors.indigo,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isRegisteredEmail
                                        ? 'Email ID is already registered. Code sent to sign in.'
                                        : 'New doctor registration. Code sent to complete setup.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isRegisteredEmail ? _primaryColor : Colors.indigo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _otpController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.number,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: InputDecoration(
                              labelText: '6-Digit Verification Code',
                              hintText: '123456',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: (v) {
                              final code = (v ?? '').trim();
                              if (code.isEmpty) {
                                return 'Verification code is required';
                              }
                              if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
                                return 'Enter the full 6-digit verification code';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isOtpSent = false;
                                        _otpController.clear();
                                        _resendTimer?.cancel();
                                        _secondsRemaining = 0;
                                      });
                                    },
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('Change email', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _isLoading
                              ? null
                              : (_isOtpSent ? _verifyOtp : _sendOtp),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isOtpSent ? 'Verify & Access Portal' : 'Send Login Code',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        if (_isOtpSent) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: _secondsRemaining > 0
                                ? Text(
                                    'Resend code in ${_secondsRemaining}s',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _isLoading ? null : _sendOtp,
                                    child: const Text('Resend Login Code'),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Verification codes expire in 10 minutes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Patient Sign In'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
            ),
          ],
        ),
      ),
    );
  }
}
