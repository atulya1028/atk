import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/services/api_client.dart';

class HomeState {
  const HomeState({
    this.selectedTab = 0,
    this.completedSurveys,
    this.totalAnswers,
    this.surveyDays,
    this.loading = true,
    this.loggingOut = false,
    this.error,
    this.signedOut = false,
  });

  final int selectedTab;
  final int? completedSurveys;
  final int? totalAnswers;
  final int? surveyDays;
  final bool loading;
  final bool loggingOut;
  final String? error;
  final bool signedOut;

  HomeState copyWith({
    int? selectedTab,
    int? completedSurveys,
    int? totalAnswers,
    int? surveyDays,
    bool? loading,
    bool? loggingOut,
    String? error,
    bool clearError = false,
    bool? signedOut,
  }) => HomeState(
    selectedTab: selectedTab ?? this.selectedTab,
    completedSurveys: completedSurveys ?? this.completedSurveys,
    totalAnswers: totalAnswers ?? this.totalAnswers,
    surveyDays: surveyDays ?? this.surveyDays,
    loading: loading ?? this.loading,
    loggingOut: loggingOut ?? this.loggingOut,
    error: clearError ? null : error ?? this.error,
    signedOut: signedOut ?? this.signedOut,
  );
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void selectTab(int index) => emit(state.copyWith(selectedTab: index));
  void clearError() => emit(state.copyWith(clearError: true));

  Future<void> loadSurveyStats() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final data = await ApiClient.surveyStatus();
      final stats = data['stats'] as Map<String, dynamic>;
      emit(
        state.copyWith(
          loading: false,
          completedSurveys: stats['completedSurveys'] as int,
          totalAnswers: stats['totalAnswers'] as int,
          surveyDays: stats['surveyDays'] as int,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(loading: false, error: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Could not load your survey progress.',
        ),
      );
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(loggingOut: true, clearError: true));
    try {
      await ApiClient.logout();
      emit(state.copyWith(loggingOut: false, signedOut: true));
    } catch (_) {
      emit(
        state.copyWith(
          loggingOut: false,
          error: 'Could not sign out. Please try again.',
        ),
      );
    }
  }
}
