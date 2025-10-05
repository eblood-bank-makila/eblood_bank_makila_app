import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/apps/services/AuthApi.dart';
import 'package:get_storage/get_storage.dart';
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
      state = state.copyWith(isLoading: true);
      print("⏳ Authentication in progress via AuthApi...");

      final resp = await AuthApi.instance.login(email: username, password: password);

      if (resp['success'] == true) {
        if (resp['requiresMfa'] == true) {
          // Trigger OTP send immediately using default MFA type
          final mfaType = (resp['mfaType'] as String?) ?? 'email';
          // Persist for OTP page display
          final storage = GetStorage();
          await storage.write('pending_login_email', username);
          await storage.write('pending_mfa_type', mfaType);
          await AuthApi.instance.getOtp(mfaType: mfaType);

          // Return a lightweight model carrying only the username to stay compatible
          final model = AuthentificationModel(
            token: 'mfa',
            datetime: DateTime.now(),
            email: username,
          );
          state = state.copyWith(isLoading: false, user: model);
          return model;
        } else {
          // No MFA required, we should have tokens stored; fetch local user if needed
          final model = AuthentificationModel(
            token: 'auth',
            datetime: DateTime.now(),
            email: username,
          );
          state = state.copyWith(isLoading: false, user: model);
          return model;
        }
      }

      state = state.copyWith(isLoading: false);
      return null;
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
