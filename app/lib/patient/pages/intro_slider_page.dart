import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/intro_cubit.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

/// Swipeable welcome screens with a centered illustration, text, progress dots,
/// and a next-step button.
class IntroSliderPage extends StatefulWidget {
  const IntroSliderPage({super.key});

  @override
  State<IntroSliderPage> createState() => _IntroSliderPageState();
}

class _IntroSliderPageState extends State<IntroSliderPage> {
  static const _teal = Color(0xFF197278);

  final PageController _controller = PageController();

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.check_rounded,
      title: 'Your companion for a healthier, clearer mind',
      text: 'Take short, confidential check-ins, see your progress over time and connect with support when you need it.',
    ),
    _Slide(
      icon: Icons.assignment_turned_in_rounded,
      title: 'Answer simple surveys',
      text: 'One question at a time. Your answers are saved as you go, so you can stop and continue later.',
    ),
    _Slide(
      icon: Icons.support_agent_rounded,
      title: 'Get support when you need it',
      text: 'If a result needs attention, we can connect you with a doctor in your area.',
    ),
  ];

  void _finish() {
    // '/login' is the login screen route in main.dart
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _next(int page) {
    if (page == _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
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
        final colorScheme = Theme.of(context).colorScheme;
        final isLast = page == _slides.length - 1;
        return Scaffold(
          backgroundColor: colorScheme.surface,
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? _teal : const Color(0xFFC5D6D4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
                  child: ResponsiveContent(
                    maxWidth: 520,
                    child: ResponsiveAction(
                      height: 56,
                      child: FilledButton(
                        onPressed: () => _next(page),
                        style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          isLast ? 'Get started' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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

  static const _teal = Color(0xFF197278);
  static const _ink = Color(0xFF283D3B);
  static const _muted = Color(0xFF4F6463);

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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 64, color: _teal),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String text;
  const _Slide({required this.icon, required this.title, required this.text});
}
