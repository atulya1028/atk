/// Initial assessment content (Addiction path).
///
/// Same questions, wording and order as the original app's initial survey:
/// the "Risk assessment" section first, then Identifying data, Psychosocial
/// stressors, Personal & psychiatric history, and Sleep & daily functioning.
///
/// Shared survey item model plus the original question set for reference.
/// Active survey questions are sent by the authenticated API.
library;

enum AnswerKind { choice, number }

class SurveyItem {
  const SurveyItem({
    required this.id,
    required this.text,
    this.kind = AnswerKind.choice,
    this.options = const [],
    this.concern,
    this.min,
    this.max,
    this.section,
  });

  final String id;
  final String text;
  final AnswerKind kind;
  final List<String> options;

  /// The answer that counts towards the DEMO score on this device.
  /// The real score is always calculated by the server.
  final String? concern;

  final int? min;
  final int? max;
  final String? section;
}

const _yesNo = ['Yes', 'No'];

const initialSurveyItems = <SurveyItem>[
  // --- Risk assessment & screening ---
  SurveyItem(
    id: 'q96',
    text:
        'Have you had thoughts of harming yourself or ending your life, '
        'either currently or in the past?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q97',
    text:
        'Has anyone expressed serious concern about your memory, confusion, '
        'or ability to manage daily tasks?',
    options: _yesNo,
    concern: 'Yes',
  ),

  // --- Identifying data ---
  SurveyItem(
    id: 'q1',
    text: 'How old are you (in completed years)?',
    kind: AnswerKind.number,
    min: 1,
    max: 120,
  ),
  SurveyItem(
    id: 'q2',
    text: 'How would you describe your gender?',
    options: ['Male', 'Female', 'Other', 'Prefer not to say'],
  ),
  SurveyItem(
    id: 'q3',
    text: 'What is your current occupation or work status?',
    options: ['Employed', 'Self-employed', 'Student', 'Unemployed', 'Retired'],
  ),
  SurveyItem(
    id: 'q4',
    text: 'What is your current marital or relationship status?',
    options: ['Single', 'Married/partnered', 'Separated/divorced', 'Widowed'],
  ),
  SurveyItem(
    id: 'q5',
    text:
        'How reliable do you feel the information provided by the '
        'informant is?',
    options: ['Reliable', 'Partially reliable', 'Not reliable'],
  ),
  SurveyItem(
    id: 'q6',
    text:
        'What is your relationship to the person providing information '
        '(if applicable)?',
    options: ['Spouse/partner', 'Parent', 'Sibling', 'Child', 'Other'],
  ),

  // --- Psychosocial stressors & protective factors ---
  SurveyItem(
    id: 'q7',
    text: 'Are you currently experiencing any financial stress?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q8',
    text:
        'Are you experiencing any relationship or marital difficulties at '
        'present?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q9',
    text: 'Have you experienced any major life changes recently?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q10',
    text: 'Is there a history of substance use in your family?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q11',
    text: 'Is there any history of psychiatric illness in your family?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q12',
    text:
        'Is there significant conflict or instability within your family '
        'environment?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q13',
    text: 'How would you describe your ability to manage stress?',
    options: ['Good', 'Fair', 'Poor'],
    concern: 'Poor',
  ),
  SurveyItem(
    id: 'q14',
    text: 'Do you usually engage in leisure or recreational activities?',
    options: ['Regular', 'Occasional', 'None'],
    concern: 'None',
  ),
  SurveyItem(
    id: 'q15',
    text: 'Do you feel you receive emotional support from your family?',
    options: _yesNo,
    concern: 'No',
  ),
  SurveyItem(
    id: 'q16',
    text:
        'Do you feel you have a generally positive and supportive peer '
        'group?',
    options: _yesNo,
    concern: 'No',
  ),

  // --- Personal & psychiatric history ---
  SurveyItem(
    id: 'q17',
    text:
        'Have you ever experienced trauma or abuse at any point in your '
        'life?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q18',
    text: 'Have you experienced symptoms of depression or anxiety?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q19',
    text:
        'Have you ever been diagnosed with ADHD or any other mental health '
        'condition?',
    options: _yesNo,
    concern: 'Yes',
  ),
  SurveyItem(
    id: 'q20',
    text:
        'Have you previously received any psychiatric or psychological '
        'treatment?',
    options: _yesNo,
    concern: 'Yes',
  ),

  // --- Sleep & daily functioning ---
  SurveyItem(
    id: 'q21',
    text: 'How would you describe your overall sleep quality?',
    options: ['Good', 'Fair', 'Poor'],
    concern: 'Poor',
  ),
  SurveyItem(
    id: 'q22',
    text: 'How would you describe your appetite recently?',
    options: ['Normal', 'Reduced', 'Increased'],
  ),
  SurveyItem(
    id: 'q23',
    text: 'How would you describe your usual daily routine?',
    options: ['Structured', 'Partially structured', 'Disorganised'],
    concern: 'Disorganised',
  ),
  SurveyItem(
    id: 'q24',
    text: 'How regular has your attendance at work or school been recently?',
    options: ['Regular', 'Irregular', 'Not attending'],
    concern: 'Not attending',
  ),
];
