import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfilePageState.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "ProfileCtrl.g.dart";

@riverpod
class ProfileCtrl extends _$ProfileCtrl {
  @override
  ProfilePageState build() {
    return ProfilePageState();
  }

  void getUserCode() async {
    var usecase =
        ref.watch(utilisateurInteractorProvider).getUserLocalCodeUseCase;
    var res = await usecase.run();
    state = state.copyWith(user: res);
  }

  Future<bool> disconnect() async {
    var usecase =
        ref.watch(utilisateurInteractorProvider).deconnexionUtilisateurUseCase;
    await usecase.run();

    return true;
  }
}
