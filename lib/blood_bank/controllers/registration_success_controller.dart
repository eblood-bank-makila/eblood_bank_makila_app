import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationSuccessState {
  final bool isSuccessful;
  final String message;

  RegistrationSuccessState({
    this.isSuccessful = false,
    this.message = '',
  });

  RegistrationSuccessState copyWith({
    bool? isSuccessful,
    String? message,
  }) {
    return RegistrationSuccessState(
      isSuccessful: isSuccessful ?? this.isSuccessful,
      message: message ?? this.message,
    );
  }
}

class RegistrationSuccessController extends StateNotifier<RegistrationSuccessState> {
  RegistrationSuccessController() : super(RegistrationSuccessState());

  void setSuccess(String message) {
    state = state.copyWith(isSuccessful: true, message: message);
  }

  void reset() {
    state = RegistrationSuccessState();
  }
}

final registrationSuccessProvider = StateNotifierProvider<RegistrationSuccessController, RegistrationSuccessState>((ref) {
  return RegistrationSuccessController();
});