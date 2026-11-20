import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atk/patient/services/api_client.dart';

class LoginState {
  const LoginState({
    this.otpSent = false,
    this.loading = false,
    this.error,
    this.seconds = 0,
    this.profileComplete,
  });

  final bool otpSent;
  final bool loading;
  final String? error;
  final int seconds;
  final bool? profileComplete;

  LoginState copyWith({
    bool? otpSent,
    bool? loading,
    String? error,
    bool clearError = false,
    int? seconds,
    bool? profileComplete,
    bool clearProfileComplete = false,
  }) => LoginState(
    otpSent: otpSent ?? this.otpSent,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    seconds: seconds ?? this.seconds,
    profileComplete: clearProfileComplete
        ? null
        : profileComplete ?? this.profileComplete,
  );
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  Timer? _timer;

  void clearError() => emit(state.copyWith(clearError: true));

  void showError(String message) => emit(state.copyWith(error: message));

  Future<void> sendCode(String email, {String role = 'user'}) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      await ApiClient.sendOtp(email, role: role);
      emit(state.copyWith(loading: false, otpSent: true, seconds: 60));
      _startCountdown();
    } on ApiException catch (error) {
      emit(state.copyWith(loading: false, error: error.message));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: e is ApiException
              ? e.message
              : 'Could not reach ${ApiClient.baseUrl}. Start the API and check the device address.',
        ),
      );
    }
  }

  Future<void> verify(String email, String code, {String role = 'user'}) async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearProfileComplete: true,
      ),
    );
    try {
      final profileComplete = await ApiClient.verifyOtp(email, code, role: role);
      emit(state.copyWith(loading: false, profileComplete: profileComplete));
    } on ApiException catch (error) {
      emit(state.copyWith(loading: false, error: error.message));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception: ', '')
              : 'Could not reach the server. Check your connection and try again.',
        ),
      );
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.seconds <= 1) {
        timer.cancel();
        emit(state.copyWith(seconds: 0));
      } else {
        emit(state.copyWith(seconds: state.seconds - 1));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
