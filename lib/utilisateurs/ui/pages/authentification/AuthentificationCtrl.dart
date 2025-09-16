import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/Authentification.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'AuthentificationState.dart';

part 'AuthentificationCtrl.g.dart';

@riverpod
class AuthentificationCtrl extends _$AuthentificationCtrl {
  @override
  AuthentificationState build() {
    return AuthentificationState();
  }

  //envoi des données vers framework
  Future<AuthentificationModel?> authenticate(
      String username, String password) async {
    try {
      print("🔐 Starting authentication for user: $username");

      var data = AuthenticateRequestBody(
        username: username,
        password: password,
      );

      var usecase =
          ref.read(utilisateurInteractorProvider).authentificationusecase;

      state = state.copyWith(isLoading: true);
      print("⏳ Authentication in progress...");

      var res = await usecase.run(data);

      state = state.copyWith(isLoading: false);
      print("✅ Authentication completed: ${res?.toJson()}");

      return res;
    } catch (e) {
      print("💥 Authentication error: $e");
      state = state.copyWith(isLoading: false);
      return null;
    }
  }

  void readLocalToken() async {
    var usecase = ref.read(utilisateurInteractorProvider).getUserLocalUseCase;
    var res = await usecase.run();
    print("token local ${res?.toJson()}");
  }
}
