import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import 'package:atk/patient/bloc/survey_question_cubit.dart';
import 'package:atk/patient/models/survey_args.dart';

import 'survey_questions.dart';

/// Survey flow: one API-provided question per page, resuming at the first
/// unanswered question.
///
/// - Tap an option and the survey saves the answer before moving on.
/// - The top shows the percentage and number of saved answers.
/// - The back arrow leaves the survey (answers are saved as you go).
///
/// Pops with the server-calculated score when the last question is answered.
class SurveyQuestionPage extends StatefulWidget {
  const SurveyQuestionPage({super.key, required this.args});
  final SurveyArgs args;

  @override
  State<SurveyQuestionPage> createState() => _SurveyQuestionPageState();
}

class _SurveyQuestionPageState extends State<SurveyQuestionPage> {
  // Colours measured from the original screen.
  static const _teal = Color(0xFF197278);
  static const _bg = Color(0xFFF9FAFB);
  static const _optionBorder = Color(0xFF71797A);

  late final _controller = PageController(
    initialPage: context.read<SurveyQuestionCubit>().state.page.clamp(
      0,
      1 << 30,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SurveyQuestionCubit, SurveyQuestionState>(
      listenWhen: (previous, current) =>
          previous.page != current.page ||
          previous.error != current.error ||
          previous.completed != current.completed,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
          context.read<SurveyQuestionCubit>().clearError();
        }
        if (state.completed) {
          Navigator.pop(context, state.score ?? 0);
        } else if (state.page >= 0 &&
            _controller.hasClients &&
            _controller.page?.round() != state.page) {
          _controller.animateToPage(
            state.page,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      },
      builder: (context, state) => _buildSurvey(context, state),
    );
  }

  Widget _buildSurvey(BuildContext context, SurveyQuestionState state) {
    final cubit = context.read<SurveyQuestionCubit>();
    final items = cubit.items;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${cubit.percent}% Complete · '
                  '${cubit.answeredCount}/${cubit.totalPages} answered',
                  style: const TextStyle(
                    color: _teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  value: cubit.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(_teal),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: state.page == -1
          ? Center(
              child: FilledButton(
                onPressed: state.busy ? null : cubit.finish,
                child: Text(state.busy ? 'Submitting…' : 'Finish assessment'),
              ),
            )
          : PageView.builder(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cubit.totalPages,
              itemBuilder: (context, i) {
                final item = items[i];
                final Widget step;
                if (item.kind == AnswerKind.number) {
                  step = _NumberStep(
                    item: item,
                    initialValue: state.answers[item.id],
                    enabled: !state.busy,
                    error: state.numberError,
                    onInvalid: (value) => cubit.validateNumber(item, value),
                    onSubmit: (value) => cubit.answer(item, value),
                  );
                } else {
                  step = _ChoiceStep(
                    item: item,
                    selected: state.answers[item.id],
                    enabled: !state.busy,
                    onPick: (value) => cubit.answer(item, value),
                  );
                }
                final section = item.section;
                if (widget.args.type != 'INITIAL' ||
                    section == null ||
                    section.isEmpty) {
                  return step;
                }
                final sectionItems = items
                    .where((question) => question.section == section)
                    .toList();
                final position = sectionItems.indexOf(item) + 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        '$section · $position of ${sectionItems.length}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Expanded(child: step),
                  ],
                );
              },
            ),
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({
    required this.item,
    required this.onPick,
    required this.selected,
    required this.enabled,
  });
  final SurveyItem item;
  final ValueChanged<String> onPick;
  final String? selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  Expanded(child: _QuestionText(item.text)),
                  for (final option in item.options)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        // No fixed height: this matches the old option layout.
                        child: OutlinedButton(
                          onPressed: enabled ? () => onPick(option) : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: selected == option
                                ? _SurveyQuestionPageState._teal
                                : Colors.black,
                            side: BorderSide(
                              color: selected == option
                                  ? _SurveyQuestionPageState._teal
                                  : _SurveyQuestionPageState._optionBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberStep extends StatefulWidget {
  const _NumberStep({
    required this.item,
    required this.initialValue,
    required this.enabled,
    required this.error,
    required this.onInvalid,
    required this.onSubmit,
  });

  final SurveyItem item;
  final String? initialValue;
  final bool enabled;
  final String? error;
  final ValueChanged<String> onInvalid;
  final ValueChanged<String> onSubmit;

  @override
  State<_NumberStep> createState() => _NumberStepState();
}

class _NumberStepState extends State<_NumberStep> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null ||
        value < (widget.item.min ?? 0) ||
        value > (widget.item.max ?? 999)) {
      widget.onInvalid(_controller.text);
      return;
    }
    widget.onSubmit(value.toString());
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                Expanded(child: _QuestionText(widget.item.text)),
                TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _continue(),
                  decoration: InputDecoration(
                    hintText: 'Enter number',
                    errorText: widget.error,
                    filled: true,
                    fillColor: _SurveyQuestionPageState._bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ResponsiveAction(
                  child: FilledButton(
                    onPressed: widget.enabled ? _continue : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _SurveyQuestionPageState._teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Next', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuestionText extends StatelessWidget {
  const _QuestionText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            height: 1.3,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
