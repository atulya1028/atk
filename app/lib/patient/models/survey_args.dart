import 'package:atk/patient/pages/survey_questions.dart';

class SurveyArgs {
  const SurveyArgs({
    required this.id,
    required this.type,
    required this.questions,
    this.answers = const {},
  });

  final String id;
  final String type;
  final List<SurveyItem> questions;
  final Map<String, String> answers;

  factory SurveyArgs.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    if (json['id'] is! String ||
        rawQuestions is! List ||
        rawQuestions.isEmpty) {
      throw const FormatException('Invalid survey response.');
    }

    final type = json['type'] as String? ?? 'INITIAL';
    final questions = rawQuestions.map((raw) {
      if (raw is! Map ||
          raw['id'] == null ||
          raw['text'] is! String ||
          raw['options'] is! List) {
        throw const FormatException('Invalid survey question.');
      }
      final options = (raw['options'] as List).map((option) {
        if (option is! Map || option['label'] is! String) {
          throw const FormatException('Invalid survey option.');
        }
        return option['label'] as String;
      }).toList();
      final kind = raw['kind'] == 'number'
          ? AnswerKind.number
          : AnswerKind.choice;
      if (kind == AnswerKind.choice && options.isEmpty) {
        throw const FormatException('Question has no options.');
      }
      return SurveyItem(
        id: raw['id'].toString(),
        text: raw['text'] as String,
        kind: kind,
        options: options,
        min: raw['min'] as int?,
        max: raw['max'] as int?,
        concern: raw['concern'] as String?,
        section: raw['section'] is String ? raw['section'] as String : null,
      );
    }).toList();

    if (type == 'INITIAL') {
      final sections = <String?, List<SurveyItem>>{
        'Risk Assessment & Screening': [],
        'Substance Use History': [],
        'Withdrawal Questions': [],
      };
      for (final question in questions) {
        sections.putIfAbsent(question.section, () => []).add(question);
      }
      questions
        ..clear()
        ..addAll(sections.values.expand((section) => section));
    }

    final answers = <String, String>{};
    final rawAnswers = json['answers'];
    if (rawAnswers is Map) {
      for (final question in questions) {
        final index = rawAnswers[question.id];
        if (question.kind == AnswerKind.number &&
            index is int &&
            index >= (question.min ?? 0) &&
            index <= (question.max ?? 999)) {
          answers[question.id] = index.toString();
        } else if (question.kind == AnswerKind.choice &&
            index is int &&
            index >= 0 &&
            index < question.options.length) {
          answers[question.id] = question.options[index];
        }
      }
    }
    return SurveyArgs(
      id: json['id'] as String,
      type: type,
      questions: questions,
      answers: answers,
    );
  }
}
