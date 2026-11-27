import 'package:atk/patient/bloc/wellbeing_cubit.dart';
import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:atk/patient/widgets/responsive_content.dart';
import 'package:atk/patient/widgets/submit_wellbeing_check_in.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Selectable radio-style card used across wellbeing check-in screens.
class WellbeingOptionTile extends StatelessWidget {
  const WellbeingOptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.accentColor = const Color(0xFF197278),
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
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
              color: selected ? accentColor : const Color(0xFFE1E8E8),
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
                color: selected ? accentColor : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Configuration for a two-question wellbeing check-in screen.
class WellbeingQuestionSection {
  const WellbeingQuestionSection({
    required this.responseKey,
    required this.prompt,
    required this.options,
  });

  final String responseKey;
  final String prompt;
  final List<String> options;
}

/// Shared layout and submission flow for wellbeing check-in pages.
class WellbeingCheckInScaffold extends StatelessWidget {
  const WellbeingCheckInScaffold({
    super.key,
    required this.topic,
    required this.appBarTitle,
    required this.stepLabel,
    required this.progress,
    required this.heading,
    required this.subheading,
    required this.firstQuestion,
    required this.secondQuestion,
    required this.disclaimerIcon,
    required this.disclaimerText,
  });

  static const Color teal = Color(0xFF197278);

  final String topic;
  final String appBarTitle;
  final String stepLabel;
  final double progress;
  final String heading;
  final String subheading;
  final WellbeingQuestionSection firstQuestion;
  final WellbeingQuestionSection secondQuestion;
  final IconData disclaimerIcon;
  final String disclaimerText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WellbeingCubit, WellbeingState>(
      builder: (context, state) {
        final responses = state.responses;
        final firstValue = responses[firstQuestion.responseKey];
        final secondValue = responses[secondQuestion.responseKey];
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9FAFB),
            elevation: 0,
            foregroundColor: const Color(0xFF283D3B),
            title: Text(
              appBarTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
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
                      children: [
                        const Expanded(
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
                        const SizedBox(width: 8),
                        Text(
                          stepLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE0EAEA),
                        valueColor: const AlwaysStoppedAnimation<Color>(teal),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      heading,
                      style: const TextStyle(
                        fontSize: 27,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF283D3B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subheading,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF718080),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ..._buildQuestionSection(
                      context,
                      firstQuestion,
                      firstValue,
                    ),
                    const SizedBox(height: 24),
                    ..._buildQuestionSection(
                      context,
                      secondQuestion,
                      secondValue,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3F2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(disclaimerIcon, color: teal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              disclaimerText,
                              style: const TextStyle(
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
                                firstValue != null &&
                                secondValue != null
                            ? () => submitWellbeingCheckIn(context, topic)
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
                          style: const TextStyle(
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

  List<Widget> _buildQuestionSection(
    BuildContext context,
    WellbeingQuestionSection section,
    String? selectedValue,
  ) {
    return [
      Text(
        section.prompt,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF263D3F),
        ),
      ),
      const SizedBox(height: 14),
      ...section.options.map(
        (option) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: WellbeingOptionTile(
            title: option,
            selected: selectedValue == option,
            accentColor: teal,
            onTap: () => context.read<WellbeingCubit>().select(
              section.responseKey,
              option,
            ),
          ),
        ),
      ),
    ];
  }
}
