import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/services/api_client.dart';

class AddictionDashboardState {
  const AddictionDashboardState({
    this.tab = 0,
    this.name,
    this.completedSurveys = 0,
    this.totalAnswers = 0,
    this.surveyDays = 0,
    this.initialDone = false,
    this.initialInProgress = false,
    this.mentalDone = false,
    this.mentalInProgress = false,
    this.detailedDone = false,
    this.detailedInProgress = false,
    this.detailedUnlocked = false,
    this.openingSurvey = false,
    this.error,
    this.signedOut = false,
  });

  final int tab;
  final String? name;
  final int completedSurveys;
  final int totalAnswers;
  final int surveyDays;
  final bool initialDone;
  final bool initialInProgress;
  final bool mentalDone;
  final bool mentalInProgress;
  final bool detailedDone;
  final bool detailedInProgress;
  final bool detailedUnlocked;
  final bool openingSurvey;
  final String? error;
  final bool signedOut;

  AddictionDashboardState copyWith({
    int? tab,
    String? name,
    int? completedSurveys,
    int? totalAnswers,
    int? surveyDays,
    bool? initialDone,
    bool? initialInProgress,
    bool? mentalDone,
    bool? mentalInProgress,
    bool? detailedDone,
    bool? detailedInProgress,
    bool? detailedUnlocked,
    bool? openingSurvey,
    String? error,
    bool clearError = false,
    bool? signedOut,
  }) => AddictionDashboardState(
    tab: tab ?? this.tab,
    name: name ?? this.name,
    completedSurveys: completedSurveys ?? this.completedSurveys,
    totalAnswers: totalAnswers ?? this.totalAnswers,
    surveyDays: surveyDays ?? this.surveyDays,
    initialDone: initialDone ?? this.initialDone,
    initialInProgress: initialInProgress ?? this.initialInProgress,
    mentalDone: mentalDone ?? this.mentalDone,
    mentalInProgress: mentalInProgress ?? this.mentalInProgress,
    detailedDone: detailedDone ?? this.detailedDone,
    detailedInProgress: detailedInProgress ?? this.detailedInProgress,
    detailedUnlocked: detailedUnlocked ?? this.detailedUnlocked,
    openingSurvey: openingSurvey ?? this.openingSurvey,
    error: clearError ? null : error ?? this.error,
    signedOut: signedOut ?? this.signedOut,
  );
}

class AddictionDashboardCubit extends Cubit<AddictionDashboardState> {
  AddictionDashboardCubit() : super(const AddictionDashboardState());

  void selectTab(int index) => emit(state.copyWith(tab: index));
  void setOpeningSurvey(bool opening) =>
      emit(state.copyWith(openingSurvey: opening));
  void clearError() => emit(state.copyWith(clearError: true));

  Future<void> logout() async {
    try {
      await ApiClient.logout();
      emit(state.copyWith(signedOut: true));
    } catch (_) {
      emit(state.copyWith(error: 'Could not sign out. Please try again.'));
    }
  }

  Future<void> loadSurveyStatus() async {
    try {
      final data = await ApiClient.surveyStatus();
      if (isClosed) return;
      final initial = data['initial'] as Map<String, dynamic>?;
      final mental = data['mental'] as Map<String, dynamic>?;
      final detailed = data['detailed'] as Map<String, dynamic>?;
      final detailedLatest = detailed?['latest'] as Map<String, dynamic>?;
      final stats = data['stats'] as Map<String, dynamic>;
      emit(
        state.copyWith(
          initialDone:
              initial?['hasCompleted'] == true ||
              initial?['status'] == 'COMPLETED',
          initialInProgress: initial?['status'] == 'IN_PROGRESS',
          mentalDone: mental?['status'] == 'COMPLETED',
          mentalInProgress: mental?['status'] == 'IN_PROGRESS',
          detailedDone: detailedLatest?['status'] == 'COMPLETED',
          detailedInProgress: detailedLatest?['status'] == 'IN_PROGRESS',
          detailedUnlocked: detailed?['unlocked'] as bool? ?? false,
          completedSurveys: stats['completedSurveys'] as int,
          totalAnswers: stats['totalAnswers'] as int,
          surveyDays: stats['surveyDays'] as int,
        ),
      );
    } on ApiException catch (error) {
      if (!isClosed) emit(state.copyWith(error: error.message));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(error: 'Could not load your survey status.'));
      }
    }
  }
}
