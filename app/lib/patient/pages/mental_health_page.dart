import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/survey_question_cubit.dart';
import 'package:atk/patient/models/survey_args.dart';
import 'package:atk/patient/services/api_client.dart';
import 'package:atk/patient/widgets/responsive_content.dart';
import '../../common/widgets/novtek_brand_widgets.dart';

import 'survey_question_page.dart';

class MentalHealthPage extends StatefulWidget {
  const MentalHealthPage({super.key});

  @override
  State<MentalHealthPage> createState() => _MentalHealthPageState();
}

class _MentalHealthPageState extends State<MentalHealthPage> {
  static const Color ink = Color(0xFF283D3B);
  static const Color teal = Color(0xFF197278);
  static const Color background = Color(0xFFF9FAFB);

  bool _openingAssessment = false;
  String? _assessmentStatus;

  @override
  void initState() {
    super.initState();
    _loadAssessmentStatus();
  }

  Future<void> _loadAssessmentStatus() async {
    try {
      final status = await ApiClient.surveyStatus();
      if (mounted && !_openingAssessment && _assessmentStatus == null) {
        setState(
          () => _assessmentStatus = status['standaloneMentalStatus'] as String?,
        );
      }
    } catch (_) {
      // Starting the assessment still works if the status request fails.
    }
  }

  Future<void> _openAssessment() async {
    setState(() => _openingAssessment = true);
    try {
      final response = await ApiClient.startSurvey('MENTAL_STANDALONE');
      if (!mounted) return;
      final args = SurveyArgs.fromJson(response);
      setState(() => _assessmentStatus = 'IN_PROGRESS');
      final completed = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => SurveyQuestionCubit(args),
            child: SurveyQuestionPage(args: args),
          ),
        ),
      );
      if (!mounted || completed == null) return;
      setState(() => _assessmentStatus = 'COMPLETED');
      await _showMentalScoreDialog(completed);
      if (mounted) {
        Navigator.of(context).popUntil(ModalRoute.withName('/home'));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The assessment data is invalid.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to the assessment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingAssessment = false);
    }
  }

  Future<void> _showMentalScoreDialog(int score) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, color: teal, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mental Health Score',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your mental health assessment has been calculated.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: teal.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'ASSESSMENT SCORE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: teal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: NovtekInteractiveBackground(
        isDark: false,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),

                ResponsiveContent(
                  maxWidth: 1040,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR WELLBEING',
                          style: TextStyle(
                            color: teal,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Make space for\nyour mind.',
                          style: TextStyle(
                            color: ink,
                            fontSize: 34,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                      const SizedBox(height: 12),

                      const Text(
                        'A little understanding can be the beginning '
                        'of meaningful change. Choose what you would '
                        'like to focus on today.',
                        style: TextStyle(
                          color: Color(0xFF747C83),
                          fontSize: 14,
                          height: 1.65,
                        ),
                      ),

                      const SizedBox(height: 28),

                      FilledButton(
                        onPressed: _openingAssessment ? null : _openAssessment,
                        child: Text(
                          _openingAssessment
                              ? 'Opening assessment…'
                              : switch (_assessmentStatus) {
                                  'IN_PROGRESS' =>
                                    'Resume Mental Health Assessment',
                                  'COMPLETED' =>
                                    'Retake Mental Health Assessment',
                                  _ => 'Start Mental Health Assessment',
                                },
                        ),
                      ),

                      const SizedBox(height: 28),

                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Explore your wellbeing',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                          Text(
                            '04 TOPICS',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 17),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 680 ? 2 : 1;
                          final cardWidth = columns == 1
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 14) / 2;
                          return Wrap(
                            spacing: 14,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _TopicCard(
                                  number: '01',
                                  title: 'Emotional Wellbeing',
                                  description:
                                      'Understand your emotions and mood.',
                                  icon: Icons.favorite_outline_rounded,
                                  color: const Color(0xFFE8EFEB),
                                  iconColor: teal,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/emotional_wellbeing',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _TopicCard(
                                  number: '02',
                                  title: 'Anxiety & Worry',
                                  description:
                                      'Explore feelings of worry and anxiety.',
                                  icon: Icons.spa_outlined,
                                  color: const Color(0xFFDDEDE9),
                                  iconColor: teal,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/anxiety_worry',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _TopicCard(
                                  number: '03',
                                  title: 'Stress Management',
                                  description:
                                      'Explore ways to manage everyday stress.',
                                  icon: Icons.waves_rounded,
                                  color: const Color(0xFFE8EFEB),
                                  iconColor: teal,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/stress_management',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _TopicCard(
                                  number: '04',
                                  title: 'Sleep & Relaxation',
                                  description:
                                      'Learn about your sleep and rest.',
                                  icon: Icons.nights_stay_outlined,
                                  color: const Color(0xFFDDEDE9),
                                  iconColor: teal,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/sleep_relaxation',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 22),

                      _buildPrivacyCard(),

                      const SizedBox(height: 25),

                      const Center(
                        child: Text(
                          'TAKE YOUR TIME. YOU MATTER.',
                          style: TextStyle(
                            color: Color(0xFF92999C),
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 22, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFE8EFEB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          BackButton(color: ink, onPressed: () => Navigator.pop(context)),

          const Expanded(
            child: Text(
              'NOVTEK ATK',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
                color: teal,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: teal,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFEB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: teal, size: 25),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A safe space for you',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your mental wellbeing is important. '
                  'This experience is for general support '
                  'and is not a medical diagnosis.',
                  style: TextStyle(
                    color: Color(0xFF687777),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _TopicCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFECEBE6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 57,
                  height: 57,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: iconColor, size: 27),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOPIC $number',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF202C3C),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF858B91),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF197278),
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
