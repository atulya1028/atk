import 'package:atk/patient/widgets/wellbeing_check_in_widgets.dart';
import 'package:material_ui/material_ui.dart';

class AnxietyWorryPage extends StatelessWidget {
  const AnxietyWorryPage({super.key});

  static const Color teal = WellbeingCheckInScaffold.teal;

  static const List<String> feelings = [
    'Calm',
    'A little worried',
    'Anxious',
    'Very anxious',
    'Restless',
    'Overwhelmed',
  ];

  static const List<String> frequencies = [
    'Rarely',
    'Sometimes',
    'Often',
    'Almost every day',
    'Throughout the day',
  ];

  @override
  Widget build(BuildContext context) {
    return const WellbeingCheckInScaffold(
      topic: 'anxiety_worry',
      appBarTitle: 'Anxiety & Worry',
      stepLabel: '02 / 04',
      progress: 0.5,
      heading: 'Let’s understand your worries.',
      subheading:
          'Take a moment to reflect on how anxiety or worry may be affecting you.',
      firstQuestion: WellbeingQuestionSection(
        responseKey: 'feeling',
        prompt: '1. How often do you feel worried or anxious?',
        options: feelings,
      ),
      secondQuestion: WellbeingQuestionSection(
        responseKey: 'frequency',
        prompt: '2. How often does this feeling occur?',
        options: frequencies,
      ),
      disclaimerIcon: Icons.lock_outline,
      disclaimerText:
          'Your responses are intended to help you reflect on your wellbeing. This is not a medical diagnosis.',
    );
  }
}
