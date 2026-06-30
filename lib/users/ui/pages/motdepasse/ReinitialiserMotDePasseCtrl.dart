import 'package:eblood_bank_mak_app/users/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/MotDePasseModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/MotDePasseOublieModele.dart';
import 'package:eblood_bank_mak_app/users/ui/pages/motdepasse/ReinitialiserMotDePasseStatePage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../business/models/reinitialiserPassword/ReinitialiserModele.dart';
import '../../../business/models/reinitialiserPassword/ReinitialiserPasswordModele.dart';

part 'ReinitialiserMotDePasseCtrl.g.dart';

@riverpod
class ReinitialiserMotDePasseCtrl extends _$ReinitialiserMotDePasseCtrl {
  @override
  ReinitialiserMotDePasseStatePage build() {
    return ReinitialiserMotDePasseStatePage();
  }

  //envoi des données vers framework
  Future<MotDePasseModele?> reinitialiser(String username) async {
    var data = MotDePasseOublieModele(
      username: username,
    );
    var usecase =
        ref.watch(utilisateurInteractorProvider).reinitialiserPasswordUseCase;
    state = state.copyWith(isLoading: true);
    var res = await usecase.run(data);
    state = state.copyWith(isLoading: false);
    return res;
  }

  void readLocalToken() async {
    var usecase = ref.watch(utilisateurInteractorProvider).getUserLocalUseCase;
    var res = await usecase.run();
    print("token local ${res?.toJson()}");
  }

  Future<ReinitialiserModele?> reinitialiser_confimer(
      String password, String password2) async {
    var data = ReinitialiserPasswordModele(
      password: password,
      password2: password2,
    );
    var usecase =
        ref.watch(utilisateurInteractorProvider).passwordReinitialiserUseCase;
    state = state.copyWith(isLoading: true);
    var res = await usecase.run(data);
    state = state.copyWith(isLoading: false);
    return res;
  }
}
