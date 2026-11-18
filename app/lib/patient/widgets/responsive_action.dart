import 'package:material_ui/material_ui.dart';

/// Keeps primary actions full-width on phones and centered on larger screens.
class ResponsiveAction extends StatelessWidget {
  const ResponsiveAction({super.key, this.height, required this.child});

  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    return Align(
      child: SizedBox(
        width: wide ? 320 : double.infinity,
        height: height,
        child: child,
      ),
    );
  }
}
