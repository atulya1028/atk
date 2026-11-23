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


  static const _quotes = [
    'Small steps every day lead to big changes.',
    'Progress, not perfection.',
    'You are stronger than you think.',
    'Every day is a new beginning.',
    'One day at a time.',
    'Your only limit is you.',
  ];

  late final String _quote = (List<String>.of(_quotes)..shuffle()).first;

  Future<void> _openSurvey(String type) async {
    final cubit = context.read<AddictionDashboardCubit>();
    if (cubit.state.openingSurvey) return;
    cubit.setOpeningSurvey(true);
    try {
      final score = await _takeSurvey(type);
      if (score != null && mounted) {
        await _showScoreDialog(type, score);
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
              child: const Icon(Icons.check_circle_rounded, color: _primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (type == 'INITIAL')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isStage3Unlocked ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isStage3Unlocked ? Icons.lock_open_rounded : Icons.info_outline,
                      color: isStage3Unlocked ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isStage3Unlocked
                            ? 'Score >= 30: Stage 3 Detailed Assessment is unlocked!'
                            : 'Assessment recorded.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isStage3Unlocked ? const Color(0xFF1B5E20) : const Color(0xFFBF360C),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Dashboard'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: IndexedStack(
          index: state.tab,
          children: [
            _homeTab(state),
            _progressTab(state),
            state.tab == 2
                ? ProfileScreen(onLogout: _logout)
                : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: state.tab,
        onTap: context.read<AddictionDashboardCubit>().selectTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'View Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  String _formatFirstName(String? rawInput) {
    if (rawInput == null || rawInput.trim().isEmpty) return 'Participant';
    String raw = rawInput.trim();
    if (raw.contains('@')) raw = raw.split('@').first;
    final parts = raw.split(RegExp(r'[._+\-\s]'));
    String candidate = parts.first.replaceAll(RegExp(r'\d'), '');
    final camelMatch = RegExp(r'^([a-zA-Z]+?)(?=[A-Z])').firstMatch(candidate);
    if (camelMatch != null && camelMatch.group(1)!.isNotEmpty) {
      candidate = camelMatch.group(1)!;
    }
    final lower = candidate.toLowerCase();
    const commonSuffixes = [
      'agrawal',
      'agarwal',
      'jaipur',
      'kumar',
      'singh',
      'sharma',
      'gupta',
      'patel',
      'verma',
      'yadav',
      'shah',
      'jain',
      'mehta',
      'joshi',
    ];
    for (final suffix in commonSuffixes) {
      if (lower.length > suffix.length && lower.endsWith(suffix)) {
        final prefix = lower.substring(0, lower.length - suffix.length);
        if (prefix.length >= 3) {
          candidate = prefix;
          break;
        }
      }
    }
    if (lower.startsWith('atulya')) candidate = 'atulya';
    if (candidate.isEmpty) return 'Participant';
    return '${candidate[0].toUpperCase()}${candidate.substring(1).toLowerCase()}';
  }

  Widget _homeTab(AddictionDashboardState state) {
    final first = _formatFirstName(state.name);
    return ResponsiveContent(
      maxWidth: 1400,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          // ---- header ----
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: _primary,
                child: Icon(
                  Icons.self_improvement,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $first',
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _CategoryChip(
                      onTap: () =>
                          Navigator.pushNamed(context, '/path_selection'),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x1AF44336),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF5350),
                  ),
                  onPressed: _logout,
                  tooltip: 'Log out',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ---- stats ----
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.assignment_turned_in,
                  label: 'Surveys Completed',
                  value: '${state.completedSurveys}',
                  color: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.question_answer,
                  label: 'Total Answers',
                  value: '${state.totalAnswers}',
                  color: _red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_today,
                  label: 'Survey Days',
                  value: '${state.surveyDays}',
                  color: _dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ---- quote ----
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D283D3B),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Color(0x66197278),
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  '"$_quote"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ---- actions ----
          const Text(
            'Actions',
            style: TextStyle(
              color: _dark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._assessmentActions(state),
          if (state.detailedUnlocked) ...[
            const SizedBox(height: 16),
            _ActionTile(
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
      ),
    );
  }

  List<Widget> _assessmentActions(AddictionDashboardState state) => [
    _ActionTile(
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
          : 'Answer questions about substance use and health. You can leave and resume later.',
      color: _primary,
      onTap: () => _openSurvey('INITIAL'),
    ),
    if (state.initialDone) ...[
      const SizedBox(height: 16),
      _ActionTile(
        icon: Icons.psychology_outlined,
        title: state.mentalInProgress
            ? 'Resume Mental Health Assessment'
            : state.mentalDone
            ? 'Retake Mental Health Assessment'
            : 'Start Mental Health Assessment',
        description: state.mentalDone
            ? 'Completed • Score: ${state.mentalScore ?? 0} pts'
            : 'Complete a short mental health check-in.',
        color: _dark,
        onTap: () => _openSurvey('MENTAL'),
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
          _StatTile(
            icon: Icons.assignment_turned_in,
            label: 'Surveys Completed',
            value: '${state.completedSurveys}',
            color: _primary,
          ),
          const SizedBox(height: 12),
          _StatTile(
            icon: Icons.question_answer,
            label: 'Total Answers',
            value: '${state.totalAnswers}',
            color: _red,
          ),
          const SizedBox(height: 12),
          _StatTile(
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
                  score: state.initialDone ? '${state.initialScore ?? 0} pts' : 'Pending',
                  badge: state.detailedUnlocked ? 'Stage 3 Qualified' : (state.initialDone ? 'Screened' : null),
                  color: _primary,
                  isCompleted: state.initialDone,
                ),
                const Divider(height: 24),
                _ScoreRow(
                  title: 'Mental Health Evaluation',
                  score: state.mentalDone ? '${state.mentalScore ?? 0} pts' : (state.mentalInProgress ? 'In Progress' : 'Not Started'),
                  badge: state.mentalDone ? 'Evaluated' : null,
                  color: _dark,
                  isCompleted: state.mentalDone,
                ),
                const Divider(height: 24),
                _ScoreRow(
                  title: 'Detailed Assessment (Stage 3)',
                  score: state.detailedDone ? '${state.detailedScore ?? 0} pts' : (state.detailedUnlocked ? 'Unlocked' : 'Locked'),
                  badge: state.detailedDone ? 'Complete' : (state.detailedUnlocked ? 'Available' : 'Needs Score 30+'),
                  color: state.detailedUnlocked ? const Color(0xFF2E7D32) : Colors.grey,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0x1A197278),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x4D197278)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.health_and_safety, size: 14, color: Color(0xFF197278)),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Addiction Assessment',
                  style: TextStyle(
                    color: Color(0xFF197278),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.swap_horiz, size: 14, color: Color(0xFF197278)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0x33FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
