import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:atk/patient/bloc/login_cubit.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

/// Passwordless email sign-in with a one-time verification code.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _teal = Color(0xFF197278);
  static const _ink = Color(0xFF283D3B);
  static const _muted = Color(0xFF4F6463);
  static const _border = Color(0xFFDDE6E4);
  static const _danger = Color(0xFFA93A2C);

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _boxes = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  bool _isDoctorMode = false;

  @override
  void dispose() {
    _email.dispose();
    for (final c in _boxes) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _boxes.map((c) => c.text).join();

  // ---------- Validation ----------

 String? _validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Please enter your email address';
  if (!RegExp(r'^[^\s@A-Z]+@[^\s@A-Z]+\.[^\s@A-Z]+$').hasMatch(email)) {
    return 'Enter a valid lowercase email address';
  }
  return null;
}


  String? _validateCode() {
    final code = _code;
    if (code.isEmpty) return 'Please enter the 6-digit code';
    if (code.length != 6) return 'The code must be 6 digits';
    return null;
  }

  // ---------- Actions ----------

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<LoginCubit>().sendCode(_email.text.trim(), role: _isDoctorMode ? 'doctor' : 'user');
    if (mounted && context.read<LoginCubit>().state.otpSent) {
      _nodes.first.requestFocus();
    }
  }

  Future<void> _verify() async {
    final problem = _validateCode();
    if (problem != null) {
      context.read<LoginCubit>().showError(problem);
      return;
    }
    await context.read<LoginCubit>().verify(_email.text.trim(), _code, role: _isDoctorMode ? 'doctor' : 'user');
  }

  void _onBoxChanged(int i, String v) {
    context.read<LoginCubit>().clearError();
    if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    if (_code.length == 6) _verify();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        final profileComplete = state.profileComplete;
        if (profileComplete != null) {
          Navigator.pushReplacementNamed(
            context,
            profileComplete ? '/home' : '/profile-setup',
            arguments: _email.text.trim(),
          );
        }
      },
      builder: (context, state) => _buildLogin(context, state),
    );
  }

  Widget _buildLogin(BuildContext context, LoginState state) {
    return Scaffold(
      backgroundColor: _teal,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 450;
            return Column(
              children: [
                if (constraints.maxHeight >= 150)
                  SizedBox(
                    height: compact ? 56 : constraints.maxHeight * 0.4,
                    child: Padding(
                      padding: compact
                          ? const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 6,
                            )
                          : const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: BackButton(
                                color: Colors.white,
                                onPressed: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/intro',
                                ),
                              ),
                            ),
                          ),
                          if (!compact) const Spacer(),
                          if (!compact)
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mail_outline_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          if (!compact) const Spacer(),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7F6),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: ResponsiveContent(
                        maxWidth: 600,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isDoctorMode ? 'Doctor Portal' : 'Welcome back',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDoctorMode
                                    ? 'Enter your registered clinician email address. We will send you a verification code.'
                                    : 'Enter your email address. We will send you a verification code. No password needed.',
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Email address
                              const Text(
                                'Email address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                maxLength: 50,
                                controller: _email,
                                enabled: !state.otpSent,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _sendCode(),
                                decoration: _fieldDecoration('you@example.com'),
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    return newValue.copyWith(
                                      text: newValue.text.toLowerCase(),
                                    );
                                  }),
                                ],
                                validator: _validateEmail,
                              ),

                              // Code boxes
                              if (state.otpSent) ...[
                                const SizedBox(height: 24),
                                const Text(
                                  'Enter code',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(6, (i) {
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: i == 5 ? 0 : 10,
                                        ),
                                        child: SizedBox(
                                          height: 60,
                                          child: TextField(
                                            controller: _boxes[i],
                                            focusNode: _nodes[i],
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            maxLength: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            decoration: InputDecoration(
                                              counterText: '',
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: EdgeInsets.zero,
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                borderSide: BorderSide(
                                                  color: state.error != null
                                                      ? _danger
                                                      : _border,
                                                  width: 1.5,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                borderSide: const BorderSide(
                                                  color: _teal,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) =>
                                                _onBoxChanged(i, v),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    const Text(
                                      'Code valid for 10 minutes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _muted,
                                      ),
                                    ),
                                    state.seconds > 0
                                        ? Text(
                                            'Resend in 0:${state.seconds.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _muted,
                                            ),
                                          )
                                        : TextButton(
                                            onPressed: state.loading
                                                ? null
                                                : _sendCode,
                                            style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 6,
                                                  ),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Resend code',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _teal,
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ],

                              if (state.error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  state.error ?? "",
                                  style: const TextStyle(
                                    color: _danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),
                              ResponsiveAction(
                                height: 56,
                                child: FilledButton(
                                  onPressed: state.loading
                                      ? null
                                      : (state.otpSent ? _verify : _sendCode),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: state.loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          state.otpSent
                                              ? 'Verify and continue'
                                              : 'Send code',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isDoctorMode = !_isDoctorMode;
                                      _email.clear();
                                      for (final c in _boxes) {
                                        c.clear();
                                      }
                                    });
                                    context.read<LoginCubit>().clearError();
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      text: _isDoctorMode ? 'Are you a patient? ' : 'Are you a doctor? ',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _muted,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _isDoctorMode ? 'Patient sign in' : 'Doctor sign in',
                                          style: const TextStyle(
                                            color: _teal,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _border, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _danger, width: 2),
      ),
    );
  }
}
