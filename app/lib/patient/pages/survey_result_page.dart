import 'package:material_ui/material_ui.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

class ResultArgs {
  const ResultArgs({
    required this.score,
    required this.unlockScore,
    required this.isInitial,
    this.isMental = false,
  });
  final int score;
  final int unlockScore;
  final bool isInitial;
  final bool isMental;
}

class SurveyResultPage extends StatelessWidget {
  const SurveyResultPage({super.key, required this.args});
  final ResultArgs args;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your result')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ResponsiveContent(
          maxWidth: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_outline,
                size: 52,
                color: Color(0xFF197278),
              ),
              const SizedBox(height: 16),
              Text(
                args.isMental
                    ? 'Mental Health Assessment complete'
                    : 'Your score: ${args.score}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                args.isMental
                    ? 'Thank you for completing the mental health check-in.'
                    : args.isInitial
                    ? (args.score >= args.unlockScore
                          ? 'Your detailed survey is now unlocked.'
                          : 'You can retake this check-in whenever you need.')
                    : 'Thank you for completing the detailed check-in.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
