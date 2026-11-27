import 'package:atk/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('welcome flow advances and Login Back returns to the intro', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome to NovTek ATK'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Take Surveys'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Continue your journey to wellness'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to NovTek ATK'), findsOneWidget);
  });

  testWidgets('Doctor sign in link on login opens Doctor Login', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/login');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Doctor sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Doctor Login'), findsOneWidget);
  });
  testWidgets('system Back returns from login to welcome', (tester) async {
    await tester.pumpWidget(const MyApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/login');
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Welcome to NovTek ATK'), findsOneWidget);
  });

  testWidgets('doctor Back returns to the preceding screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/doctorlogin');
    await tester.pumpAndSettle();
    expect(find.text('Doctor Login'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to NovTek ATK'), findsOneWidget);
  });

  testWidgets('Doctor sign in link on login opens Doctor Login', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/login');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Doctor sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Doctor Login'), findsOneWidget);
  });
}
