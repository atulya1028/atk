import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/wellbeing_cubit.dart';
import 'package:atk/patient/widgets/submit_wellbeing_check_in.dart';

class EmotionalWellbeingPage extends StatelessWidget {
  const EmotionalWellbeingPage({super.key});

  static const Color teal = Color(0xFF197278);

  static const List<Map<String, String>> feelings = [
    {'emoji': '😊', 'title': 'Happy'},
    {'emoji': '😌', 'title': 'Calm'},
    {'emoji': '😔', 'title': 'Sad'},
    {'emoji': '😟', 'title': 'Worried'},
    {'emoji': '😶', 'title': 'Confused'},
    {'emoji': '😣', 'title': 'Overwhelmed'},
  ];

  static const List<String> durations = [
    'Just today',
    'A few days',
    'A few weeks',
    'Several months',
    'A long time',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WellbeingCubit, WellbeingState>(
      builder: (context, state) {
        final responses = state.responses;
        final selectedFeeling = responses['feeling'];
        final selectedDuration = responses['duration'];
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),

          appBar: AppBar(
            backgroundColor: const Color(0xFFF9FAFB),
            elevation: 0,
            toolbarHeight: 54,
            leading: BackButton(onPressed: () => Navigator.pop(context)),
            title: Text(
              'Emotional Wellbeing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),

          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;

                // Keep content from becoming excessively wide on tablets.
                final contentWidth = screenWidth >= 680 ? 640.0 : screenWidth;

                return Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(18, 8, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'YOUR WELLBEING JOURNEY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.bold,
                                    color: teal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '01 / 04',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: 0.25,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE6E9E5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                teal,
                              ),
                            ),
                          ),

                          SizedBox(height: 19),

                          // Introduction card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8EFEB), Color(0xFFF3F7F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 47,
                                  width: 47,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: teal,
                                    size: 25,
                                  ),
                                ),

                                SizedBox(width: 13),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Understand your feelings',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF283D3B),
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Take a moment to check in with yourself.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.4,
                                          color: const Color(0xFF4F6463),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 23),

                          // Mood question
                          Text(
                            'How are you feeling?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF283D3B),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Choose the feeling that best describes you.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),

                          SizedBox(height: 13),

                          // Responsive mood cards
                          LayoutBuilder(
                            builder: (context, gridConstraints) {
                              final availableWidth = gridConstraints.maxWidth;

                              final columns = availableWidth < 380 ? 2 : 3;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: feelings.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1.4,
                                    ),
                                itemBuilder: (context, index) {
                                  final feeling = feelings[index];
                                  final title = feeling['title']!;
                                  final selected = selectedFeeling == title;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFE8EFEB)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                        color: selected
                                            ? teal
                                            : const Color(0xFFE9E7E1),
                                        width: selected ? 2 : 1,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: teal.withValues(
                                                  alpha: 0.10,
                                                ),
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(13),
                                      onTap: () {
                                        context.read<WellbeingCubit>().select(
                                          'feeling',
                                          title,
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  feeling['emoji']!,
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                  ),
                                                  child: Text(
                                                    title,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: selected
                                                          ? teal
                                                          : const Color(
                                                              0xFF283D3B,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          if (selected)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Icon(
                                                Icons.check_circle,
                                                color: teal,
                                                size: 13,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          SizedBox(height: 23),

                          // Duration question
                          Text(
                            'How long have you felt this way?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF283D3B),
                            ),
                          ),

                          SizedBox(height: 12),

                          // Duration options
                          ...durations.map((duration) {
                            final selected = selectedDuration == duration;

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  context.read<WellbeingCubit>().select(
                                    'duration',
                                    duration,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFE8EFEB)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? teal
                                          : const Color(0xFFE9E7E1),
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          duration,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: selected
                                                ? teal
                                                : const Color(0xFF283D3B),
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        selected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 19,
                                        color: selected ? teal : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          SizedBox(height: 12),

                          // Continue button
                          ResponsiveAction(
                            height: 49,
                            child: ElevatedButton(
                              onPressed:
                                  state.saving ||
                                      selectedFeeling == null ||
                                      selectedDuration == null
                                  ? null
                                  : () => submitWellbeingCheckIn(
                                      context,
                                      'emotional_wellbeing',
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: teal,
                                disabledBackgroundColor: const Color(
                                  0xFFB9CDCD,
                                ),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.saving ? 'Saving…' : 'Continue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 12),

                          Center(
                            child: Text(
                              'Your feelings matter. Take your time.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
