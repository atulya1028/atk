import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/wellbeing_cubit.dart';
import 'package:atk/patient/widgets/submit_wellbeing_check_in.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

class SleepRelaxationPage extends StatelessWidget {
  const SleepRelaxationPage({super.key});

  static const Color teal = Color(0xFF197278);

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

  static Widget buildOption({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFE5F3F2) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
        final selectedSleep = responses['sleepQuality'];
        final selectedRest = responses['morningFeeling'];
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9FAFB),
            elevation: 0,
            foregroundColor: const Color(0xFF283D3B),
            title: const Text(
              'Sleep & Relaxation',
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
                          '04 / 04',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: teal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 6,
                        backgroundColor: Color(0xFFE0EAEA),
                        valueColor: AlwaysStoppedAnimation<Color>(teal),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Give yourself time to rest.',
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF283D3B),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Good rest is an important part of wellbeing. Let’s understand your sleep and relaxation habits.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF718080),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      '1. How would you describe your sleep quality?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263D3F),
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...sleepOptions.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: buildOption(
                          title: option,
                          selected: selectedSleep == option,
                          onTap: () {
                            context.read<WellbeingCubit>().select(
                              'sleepQuality',
                              option,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      '2. How do you usually feel after waking up?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263D3F),
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...restOptions.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: buildOption(
                          title: option,
                          selected: selectedRest == option,
                          onTap: () {
                            context.read<WellbeingCubit>().select(
                              'morningFeeling',
                              option,
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.nightlight_outlined, color: teal),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Rest and relaxation look different for everyone. These questions are for general wellbeing reflection, not medical diagnosis.',
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
                                selectedSleep != null &&
                                selectedRest != null
                            ? () => submitWellbeingCheckIn(
                                context,
                                'sleep_relaxation',
                              )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          disabledBackgroundColor: const Color(0xFFB8CDCE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
