import 'package:material_ui/material_ui.dart';

class PathSelectionPage extends StatelessWidget {
  const PathSelectionPage({super.key});

  static const _teal = Color(0xFF197278);
  static const _ink = Color(0xFF283D3B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _teal,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_teal, _ink],
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
                        const Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0x33FFFFFF),
                              child: Icon(
                                Icons.self_improvement,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'NOVTEK ATK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.7,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: wide ? 54 : 38),
                        Text(
                          'Choose your path',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: wide ? 36 : 30,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Select the type of support you are looking for.\nWe will guide you through the next steps.',
                          style: TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 15,
                            height: 1.55,
                          ),
                        ),
                        SizedBox(height: wide ? 34 : 26),
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
                            'Your journey starts with one step.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
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
    required this.alternate,
    required this.onTap,
  });

  const _PathCard.addiction({required VoidCallback onTap})
    : this(
        title: 'Addiction Assessment',
        description: 'Substance use and dependency screening',
        icon: Icons.health_and_safety_outlined,
        alternate: false,
        onTap: onTap,
      );

  const _PathCard.mentalHealth({required VoidCallback onTap})
    : this(
        title: 'Mental Health',
        description: 'Emotional and psychological well-being',
        icon: Icons.psychology_outlined,
        alternate: true,
        onTap: onTap,
      );

  final String title;
  final String description;
  final IconData icon;
  final bool alternate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = alternate ? Colors.white : const Color(0xFF283D3B);
    return Material(
      color: alternate ? Colors.white.withValues(alpha: 0.16) : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 144),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: alternate
                ? Border.all(color: Colors.white.withValues(alpha: 0.35))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alternate
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0x1A197278),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: alternate ? Colors.white : const Color(0xFF197278),
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: alternate
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF667371),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: alternate ? Colors.white70 : const Color(0xFF197278),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
