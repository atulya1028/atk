import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:atk/patient/pages/profile_setup_page.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/bloc/addiction_dashboard_cubit.dart';
import 'package:atk/patient/bloc/home_cubit.dart';
import 'package:atk/patient/bloc/intro_cubit.dart';
import 'package:atk/patient/bloc/login_cubit.dart';
import 'package:atk/patient/bloc/wellbeing_cubit.dart';

import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations, GlobalCupertinoLocalizations;

import 'patient/pages/intro_slider_page.dart';
import 'patient/pages/login_page.dart';
import 'patient/pages/mental_health_page.dart';
import 'patient/pages/path_selection_page.dart';
import 'patient/pages/emotional_wellbeing_page.dart';
import 'patient/pages/anxiety_worry_page.dart';
import 'patient/pages/stress_management_page.dart';
import 'patient/pages/sleep_relaxation_page.dart';
import 'patient/pages/home_page.dart';
import 'patient/pages/addiction_assignment_page.dart';
import 'patient/pages/checkin_summary_page.dart';
import 'doctor/doctor_login_page.dart';
import 'doctor/doctor_profile_setup_page.dart';
import 'doctor/doctor_dashboard_page.dart';
import 'admin/admin_login_page.dart';
import 'admin/admin_dashboard_page.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Novtek ATK',

          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [Locale('en', '')],

          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5), // Electric Indigo
              primary: const Color(0xFF4F46E5),
              secondary: const Color(0xFF0F172A), // Slate Navy
              tertiary: const Color(0xFF06B6D4), // Cyan Accent
              surface: const Color(0xFFF8FAFC),
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              iconTheme: IconThemeData(color: Color(0xFF0F172A)),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              margin: EdgeInsets.zero,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF4F46E5), width: 2),
              ),
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter'),
              floatingLabelStyle: const TextStyle(color: Color(0xFF4F46E5), fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          initialRoute: '/',

          routes: {
            '/': (context) => BlocProvider(
              create: (_) => IntroCubit(),
              child: const IntroSliderPage(),
            ),
            '/intro': (context) => BlocProvider(
              create: (_) => IntroCubit(),
              child: const IntroSliderPage(),
            ),
            '/login': (context) => BlocProvider(
              create: (_) => LoginCubit(),
              child: const LoginPage(),
            ),
            '/profile-setup': (context) => const ProfileSetupPage(),
            '/path_selection': (context) => const PathSelectionPage(),
            '/mental_health': (context) => const MentalHealthPage(),
            '/emotional_wellbeing': (context) => BlocProvider(
              create: (_) => WellbeingCubit(),
              child: const EmotionalWellbeingPage(),
            ),
            '/anxiety_worry': (context) => BlocProvider(
              create: (_) => WellbeingCubit(),
              child: const AnxietyWorryPage(),
            ),
            '/stress_management': (context) => BlocProvider(
              create: (_) => WellbeingCubit(),
              child: const StressManagementPage(),
            ),
            '/sleep_relaxation': (context) => BlocProvider(
              create: (_) => WellbeingCubit(),
              child: const SleepRelaxationPage(),
            ),
            '/addiction': (context) => BlocProvider(
              create: (_) => AddictionDashboardCubit()..loadSurveyStatus(),
              child: const AddictionAssignmentPage(),
            ),
            '/anxiety_worry_next': (context) =>
                _checkinSummary(context, 'Anxiety and Worry'),
            '/emotional_wellbeing_next': (context) =>
                _checkinSummary(context, 'Emotional Wellbeing'),
            '/stress_management_next': (context) =>
                _checkinSummary(context, 'Stress Management'),
            '/sleep_relaxation_next': (context) =>
                _checkinSummary(context, 'Sleep and Relaxation'),

            // Temporary placeholders
            '/home': (context) => BlocProvider(
              create: (_) => HomeCubit()..loadSurveyStats(),
              child: HomePage(
                email:
                    ModalRoute.of(context)?.settings.arguments as String? ?? '',
              ),
            ),
            '/doctor': (context) => const DoctorLoginPage(),
            '/doctor-setup': (context) => const DoctorProfileSetupPage(),
            '/doctor-dashboard': (context) => const DoctorDashboardPage(),
            '/admin': (context) => const AdminLoginPage(),
            '/admin-dashboard': (context) => const AdminDashboardPage(),
          },

          onGenerateRoute: (settings) {
            final rawName = settings.name?.trim() ?? '';
            final uri = Uri.tryParse(rawName);
            var path = uri?.path.toLowerCase() ?? '';
            if (path.isEmpty && rawName.isNotEmpty) {
              path = rawName.toLowerCase();
            }
            if (!path.startsWith('/')) {
              path = '/$path';
            }
            if (path.length > 1 && path.endsWith('/')) {
              path = path.substring(0, path.length - 1);
            }

            switch (path) {
              case '/admin':
              case '/admin/login':
              case '/admin-login':
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const AdminLoginPage(),
                );
              case '/admin-dashboard':
              case '/admin/dashboard':
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const AdminDashboardPage(),
                );
              case '/doctor':
              case '/doctor/login':
              case '/doctor-login':
              case '/doctorlogin':
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const DoctorLoginPage(),
                );
              case '/doctor-dashboard':
              case '/doctor/dashboard':
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const DoctorDashboardPage(),
                );
              case '/doctor-setup':
              case '/doctor/setup':
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const DoctorProfileSetupPage(),
                );
              case '/login':
              case '/patient':
              case '/patient/login':
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => BlocProvider(
                    create: (_) => LoginCubit(),
                    child: const LoginPage(),
                  ),
                );
              case '/home':
              case '/patient/home':
              case '/patient/dashboard':
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => BlocProvider(
                    create: (_) => HomeCubit()..loadSurveyStats(),
                    child: HomePage(
                      email: settings.arguments as String? ?? '',
                    ),
                  ),
                );
              default:
                return null;
            }
          },

          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BlocProvider(
                create: (_) => IntroCubit(),
                child: const IntroSliderPage(),
              ),
            );
          },
        );
      },
    );
  }
}

Widget _checkinSummary(BuildContext context, String category) {
  final arguments = ModalRoute.of(context)?.settings.arguments;
  final responses = <String, String>{};
  if (arguments is Map) {
    for (final entry in arguments.entries) {
      responses[entry.key.toString()] = entry.value?.toString() ?? '';
    }
  }
  return CheckInSummaryPage(category: category, responses: responses);
}
