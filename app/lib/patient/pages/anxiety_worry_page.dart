import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/wellbeing_cubit.dart';
import 'package:atk/patient/widgets/submit_wellbeing_check_in.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

class AnxietyWorryPage extends StatelessWidget {
  const AnxietyWorryPage({super.key});

  static const Color teal = Color(0xFF197278);

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

  static Widget buildOption({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFE5F3F2) : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? teal : const Color(0xFFE1E8E8),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: const Color(0xFF263D3F),
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? teal : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WellbeingCubit, WellbeingState>(
      builder: (context, state) {
        final responses = state.responses;
        final selectedFeeling = responses['feeling'];
        final selectedFrequency = responses['frequency'];
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9FAFB),
            elevation: 0,
            foregroundColor: const Color(0xFF283D3B),
            title: const Text(
              'Anxiety & Worry',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ResponsiveContent(
                maxWidth: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(
                          child: Text(
                            'YOUR WELLNESS JOURNEY',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: teal,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '02 / 04',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: teal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: const LinearProgressIndicator(
                        value: 0.5,
                        minHeight: 6,
                        backgroundColor: Color(0xFFE0EAEA),
                        valueColor: AlwaysStoppedAnimation<Color>(teal),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Let’s understand your worries.',
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF283D3B),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Take a moment to reflect on how anxiety or worry may be affecting you.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF718080),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      '1. How often do you feel worried or anxious?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263D3F),
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...feelings.map(
                      (feeling) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: buildOption(
                          title: feeling,
                          selected: selectedFeeling == feeling,
                          onTap: () {
                            context.read<WellbeingCubit>().select(
                              'feeling',
                              feeling,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      '2. How often does this feeling occur?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263D3F),
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...frequencies.map(
                      (frequency) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: buildOption(
                          title: frequency,
                          selected: selectedFrequency == frequency,
                          onTap: () {
                            context.read<WellbeingCubit>().select(
                              'frequency',
                              frequency,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3F2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_outline, color: teal),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your responses are intended to help you reflect on your wellbeing. This is not a medical diagnosis.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Color(0xFF526C6D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    ResponsiveAction(
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            !state.saving &&
                                selectedFeeling != null &&
                                selectedFrequency != null
                            ? () => submitWellbeingCheckIn(
                                context,
                                'anxiety_worry',
                              )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          disabledBackgroundColor: const Color(0xFFB8CDCE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          state.saving ? 'Saving…' : 'Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
