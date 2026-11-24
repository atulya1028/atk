import 'package:atk/patient/pages/profile_page.dart';
import 'package:atk/patient/widgets/patient_dashboard.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/survey_question_cubit.dart';
import 'package:atk/patient/models/survey_args.dart';
import 'package:atk/patient/services/api_client.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

import 'survey_question_page.dart';

class MentalHealthPage extends StatefulWidget {
  const MentalHealthPage({super.key});

  @override
  State<MentalHealthPage> createState() => _MentalHealthPageState();
}

class _MentalHealthPageState extends State<MentalHealthPage> {
  static const Color ink = Color(0xFF283D3B);
  static const Color teal = Color(0xFF197278);

  int _tab = 0;
  int? _score;
  String? _name;
  int _completedSurveys = 0;
  int _totalAnswers = 0;
  int _daysActive = 0;
  bool _openingAssessment = false;
  String? _assessmentStatus;

  @override
  void initState() {
    super.initState();
    _loadAssessmentStatus();
    _loadName();
  }

  Future<void> _loadName() async {
    try {
      final account = await ApiClient.getAccountProfile();
      final profile = account['profile'] as Map<String, dynamic>?;
      if (mounted) {
        setState(
          () => _name = (profile?['fullName'] ?? account['email']) as String?,
        );
      }
    } on ApiException {
      // The dashboard can render while account data is unavailable.
    }
  }

  Future<void> _loadAssessmentStatus() async {
    try {
      final status = await ApiClient.surveyStatus();
      final stats = status['stats'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _completedSurveys = stats?['completedSurveys'] as int? ?? 0;
        _totalAnswers = stats?['totalAnswers'] as int? ?? 0;
        _daysActive = stats?['surveyDays'] as int? ?? 0;
        if (!_openingAssessment && _assessmentStatus == null) {
          _assessmentStatus = status['standaloneMentalStatus'] as String?;
          final mental = status['mental'] as Map<String, dynamic>?;
          if (_assessmentStatus == 'COMPLETED') {
            _score = mental?['score'] as int?;
          }
        }
      });
    } on ApiException {
      // The assessment action can still be used if status is unavailable.
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
      setState(() {
        _assessmentStatus = 'COMPLETED';
        _score = completed;
        _tab = 1;
      });
      await _showMentalScoreDialog(completed);
      if (mounted) await _loadAssessmentStatus();
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
              child: const Icon(
                Icons.psychology_rounded,
                color: teal,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mental Health Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await ApiClient.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (_assessmentStatus) {
      'IN_PROGRESS' => 'In progress',
      'COMPLETED' => 'Completed',
      _ => 'Not started',
    };
    return PatientDashboard(
      tab: _tab,
      onTabSelected: (tab) => setState(() => _tab = tab),
      color: teal,
      home: PatientDashboardHome(
        name: _name,
        category: 'Mental Health',
        categoryIcon: Icons.psychology,
        completedSurveys: _completedSurveys,
        totalAnswers: _totalAnswers,
        surveyDays: _daysActive,
        daysLabel: 'Days Active',
        quote: 'One day at a time.',
        onLogout: _logout,
        actions: [
          DashboardActionTile(
            icon: Icons.assignment_turned_in,
            title: _openingAssessment
                ? 'Opening assessment…'
                : switch (_assessmentStatus) {
                    'IN_PROGRESS' => 'Resume Initial Assessment',
                    'COMPLETED' => 'Retake Initial Assessment',
                    _ => 'Start Initial Assessment',
                  },
            description: _assessmentStatus == 'IN_PROGRESS'
                ? 'Continue where you left off.'
                : 'Complete this first step in your journey.',
            color: teal,
            onTap: _openingAssessment ? null : _openAssessment,
          ),
        ],
      ),
      progress: _dashboardList([
        Text('View Progress', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.assignment_turned_in_outlined,
              color: teal,
            ),
            title: const Text('Mental Health Assessment'),
            subtitle: Text(status),
            trailing: _score == null ? null : Text('$_score points'),
          ),
        ),
      ]),
      account: _tab == 2
          ? ProfileScreen(onLogout: _logout)
          : const SizedBox.shrink(),
    );
  }

  Widget _dashboardList(List<Widget> children) {
    return ResponsiveContent(
      maxWidth: 1400,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: children,
      ),
    );
  }
}
