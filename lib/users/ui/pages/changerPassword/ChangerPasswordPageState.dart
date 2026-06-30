import 'package:eblood_bank_mak_app/users/business/models/changerPassword/PasswordChangerModel.dart';

class ChangerPasswordPageState {
  bool isLoading;
  PasswordChangerModel? password;

  ChangerPasswordPageState({
    this.isLoading = false,
    this.password = null,
    //chargement
  });

  ChangerPasswordPageState copyWith(
          {bool? isLoading, PasswordChangerModel? password}) =>
      ChangerPasswordPageState(
          isLoading: isLoading ?? this.isLoading,
          password: password ?? this.password);
}
