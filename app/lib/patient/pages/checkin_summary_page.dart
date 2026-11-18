import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:material_ui/material_ui.dart';
import 'package:atk/patient/widgets/responsive_content.dart';

class CheckInSummaryPage extends StatelessWidget {
  const CheckInSummaryPage({
    super.key,
    required this.category,
    required this.responses,
  });

  final String category;
  final Map<String, String> responses;

  String _label(String value) {
    final spaced = value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    );
    return spaced.isEmpty
        ? spaced
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF197278);
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ResponsiveContent(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your check-in',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF283D3B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Here are the responses you selected.'),
              const SizedBox(height: 20),
              for (final response in responses.entries)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(_label(response.key)),
                    subtitle: Text(response.value),
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: teal,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              ResponsiveAction(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to check-in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
