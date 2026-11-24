import 'package:material_ui/material_ui.dart';

import 'admin_service.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static const _background = Color(0xFFF5F7F8);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF90A3BD);
  static const _purple = Color(0xFF4F35F3);

  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final signedIn = await AdminService.isLoggedIn();
      if (mounted && signedIn && !_loading) _openDashboard();
    } catch (_) {}
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _openDashboard() =>
      Navigator.of(context).pushReplacementNamed('/admin-dashboard');

  Future<void> _submit() async {
    if (_loading) return;
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter the master password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AdminService.signInWithPassword(_password.text);
      if (mounted) {
        _password.clear();
        _openDashboard();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE5F0)),
    );

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: 448,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFEDF2F7)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 25,
                    offset: Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF1FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: _purple,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Admin Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enter the master password to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF60738E),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'MASTER PASSWORD',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    readOnly: _loading,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: _muted),
                      filled: true,
                      fillColor: _background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: const BorderSide(color: _purple, width: 2),
                      ),
                    ),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _loading
                        ? const Text('Authenticating…')
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Authenticate Securely',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
