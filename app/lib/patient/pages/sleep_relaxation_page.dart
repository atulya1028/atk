import 'package:atk/patient/widgets/wellbeing_check_in_widgets.dart';
import 'package:material_ui/material_ui.dart';

class SleepRelaxationPage extends StatelessWidget {
  const SleepRelaxationPage({super.key});

  static const Color teal = WellbeingCheckInScaffold.teal;

  static const List<String> sleepOptions = [
    'Very good',
    'Good',
    'Average',
    'Poor',
    'Very poor',
  ];

  static const List<String> restOptions = [
    'I wake up feeling refreshed',
    'I sometimes feel rested',
    'I often feel tired',
    'I feel tired most of the day',
    'I rarely feel refreshed',
  ];

  @override
  Widget build(BuildContext context) {
    return const WellbeingCheckInScaffold(
      topic: 'sleep_relaxation',
      appBarTitle: 'Sleep & Relaxation',
      stepLabel: '04 / 04',
      progress: 1.0,
      heading: 'Give yourself time to rest.',
      subheading:
          'Good rest is an important part of wellbeing. Let’s understand your sleep and relaxation habits.',
      firstQuestion: WellbeingQuestionSection(
        responseKey: 'sleepQuality',
        prompt: '1. How would you describe your sleep quality?',
        options: sleepOptions,
      ),
      secondQuestion: WellbeingQuestionSection(
        responseKey: 'morningFeeling',
        prompt: '2. How do you usually feel after waking up?',
        options: restOptions,
      ),
      disclaimerIcon: Icons.nightlight_outlined,
      disclaimerText:
          'Rest and relaxation look different for everyone. These questions are for general wellbeing reflection, not medical diagnosis.',
    );
  }
}
