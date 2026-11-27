import 'package:atk/patient/widgets/wellbeing_check_in_widgets.dart';
import 'package:material_ui/material_ui.dart';

class StressManagementPage extends StatelessWidget {
  const StressManagementPage({super.key});

  static const Color teal = WellbeingCheckInScaffold.teal;

  static const List<String> stressLevels = [
    'Not stressed',
    'A little stressed',
    'Moderately stressed',
    'Very stressed',
    'Extremely stressed',
  ];

  static const List<String> copingMethods = [
    'Talking to someone',
    'Taking a break',
    'Exercise or walking',
    'Listening to music',
    'Meditation or breathing',
    'I am not sure',
  ];

  @override
  Widget build(BuildContext context) {
    return const WellbeingCheckInScaffold(
      topic: 'stress_management',
      appBarTitle: 'Stress Management',
      stepLabel: '03 / 04',
      progress: 0.75,
      heading: 'Let’s make stress easier to manage.',
      subheading:
          'Understanding what causes stress and how you respond can be a helpful first step.',
      firstQuestion: WellbeingQuestionSection(
        responseKey: 'stressLevel',
        prompt: '1. How would you describe your current stress level?',
        options: stressLevels,
      ),
      secondQuestion: WellbeingQuestionSection(
        responseKey: 'copingMethod',
        prompt: '2. What usually helps you deal with stress?',
        options: copingMethods,
      ),
      disclaimerIcon: Icons.favorite_outline,
      disclaimerText:
          'Small steps toward relaxation can make everyday challenges easier to approach. This experience is not a medical diagnosis.',
    );
  }
}
