import 'package:atk/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('welcome flow advances and Login Back returns to the intro', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.text('Your companion for a healthier, clearer mind'),
      findsOneWidget,
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Answer simple surveys'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your companion for a healthier, clearer mind'),
      findsOneWidget,
    );
  });
}
