import 'package:material_ui/material_ui.dart';
import '../../common/widgets/novtek_brand_widgets.dart';

class PathSelectionPage extends StatelessWidget {
  const PathSelectionPage({super.key});

  static const _slate = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slate,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate, Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final horizontalPadding = wide ? 32.0 : 24.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ModalRoute.of(context)?.canPop ?? false)
                          const BackButton(color: Colors.white),
                        const NovtekBrandLockup(
                          iconSize: 32,
                          subtitle: 'CLINICAL ASSESSMENT',
                          isDark: true,
                        ),
                        SizedBox(height: wide ? 48 : 32),
                        Text(
                          'Choose your path',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: wide ? 36 : 28,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Select the type of clinical check-in you would like to begin.\nWe will guide you through each assessment step.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF94A3B8),
                            fontSize: 15,
                            height: 1.55,
                          ),
                        ),
                        SizedBox(height: wide ? 32 : 24),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _PathCard.addiction(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/addiction',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _PathCard.mentalHealth(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/mental_health',
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _PathCard.addiction(
                            onTap: () =>
                                Navigator.pushNamed(context, '/addiction'),
                          ),
                          const SizedBox(height: 14),
                          _PathCard.mentalHealth(
                            onTap: () =>
                                Navigator.pushNamed(context, '/mental_health'),
                          ),
                        ],
                        const SizedBox(height: 28),
                        const Center(
                          child: Text(
                            'Your answers are strictly confidential and HIPAA/GDPR compliant.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  const _PathCard.addiction({required VoidCallback onTap})
      : this(
          title: 'Addiction Assessment',
          description: 'Screening for substance dependency & treatment pathways',
          icon: Icons.health_and_safety_rounded,
          accentColor: const Color(0xFF4F46E5),
          onTap: onTap,
        );

  const _PathCard.mentalHealth({required VoidCallback onTap})
      : this(
          title: 'Mental Health Evaluation',
          description: 'Emotional balance, anxiety, stress, and wellbeing telemetry',
          icon: Icons.psychology_rounded,
          accentColor: const Color(0xFF06B6D4),
          onTap: onTap,
        );

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
