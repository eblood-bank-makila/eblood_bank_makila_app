import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';

class AuthentificationState {
  bool isLoading;
  AuthentificationModel? user;

  AuthentificationState({
    this.isLoading = false,
    this.user = null,
    //chargement
  });

  AuthentificationState copyWith(
          {bool? isLoading, AuthentificationModel? user}) =>
      AuthentificationState(
          isLoading: isLoading ?? this.isLoading, user: user ?? this.user);
}
