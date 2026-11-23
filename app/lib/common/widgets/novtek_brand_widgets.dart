import 'package:material_ui/material_ui.dart';

/// Minimalist, Simple & Attractive Novtek ATK Logo Icon
class NovtekLogoIcon extends StatelessWidget {
  final double size;
  final bool isDark;

  const NovtekLogoIcon({
    super.key,
    this.size = 32,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    final crossLength = size * 0.54;
    final crossThickness = size * 0.22;
    final crossRadius = crossThickness / 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5), // Electric Indigo
            Color(0xFF06B6D4), // Cyan
            Color(0xFF10B981), // Healing Mint
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: crossLength,
          height: crossLength,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Horizontal cross bar
              Container(
                width: crossLength,
                height: crossThickness,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(crossRadius),
                ),
              ),
              // Vertical cross bar
              Container(
                width: crossThickness,
                height: crossLength,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(crossRadius),
                ),
              ),
              // Central vital dot
              Container(
                width: size * 0.10,
                height: size * 0.10,
                decoration: const BoxDecoration(
                  color: Color(0xFF06B6D4),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimalist Horizontal Brand Lockup ("novtek" + "atk" badge)
class NovtekBrandLockup extends StatelessWidget {
  final double iconSize;
  final bool isDark;
  final String subtitle;

  const NovtekBrandLockup({
    super.key,
    this.iconSize = 32,
    this.isDark = false,
    this.subtitle = 'CLINICAL ADMIN',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NovtekLogoIcon(size: iconSize, isDark: isDark),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'novtek',
                  style: TextStyle(
                    fontSize: iconSize * 0.44,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'atk',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4F46E5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
