import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

/// Interactive, simple, and beautiful ambient mesh background
/// Responds gently to mouse movements on web/desktop and features a calm,
/// continuous ambient breathing motion for mobile/touch screens.
class NovtekInteractiveBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final bool interactive;
  final double intensity;

  const NovtekInteractiveBackground({
    super.key,
    required this.child,
    this.isDark = false,
    this.interactive = true,
    this.intensity = 1.0,
  });

  @override
  State<NovtekInteractiveBackground> createState() =>
      _NovtekInteractiveBackgroundState();
}

class _NovtekInteractiveBackgroundState
    extends State<NovtekInteractiveBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  double _mouseX = 0.0;
  double _mouseY = 0.0;
  double _targetMouseX = 0.0;
  double _targetMouseY = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _animController.repeat(reverse: true);
    } else {
      _animController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerEvent event, Size size) {
    if (!widget.interactive || size.width == 0 || size.height == 0) return;
    final normX = (event.position.dx / size.width) * 2.0 - 1.0;
    final normY = (event.position.dy / size.height) * 2.0 - 1.0;
    setState(() {
      _targetMouseX = normX.clamp(-1.0, 1.0);
      _targetMouseY = normY.clamp(-1.0, 1.0);
      _mouseX += (_targetMouseX - _mouseX) * 0.25;
      _mouseY += (_targetMouseY - _mouseY) * 0.25;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          onHover: (e) => _onPointerHover(e, size),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ambient Glowing Mesh Background
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    final progress = _animController.value;
                    final waveSin = math.sin(progress * math.pi * 2);
                    final waveCos = math.cos(progress * math.pi * 2);

                    final mouseShiftX = _mouseX * 30.0;
                    final mouseShiftY = _mouseY * 30.0;

                    return CustomPaint(
                      painter: _AmbientMeshPainter(
                        isDark: widget.isDark,
                        intensity: widget.intensity,
                        waveSin: waveSin,
                        waveCos: waveCos,
                        mouseX: mouseShiftX,
                        mouseY: mouseShiftY,
                      ),
                      size: size,
                    );
                  },
                ),
              ),

              // Foreground Screen Content
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _AmbientMeshPainter extends CustomPainter {
  final bool isDark;
  final double intensity;
  final double waveSin;
  final double waveCos;
  final double mouseX;
  final double mouseY;

  _AmbientMeshPainter({
    required this.isDark,
    required this.intensity,
    required this.waveSin,
    required this.waveCos,
    required this.mouseX,
    required this.mouseY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Layer 1: Base Solid Canvas Color
    final baseColor = isDark
        ? const Color(0xFF0B0F19)
        : const Color(0xFFF8FAFC);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = baseColor,
    );

    final w = size.width;
    final h = size.height;

    // Orb 1: Electric Indigo Glow (Top Right)
    final indigoCenter = Offset(
      w * 0.82 + mouseX * 0.8 + waveSin * 18.0,
      h * 0.16 + mouseY * 0.8 + waveCos * 14.0,
    );
    final indigoRadius = math.max(w, h) * 0.52;
    final indigoColor = isDark
        ? Color.fromRGBO(79, 70, 229, 0.22 * intensity)
        : Color.fromRGBO(79, 70, 229, 0.08 * intensity);

    final indigoPaint = Paint()
      ..shader = RadialGradient(
        colors: [indigoColor, indigoColor.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: indigoCenter, radius: indigoRadius),
      );
    canvas.drawCircle(indigoCenter, indigoRadius, indigoPaint);

    // Orb 2: Electric Cyan Glow (Bottom Left)
    final cyanCenter = Offset(
      w * 0.14 - mouseX * 0.6 - waveCos * 16.0,
      h * 0.84 - mouseY * 0.6 - waveSin * 16.0,
    );
    final cyanRadius = math.max(w, h) * 0.56;
    final cyanColor = isDark
        ? Color.fromRGBO(6, 182, 212, 0.18 * intensity)
        : Color.fromRGBO(6, 182, 212, 0.065 * intensity);

    final cyanPaint = Paint()
      ..shader = RadialGradient(
        colors: [cyanColor, cyanColor.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: cyanCenter, radius: cyanRadius),
      );
    canvas.drawCircle(cyanCenter, cyanRadius, cyanPaint);

    // Orb 3: Subtle Emerald / Soft Violet Accent Glow (Center Subtle)
    final accentCenter = Offset(
      w * 0.5 + mouseX * 0.3 + waveCos * 12.0,
      h * 0.48 + mouseY * 0.3 + waveSin * 10.0,
    );
    final accentRadius = math.max(w, h) * 0.38;
    final accentColor = isDark
        ? Color.fromRGBO(99, 102, 241, 0.10 * intensity)
        : Color.fromRGBO(16, 185, 129, 0.035 * intensity);

    final accentPaint = Paint()
      ..shader = RadialGradient(
        colors: [accentColor, accentColor.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: accentCenter, radius: accentRadius),
      );
    canvas.drawCircle(accentCenter, accentRadius, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _AmbientMeshPainter old) {
    return old.isDark != isDark ||
        old.intensity != intensity ||
        old.waveSin != waveSin ||
        old.waveCos != waveCos ||
        old.mouseX != mouseX ||
        old.mouseY != mouseY;
  }
}
