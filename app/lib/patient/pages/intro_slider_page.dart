import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/intro_cubit.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

import '../../common/widgets/novtek_brand_widgets.dart';

/// Swipeable welcome screens with a centered illustration, text, progress dots,
/// and a next-step button.
class IntroSliderPage extends StatefulWidget {
  const IntroSliderPage({super.key});

  @override
  State<IntroSliderPage> createState() => _IntroSliderPageState();
}

class _IntroSliderPageState extends State<IntroSliderPage> {
  static const _indigo = Color(0xFF4F46E5);
  static const _cyan = Color(0xFF06B6D4);

  final PageController _controller = PageController();

  static const _slides = <_Slide>[
    _Slide(
      useLogo: true,
      title: 'Welcome to NovTek ATK',
      text: 'Your companion on the journey to a healthier, addiction free life.',
    ),
    _Slide(
      icon: Icons.assignment_turned_in_rounded,
      title: 'Take Surveys',
      text: 'Answer simple, confidential surveys to track your progress and get insights.',
    ),
    _Slide(
      icon: Icons.health_and_safety_rounded,
      title: 'Get support when you need it',
      text: 'Access resources and suppport to help you stay on track and motivaed.`',
    ),
  ];

  void _finish() {
    Navigator.pushNamed(context, '/login');
  }

  void _next(int page) {
    if (page == _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntroCubit, int>(
      builder: (context, page) {
        final isLast = page == _slides.length - 1;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: context.read<IntroCubit>().showPage,
                    itemBuilder: (context, i) => ResponsiveContent(
                      maxWidth: 760,
                      child: _SlideView(slide: _slides[i]),
                    ),
                  ),
                ),

                // Active Indicator Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: active
                            ? const LinearGradient(
                                colors: [_indigo, _cyan],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: active ? null : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),

                // CTA Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                  child: ResponsiveContent(
                    maxWidth: 520,
                    child: ResponsiveAction(
                      height: 56,
                      child: FilledButton(
                        onPressed: () => _next(page),
                        style: FilledButton.styleFrom(
                          backgroundColor: _indigo,
                          elevation: 4,
                          shadowColor: _indigo.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isLast ? 'Get started' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
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
      },
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  static const _indigo = Color(0xFF4F46E5);
  static const _slate = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (slide.useLogo)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _indigo.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const NovtekLogoIcon(size: 88),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_indigo, Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _indigo.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(slide.icon, size: 56, color: Colors.white),
            ),
          const SizedBox(height: 36),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _slate,
              fontSize: 26,
              height: 1.25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 15, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData? icon;
  final bool useLogo;
  final String title;
  final String text;
  const _Slide({
    this.icon,
    this.useLogo = false,
    required this.title,
    required this.text,
  });
}
