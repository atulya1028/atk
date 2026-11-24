import 'package:atk/patient/widgets/responsive_content.dart';
import 'package:material_ui/material_ui.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({
    super.key,
    required this.tab,
    required this.onTabSelected,
    required this.color,
    required this.home,
    required this.progress,
    required this.account,
  });

  final int tab;
  final ValueChanged<int> onTabSelected;
  final Color color;
  final Widget home;
  final Widget progress;
  final Widget account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: IndexedStack(index: tab, children: [home, progress, account]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: color,
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
}

class DashboardActionTile extends StatelessWidget {
  const DashboardActionTile({
    super.key,
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
  final VoidCallback? onTap;

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

class PatientDashboardHome extends StatelessWidget {
  const PatientDashboardHome({
    super.key,
    required this.name,
    required this.category,
    required this.categoryIcon,
    required this.completedSurveys,
    required this.totalAnswers,
    required this.surveyDays,
    required this.quote,
    required this.onLogout,
    required this.actions,
    this.daysLabel = 'Survey Days',
  });

  static const _primary = Color(0xFF197278);
  static const _dark = Color(0xFF283D3B);
  static const _red = Color(0xFFC44536);

  final String? name;
  final String category;
  final IconData categoryIcon;
  final int completedSurveys;
  final int totalAnswers;
  final int surveyDays;
  final String daysLabel;
  final String quote;
  final VoidCallback onLogout;
  final List<Widget> actions;

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

  @override
  Widget build(BuildContext context) {
    final first = _formatFirstName(name);
    return ResponsiveContent(
      maxWidth: 1400,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          // ---- header ----
          Row(
            children: [
              if (ModalRoute.of(context)?.canPop ?? false)
                const BackButton(color: _dark),
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
                      label: category,
                      icon: categoryIcon,
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
                  onPressed: onLogout,
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
                child: DashboardStatTile(
                  icon: Icons.assignment_turned_in,
                  label: 'Surveys Completed',
                  value: '$completedSurveys',
                  color: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardStatTile(
                  icon: Icons.question_answer,
                  label: 'Total Answers',
                  value: '$totalAnswers',
                  color: _red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardStatTile(
                  icon: Icons.calendar_today,
                  label: daysLabel,
                  value: '$surveyDays',
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
                  '"$quote"',
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
          ...actions,
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.onTap,
    required this.label,
    required this.icon,
  });
  final String label;
  final IconData icon;
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Color(0xFF197278)),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
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

class DashboardStatTile extends StatelessWidget {
  const DashboardStatTile({
    super.key,
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
