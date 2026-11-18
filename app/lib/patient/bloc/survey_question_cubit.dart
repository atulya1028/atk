import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/models/survey_args.dart';
import 'package:atk/patient/pages/survey_questions.dart';
import 'package:atk/patient/services/api_client.dart';

class SurveyQuestionState {
  const SurveyQuestionState({
    required this.page,
    required this.answers,
    this.busy = false,
    this.error,
    this.numberError,
    this.completed = false,
    this.score,
  });

  final int page;
  final Map<String, String> answers;
  final bool busy;
  final String? error;
  final String? numberError;
  final bool completed;
  final int? score;

  SurveyQuestionState copyWith({
    int? page,
    Map<String, String>? answers,
    bool? busy,
    String? error,
    bool clearError = false,
    String? numberError,
    bool clearNumberError = false,
    bool? completed,
    int? score,
  }) => SurveyQuestionState(
    page: page ?? this.page,
    answers: answers ?? this.answers,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    numberError: clearNumberError ? null : numberError ?? this.numberError,
    completed: completed ?? this.completed,
    score: score ?? this.score,
  );
}

class SurveyQuestionCubit extends Cubit<SurveyQuestionState> {
  SurveyQuestionCubit(this.args)
    : super(
        SurveyQuestionState(
          page: _firstUnanswered(args.questions, args.answers),
          answers: Map<String, String>.of(args.answers),
        ),
      );

  final SurveyArgs args;
  List<SurveyItem> get items => args.questions;
  int get totalPages => items.length;
  double get progress {
    if (totalPages == 0) return 0;

    final answeredCount = items
        .where((item) => state.answers.containsKey(item.id))
        .length;
    return answeredCount / totalPages;
  }

  int get percent => (progress * 100).round();

  static int _firstUnanswered(
    List<SurveyItem> items,
    Map<String, String> answers,
  ) {
    return items.indexWhere((item) => !answers.containsKey(item.id));
  }

  void validateNumber(SurveyItem item, String rawValue) {
    final value = int.tryParse(rawValue.trim());
    if (value == null || value < (item.min ?? 0) || value > (item.max ?? 999)) {
      emit(
        state.copyWith(
          numberError:
              'Enter a whole number from ${item.min ?? 0} to ${item.max ?? 999}.',
        ),
      );
      return;
    }
    emit(state.copyWith(clearNumberError: true));
    answer(item, value.toString());
  }

  Future<void> answer(SurveyItem item, String value) async {
    if (state.busy ||
        state.completed ||
        state.page < 0 ||
        items[state.page].id != item.id) {
      return;
    }
    final answerValue = item.kind == AnswerKind.number
        ? int.tryParse(value)
        : item.options.indexOf(value);
    if (answerValue == null ||
        (item.kind == AnswerKind.choice && answerValue < 0) ||
        (item.kind == AnswerKind.number &&
            (answerValue < (item.min ?? 0) ||
                answerValue > (item.max ?? 999)))) {
      return;
    }

    emit(state.copyWith(busy: true, clearError: true, clearNumberError: true));
    final updatedAnswers = Map<String, String>.of(state.answers)
      ..[item.id] = value;
    final apiAnswers = <String, int>{};
    for (final question in items) {
      final answer = updatedAnswers[question.id];
      if (answer != null) {
        apiAnswers[question.id] = question.kind == AnswerKind.number
            ? int.parse(answer)
            : question.options.indexOf(answer);
      }
    }

    try {
      await ApiClient.saveSurveyAnswers(args.id, apiAnswers);
      if (isClosed) return;
      final nextPage = _firstUnanswered(items, updatedAnswers);
      emit(
        state.copyWith(
          answers: updatedAnswers,
          busy: nextPage == -1,
          page: nextPage,
        ),
      );
      if (nextPage == -1) await _complete();
    } on ApiException catch (error) {
      if (!isClosed) emit(state.copyWith(busy: false, error: error.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          busy: false,
          error: 'Could not save your answer. Check your connection and try again.',
        ),
      );
    }
  }

  Future<void> finish() async {
    if (state.busy || state.completed || state.page != -1) return;
    emit(state.copyWith(busy: true, clearError: true));
    await _complete();
  }

  Future<void> _complete() async {
    try {
      final score = await ApiClient.completeSurvey(args.id);
      if (!isClosed) {
        emit(state.copyWith(busy: false, completed: true, score: score));
      }
    } on ApiException catch (error) {
      if (!isClosed) emit(state.copyWith(busy: false, error: error.message));
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            busy: false,
            error: 'Could not finish the assessment. Try again.',
          ),
        );
      }
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));
}
