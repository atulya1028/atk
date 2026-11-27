import 'package:atk/patient/widgets/patient_dashboard.dart';
import 'package:atk/patient/pages/profile_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/addiction_dashboard_cubit.dart';
import 'package:atk/patient/bloc/survey_question_cubit.dart';
import 'package:atk/patient/models/survey_args.dart';
import 'package:atk/patient/services/api_client.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

import 'survey_question_page.dart';

/// Home screen of the Addiction path: welcome header, three stat cards, a
/// motivation quote, and big action cards for the surveys. A bottom bar has
/// Home, View Progress and Account.
class AddictionAssignmentPage extends StatefulWidget {
  const AddictionAssignmentPage({super.key});

  @override
  State<AddictionAssignmentPage> createState() =>
      _AddictionAssignmentPageState();
}

class _AddictionAssignmentPageState extends State<AddictionAssignmentPage> {
  static const _primary = Color(0xFF197278);
  static const _dark = Color(0xFF283D3B);
  static const _red = Color(0xFFC44536);

  Future<void> _openSurvey(String type) async {
    final cubit = context.read<AddictionDashboardCubit>();
    if (cubit.state.openingSurvey) return;
    cubit.setOpeningSurvey(true);
    try {
      final score = await _takeSurvey(type);
      if (score != null && mounted) {
        await _showScoreDialog(type, score);
        if (type == 'INITIAL' && score > 30 && mounted) {
          Navigator.pushNamed(context, '/mental_health');
        }
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The survey data from the server is invalid.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not connect to the survey service.'),
          ),
        );
      }
    } finally {
      if (!cubit.isClosed) {
        try {
          await cubit.loadSurveyStatus();
        } catch (_) {}
        if (!cubit.isClosed) cubit.setOpeningSurvey(false);
      }
    }
  }

  Future<void> _showScoreDialog(String type, int score) async {
    final title = switch (type) {
      'INITIAL' => 'Initial Assessment Complete',
      'DETAILED' => 'Detailed Assessment Complete',
      'MENTAL' || 'MENTAL_STANDALONE' => 'Mental Health Assessment Complete',
      _ => 'Assessment Complete',
    };
    final shouldProceedToMental = type == 'INITIAL' && score > 30;
    final isStage3Unlocked = score >= 30;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: _primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your assessment responses have been evaluated.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'CLINICAL SCORE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: _dark,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (type == 'INITIAL')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isStage3Unlocked
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isStage3Unlocked
                          ? Icons.lock_open_rounded
                          : Icons.info_outline,
                      color: isStage3Unlocked
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        shouldProceedToMental
                            ? 'Score > 30: Proceeding to Mental Assessment...'
                            : isStage3Unlocked
                            ? 'Score >= 30: Stage 3 Detailed Assessment is unlocked!'
                            : 'Assessment recorded.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isStage3Unlocked
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFBF360C),
                        ),
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
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              shouldProceedToMental
                  ? 'Proceed to Mental Assessment'
                  : 'View Dashboard',
            ),
          ),
        ],
      ),
    );
  }

  Future<int?> _takeSurvey(String type) async {
    final submission = await ApiClient.startSurvey(type);
    if (!mounted) return null;
    final args = SurveyArgs.fromJson(submission);
    return Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => SurveyQuestionCubit(args),
          child: SurveyQuestionPage(args: args),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await context.read<AddictionDashboardCubit>().logout();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddictionDashboardCubit, AddictionDashboardState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.signedOut != current.signedOut,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error ?? "")));
          context.read<AddictionDashboardCubit>().clearError();
        }
        if (state.signedOut) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      },
      builder: (context, state) => _buildDashboard(context, state),
    );
  }

  Widget _buildDashboard(BuildContext context, AddictionDashboardState state) {
    return PatientDashboard(
      tab: state.tab,
      onTabSelected: context.read<AddictionDashboardCubit>().selectTab,
      color: _primary,
      home: _homeTab(state),
      progress: _progressTab(state),
      account: state.tab == 2
          ? ProfileScreen(onLogout: _logout)
          : const SizedBox.shrink(),
    );
  }

  Widget _homeTab(AddictionDashboardState state) => PatientDashboardHome(
    name: state.name,
    category: 'Addiction Assessment',
    categoryIcon: Icons.health_and_safety,
    completedSurveys: state.completedSurveys,
    totalAnswers: state.totalAnswers,
    surveyDays: state.surveyDays,
    daysLabel: 'Days Active',
    quote: 'One day at a time.',
    onLogout: _logout,
    actions: [
      ..._assessmentActions(state),
      if (state.detailedUnlocked) ...[
        const SizedBox(height: 16),
        DashboardActionTile(
          icon: Icons.analytics_rounded,
          title: state.detailedInProgress
              ? 'Resume Detailed Assessment'
              : state.detailedDone
              ? 'Retake Detailed Assessment'
              : 'Start Detailed Assessment',
          description: state.detailedDone
              ? 'Completed • Score: ${state.detailedScore ?? 0} pts'
              : state.detailedInProgress
              ? 'Continue where you left off.'
              : 'Unlocked! Begin your thorough evaluation.',
          color: _dark,
          onTap: () => _openSurvey('DETAILED'),
        ),
      ],
    ],
  );

  List<Widget> _assessmentActions(AddictionDashboardState state) => [
    DashboardActionTile(
      icon: Icons.assignment_turned_in,
      title: state.initialInProgress
          ? 'Resume Initial Assessment'
          : state.initialDone
          ? 'Retake Initial Assessment'
          : 'Start Initial Assessment',
      description: state.initialInProgress
          ? 'Continue where you left off.'
          : state.initialDone
          ? 'Completed • Score: ${state.initialScore ?? 0} pts ${state.detailedUnlocked ? "(Stage 3 Unlocked)" : ""}'
          : 'Complete this first step in your journey.',
      color: _primary,
      onTap: () => _openSurvey('INITIAL'),
    ),
    const SizedBox(height: 16),
    DashboardActionTile(
      icon: Icons.psychology_outlined,
      title: state.mentalInProgress
          ? 'Resume Mental Assessment'
          : state.mentalDone
          ? 'Retake Mental Assessment'
          : 'Start Mental Assessment',
      description: state.mentalInProgress
          ? 'Continue where you left off.'
          : state.mentalDone
          ? 'Completed • Score: ${state.mentalScore ?? 0} pts'
          : 'Complete a short mental health check-in.',
      color: _dark,
      onTap: () => _openSurvey(state.initialDone ? 'MENTAL' : 'MENTAL_STANDALONE'),
    ),
    if (state.detailedUnlocked) ...[
      const SizedBox(height: 16),
      DashboardActionTile(
        icon: Icons.assignment_outlined,
        title: state.detailedInProgress
            ? 'Resume Detailed Assessment'
            : state.detailedDone
            ? 'Retake Detailed Assessment'
            : 'Start Detailed Assessment',
        description: state.detailedInProgress
            ? 'Continue where you left off.'
            : state.detailedDone
            ? 'Completed • Score: ${state.detailedScore ?? 0} pts'
            : 'Clinical addiction evaluation for deep behavioral profiling.',
        color: const Color(0xFF0284C7),
        onTap: () => _openSurvey('DETAILED'),
      ),
    ],
  ];

  Widget _progressTab(AddictionDashboardState state) {
    return ResponsiveContent(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          const Text(
            'View Progress',
            style: TextStyle(
              color: _dark,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          DashboardStatTile(
            icon: Icons.assignment_turned_in,
            label: 'Surveys Completed',
            value: '${state.completedSurveys}',
            color: _primary,
          ),
          const SizedBox(height: 12),
          DashboardStatTile(
            icon: Icons.question_answer,
            label: 'Total Answers',
            value: '${state.totalAnswers}',
            color: _red,
          ),
          const SizedBox(height: 12),
          DashboardStatTile(
            icon: Icons.calendar_today,
            label: 'Survey Days',
            value: '${state.surveyDays}',
            color: _dark,
          ),
          const SizedBox(height: 28),
          const Text(
            'Assessment Scores',
            style: TextStyle(
              color: _dark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _ScoreRow(
                  title: 'Initial Assessment (Stage 2)',
                  score: state.initialDone
                      ? '${state.initialScore ?? 0} pts'
                      : 'Pending',
                  badge: state.detailedUnlocked
                      ? 'Stage 3 Qualified'
                      : (state.initialDone ? 'Screened' : null),
                  color: _primary,
                  isCompleted: state.initialDone,
                ),
                const Divider(height: 24),
                _ScoreRow(
                  title: 'Mental Health Evaluation',
                  score: state.mentalDone
                      ? '${state.mentalScore ?? 0} pts'
                      : (state.mentalInProgress
                            ? 'In Progress'
                            : 'Not Started'),
                  badge: state.mentalDone ? 'Evaluated' : null,
                  color: _dark,
                  isCompleted: state.mentalDone,
                ),
                const Divider(height: 24),
                _ScoreRow(
                  title: 'Detailed Assessment (Stage 3)',
                  score: state.detailedDone
                      ? '${state.detailedScore ?? 0} pts'
                      : (state.detailedUnlocked ? 'Unlocked' : 'Locked'),
                  badge: state.detailedDone
                      ? 'Complete'
                      : (state.detailedUnlocked
                            ? 'Available'
                            : 'Needs Score 30+'),
                  color: state.detailedUnlocked
                      ? const Color(0xFF2E7D32)
                      : Colors.grey,
                  isCompleted: state.detailedDone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Actions',
            style: TextStyle(
              color: _dark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ..._assessmentActions(state),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.title,
    required this.score,
    required this.color,
    required this.isCompleted,
    this.badge,
  });

  final String title;
  final String score;
  final Color color;
  final bool isCompleted;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.pending_outlined,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF283D3B),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 2),
                Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          score,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: isCompleted ? const Color(0xFF283D3B) : Colors.grey,
          ),
        ),
      ],
    );
  }
}
