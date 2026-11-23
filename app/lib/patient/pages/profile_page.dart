import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:atk/patient/services/api_client.dart';
import 'package:atk/patient/widgets/responsive_content.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_setup_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _account;

  @override
  void initState() {
    super.initState();
    _account = ApiClient.getAccountProfile();
  }

  void _reload() => setState(() => _account = ApiClient.getAccountProfile());

  Future<void> _editProfile() async {
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const ProfileSetupPage(isEditing: true),
        ),
      );
      if (mounted && saved == true) _reload();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF2F4F8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              Expanded(
                child: ResponsiveContent(
                  maxWidth: 760,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 4,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: _account,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const Text('Loading profile…');
                              }
                              if (snapshot.hasError) {
                                final error = snapshot.error;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      error is ApiException
                                          ? error.message
                                          : 'Could not load your account.',
                                    ),
                                    TextButton(
                                      onPressed: _reload,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                );
                              }
                              final profile =
                                  snapshot.data?['profile']
                                      as Map<String, dynamic>?;
                              final name = profile?['fullName'] as String?;
                              final email = snapshot.data?['email'] as String?;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (name != null)
                                    Text(
                                      name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  if (email != null) Text(email),
                                  if (name == null && email == null)
                                    const Text('Account'),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 48),

                        const Divider(height: 32),

                        _ProfileListTile(
                          icon: Icons.person_rounded,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          onTap: _editProfile,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 24),

                        ResponsiveAction(
                          child: FilledButton.tonalIcon(
                            onPressed: widget.onLogout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ProfileListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
