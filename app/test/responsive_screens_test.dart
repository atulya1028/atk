import 'package:atk/main.dart';
import 'package:atk/patient/bloc/survey_question_cubit.dart';
import 'package:atk/patient/models/survey_args.dart';
import 'package:atk/patient/pages/survey_question_page.dart';
import 'package:atk/patient/pages/survey_questions.dart';
import 'package:atk/patient/pages/survey_result_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const viewports = {
    'small phone': (Size(320, 568), 1.0),
    'landscape phone': (Size(568, 320), 1.0),
    'tablet': (Size(768, 1024), 1.0),
    'desktop': (Size(1440, 900), 1.0),
    'phone with large text': (Size(360, 640), 1.6),
  };

  for (final entry in viewports.entries) {
    testWidgets('screens fit a ${entry.key}', (tester) async {
      final (size, textScale) = entry.value;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      FlutterSecureStorage.setMockInitialValues({'atk_access_token': 'test'});

      await http.runWithClient(
        () async {
          await tester.pumpWidget(const MyApp());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Welcome');
          expect(
            tester.getSize(find.widgetWithText(FilledButton, 'Next')).width,
            size.width >= 768 ? 320 : (size.width - 64).clamp(0, 520),
          );
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Welcome second slide',
          );
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Welcome third slide');
          final navigator = tester.state<NavigatorState>(
            find.byType(Navigator),
          );
          for (final route in [
            '/login',
            '/profile-setup',
            '/path_selection',
            '/mental_health',
            '/emotional_wellbeing',
            '/anxiety_worry',
            '/stress_management',
            '/sleep_relaxation',
            '/emotional_wellbeing_next',
            '/anxiety_worry_next',
            '/stress_management_next',
            '/sleep_relaxation_next',
            '/home',
            '/addiction',
          ]) {
            navigator.pushNamed(
              route,
              arguments: route.endsWith('_next')
                  ? {'response': 'A selected answer'}
                  : null,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: route);
            if (route == '/login') {
              await tester.enterText(
                find.byType(TextFormField),
                'test@example.invalid',
              );
              final sendCode = find.text('Send OTP');
              expect(
                tester
                    .getSize(find.widgetWithText(FilledButton, 'Send OTP'))
                    .width,
                size.width >= 768 ? 320 : size.width - 48,
              );
              await tester.ensureVisible(sendCode);
              await tester.tap(sendCode);
              await tester.pumpAndSettle();
              expect(find.text('Enter code'), findsOneWidget);
              expect(
                tester.takeException(),
                isNull,
                reason: 'Verification code',
              );
              tester.view.viewInsets = const FakeViewPadding(bottom: 210);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: 'Keyboard open');
              final verify = find.text('Verify and continue');
              await tester.ensureVisible(verify);
              expect(verify.hitTestable(), findsOneWidget);
              tester.view.resetViewInsets();
              await tester.pumpAndSettle();
            }
            if (route == '/home' || route == '/addiction') {
              for (final tab in ['View Progress', 'Account']) {
                await tester.tap(find.text(tab));
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull, reason: '$route $tab');
              }
              final editProfile = find.text('Edit Profile');
              await tester.ensureVisible(editProfile);
              await tester.tap(editProfile);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: 'Edit Profile');
              expect(find.text('Save Changes'), findsOneWidget);
              navigator.pop();
              await tester.pumpAndSettle();
            }
            navigator.pop();
            await tester.pumpAndSettle();
          }

          for (final item in [
            const SurveyItem(
              id: 'q1',
              text: 'How have you been feeling this week?',
              options: ['Very good', 'Somewhat worried', 'Overwhelmed'],
            ),
            const SurveyItem(
              id: 'q2',
              text: 'How many hours did you sleep?',
              kind: AnswerKind.number,
              min: 0,
              max: 24,
            ),
          ]) {
            final args = SurveyArgs(
              id: 'draft',
              type: 'MENTAL',
              questions: [item],
            );
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider(
                  create: (_) => SurveyQuestionCubit(args),
                  child: SurveyQuestionPage(args: args),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'Survey ${item.kind}',
            );
            navigator.pop();
            await tester.pumpAndSettle();
          }
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => const SurveyResultPage(
                args: ResultArgs(
                  score: 0,
                  unlockScore: 30,
                  isInitial: false,
                  isMental: true,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Survey result');
        },
        () => MockClient((request) async {
          final json = switch (request.url.path) {
            '/user/profile' => '{"email":"test@example.invalid","profile":{"fullName":"Test User","ageGroup":"26-35","gender":"Prefer not to say","occupation":"Test","maritalStatus":"Single","postcode":"012345"}}',
            '/v1/surveys/status' => '{"stats":{"completedSurveys":3,"totalAnswers":23,"surveyDays":2},"detailed":{"unlocked":true},"initial":{"status":"COMPLETED"},"mental":{"status":"COMPLETED"},"standaloneMentalStatus":"COMPLETED"}',
            _ => '{}',
          };
          return http.Response(json, 200);
        }),
      );
    });
  }
}
