import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'admin_dashboard_page.dart';
import 'admin_service.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isRegisteredEmail = false;
  Timer? _resendTimer;
  int _secondsRemaining = 0;

  static const Color _adminPrimary = Color(0xFF0F172A); // Slate 900
  static const Color _adminAccent = Color(0xFF0284C7); // Sky 600
  static const Color _adminDark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final token = await AdminService.getToken();
    if (token != null && token.isNotEmpty && mounted) {
      Navigator.of(context).pushReplacementNamed('/admin-dashboard');
    }
  }

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
      final result = await AdminService.sendOtp(email);
      if (!mounted) return;

      final isRegistered = result['isRegistered'] as bool? ?? false;
      final serverMessage = result['message'] as String? ??
          (isRegistered
              ? 'Administrator email recognized. Verification code sent.'
              : 'New administrator code sent.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  serverMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: _adminAccent,
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

  bool _isVerifying = false;

  Future<void> _verifyOtp() async {
    if (_isVerifying || _isLoading) return;
    final otp = _otpController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (otp.isEmpty || otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit admin verification code.')),
      );
      return;
    }

    _isVerifying = true;
    setState(() => _isLoading = true);

    try {
      final result = await AdminService.verifyOtp(email, otp);
      if (!mounted) return;

      final user = result['user'] as Map<String, dynamic>? ?? {};
      final adminData = {
        'id': user['id'],
        'email': user['email'] ?? email,
        'role': 'admin',
      };

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AdminDashboardPage(initialAdmin: adminData),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _isVerifying = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _adminPrimary,
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
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Novtek ATK Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Platform Administration & Clinical Oversight',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
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
                        // Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _adminAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security, size: 16, color: _adminAccent),
                                SizedBox(width: 6),
                                Text(
                                  'Restricted Administrator Access',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _adminAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Administrator Sign In',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _adminDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isOtpSent
                              ? 'Enter the 6-digit code sent to ${_emailController.text.trim()}'
                              : 'Enter your administrative email to receive a secure sign-in code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),

                        // Email input
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: _isOtpSent,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Administrator Email',
                            hintText: 'admin@novtek.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            suffixIcon: _isOtpSent
                                ? IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _isOtpSent = false;
                                        _otpController.clear();
                                      });
                                    },
                                    tooltip: 'Change Email',
                                  )
                                : null,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            TextInputFormatter.withFunction((oldVal, newVal) {
                              return newVal.copyWith(text: newVal.text.toLowerCase());
                            }),
                          ],
                          validator: (value) {
                            final email = (value ?? '').trim().toLowerCase();
                            if (email.isEmpty) return 'Admin email address is required';
                            if (RegExp(r'[A-Z]').hasMatch(value ?? '')) {
                              return 'Uppercase letters are not allowed';
                            }
                            if (!RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(email)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        // OTP Section
                        if (_isOtpSent) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isRegisteredEmail ? Colors.blue.shade50 : Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isRegisteredEmail ? Colors.blue.shade200 : Colors.indigo.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isRegisteredEmail ? Icons.verified_user_outlined : Icons.info_outline,
                                  size: 18,
                                  color: _isRegisteredEmail ? Colors.blue.shade800 : Colors.indigo.shade800,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isRegisteredEmail
                                        ? 'Verified administrator account. Enter your security code.'
                                        : 'Administrator verification code generated.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _isRegisteredEmail ? Colors.blue.shade900 : Colors.indigo.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: const TextStyle(
                              letterSpacing: 8,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _adminDark,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Verification Code',
                              hintText: '000000',
                              counterText: '',
                              prefixIcon: Icon(Icons.key_outlined),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isOtpSent = false;
                                    _otpController.clear();
                                  });
                                },
                                child: const Text('Change email'),
                              ),
                              _secondsRemaining > 0
                                  ? Text(
                                      'Resend in ${_secondsRemaining}s',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _isLoading ? null : _sendOtp,
                                      child: const Text('Resend code'),
                                    ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action Button
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_isOtpSent ? _verifyOtp : _sendOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _adminDark,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isOtpSent ? 'Verify & Access Dashboard' : 'Send Admin Code',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Portal Switcher
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pushReplacementNamed('/doctor'),
                              icon: const Icon(Icons.medical_services_outlined, size: 16),
                              label: const Text('Doctor Portal'),
                            ),
                            const Text('•', style: TextStyle(color: Colors.grey)),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                              icon: const Icon(Icons.person_outline, size: 16),
                              label: const Text('Patient Portal'),
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
