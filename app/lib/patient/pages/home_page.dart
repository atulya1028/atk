import 'package:atk/patient/pages/profile_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/home_cubit.dart';
import 'package:atk/patient/widgets/responsive_content.dart';
import '../../common/widgets/novtek_brand_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.email = ''});

  final String email;

  static const _teal = Color(0xFF197278);
  static const _ink = Color(0xFF283D3B);
  static const _muted = Color(0xFF777D7C);
  static const _canvas = Color(0xFFF7F8F9);

  String get _firstName {
    final localPart = email.split('@').first;
    final name = localPart.replaceAll(RegExp(r'\d'), '');
    final first = name.isEmpty ? 'there' : name;
    return '${first[0].toUpperCase()}${first.substring(1)}';
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<HomeCubit>().logout();
  }

  Future<void> _openAssessment(BuildContext context) async {
    await Navigator.pushNamed<void>(context, '/path_selection');
    if (context.mounted) await context.read<HomeCubit>().loadSurveyStats();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.signedOut != current.signedOut,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error ?? "")));
          context.read<HomeCubit>().clearError();
        }
        if (state.signedOut) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      },
      builder: (context, state) => _buildHome(context, state),
    );
  }

  Widget _buildHome(BuildContext context, HomeState state) {
    return Scaffold(
      backgroundColor: HomePage._canvas,
      body: SafeArea(
        child: IndexedStack(
          index: state.selectedTab,
          children: [
            _dashboard(context, state),
            _progressTab(context, state),
            state.selectedTab == 2
                ? ProfileScreen(onLogout: () => _logout(context))
                : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.selectedTab,
        backgroundColor: Colors.white,
        onDestinationSelected: context.read<HomeCubit>().selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            label: 'View Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _dashboard(BuildContext context, HomeState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final pagePadding = wide ? 32.0 : 20.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    name: _firstName,
                    onAssessment: () => _openAssessment(context),
                    onLogout: () => _logout(context),
                    wide: wide,
                  ),
                  const SizedBox(height: 34),
                  if (wide)
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard.completed(
                            value: state.completedSurveys?.toString() ?? '—',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard.answers(
                            value: state.totalAnswers?.toString() ?? '—',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard.days(
                            value: state.surveyDays?.toString() ?? '—',
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _StatCard.completed(
                      value: state.completedSurveys?.toString() ?? '—',
                    ),
                    const SizedBox(height: 12),
                    _StatCard.answers(
                      value: state.totalAnswers?.toString() ?? '—',
                    ),
                    const SizedBox(height: 12),
                    _StatCard.days(value: state.surveyDays?.toString() ?? '—'),
                  ],
                  const SizedBox(height: 24),
                  const _QuoteCard(),
                  const SizedBox(height: 28),
                  const Text(
                    'Actions',
                    style: TextStyle(
                      color: HomePage._ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AssessmentCard(onTap: () => _openAssessment(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _progressTab(BuildContext context, HomeState state) {
    return ResponsiveContent(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Text(
            'View Progress',
            style: TextStyle(
              color: HomePage._ink,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _StatCard.completed(value: state.completedSurveys?.toString() ?? '—'),
          const SizedBox(height: 12),
          _StatCard.answers(value: state.totalAnswers?.toString() ?? '—'),
          const SizedBox(height: 12),
          _StatCard.days(value: state.surveyDays?.toString() ?? '—'),
          const SizedBox(height: 24),
          _AssessmentCard(onTap: () => _openAssessment(context)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.onAssessment,
    required this.onLogout,
    required this.wide,
  });

  final String name;
  final VoidCallback onAssessment;
  final VoidCallback onLogout;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const NovtekLogoIcon(size: 60),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $name!',
                style: TextStyle(
                  color: HomePage._ink,
                  fontWeight: FontWeight.w700,
                  fontSize: wide ? 30 : 24,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: onAssessment,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1F1),
                    border: Border.all(color: const Color(0xFFB5D1D2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        size: 17,
                        color: HomePage._teal,
                      ),
                      SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Addiction Assessment',
                          style: TextStyle(
                            color: HomePage._teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 7),
                      Icon(Icons.swap_horiz, size: 17, color: HomePage._teal),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Sign out',
          onPressed: onLogout,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFFEBEB),
            foregroundColor: const Color(0xFFE34F4F),
            fixedSize: const Size(54, 54),
          ),
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard._({
    required this.icon,
    required this.valueColor,
    required this.label,
    required this.value,
  });
  const _StatCard.completed({required String value})
    : this._(
        icon: Icons.assignment_turned_in,
        valueColor: HomePage._teal,
        label: 'Surveys Completed',
        value: value,
      );
  const _StatCard.answers({required String value})
    : this._(
        icon: Icons.forum,
        valueColor: const Color(0xFFC9483B),
        label: 'Total Answers',
        value: value,
      );
  const _StatCard.days({required String value})
    : this._(
        icon: Icons.calendar_month,
        valueColor: HomePage._ink,
        label: 'Survey Days',
        value: value,
      );

  final IconData icon;
  final Color valueColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: valueColor.withValues(alpha: 0.1),
            child: Icon(icon, color: valueColor, size: 23),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: HomePage._muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        children: [
          Icon(Icons.format_quote, color: Color(0xFF9BC5C5), size: 34),
          SizedBox(height: 10),
          Text(
            '"You are stronger than you think."',
            style: TextStyle(
              color: HomePage._ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomePage._teal,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0x447FFFFF),
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Initial Assessment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Complete this first step in your journey.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
