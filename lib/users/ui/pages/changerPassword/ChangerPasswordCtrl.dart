import 'package:eblood_bank_mak_app/users/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/users/business/models/changerPassword/ChangerPasswordModel.dart';
import 'package:eblood_bank_mak_app/users/business/models/changerPassword/PasswordChangerModel.dart';
import 'package:eblood_bank_mak_app/users/ui/pages/changerPassword/ChangerPasswordPageState.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ChangerPasswordCtrl.g.dart';

@riverpod
class ChangerPasswordCtrl extends _$ChangerPasswordCtrl {
  @override
  ChangerPasswordPageState build() {
    return ChangerPasswordPageState();
  }

  //envoi des données vers framework
  Future<PasswordChangerModel?> changer(
      String oldpassword, String password, String password2) async {
    var data = ChangerPasswordModel(
      oldpassword: oldpassword,
      password: password,
      password2: password2,
    );
    var usecase =
        ref.watch(utilisateurInteractorProvider).changerPasswordUseCase;
    state = state.copyWith(isLoading: true);
    var res = await usecase.run(data);
    state = state.copyWith(isLoading: false);
    return res;
  }

  void readLocalCodeToken() async {
    var usecase = ref.watch(utilisateurInteractorProvider).getUserLocalUseCase;
    var res = await usecase.run();
    print("token local ${res?.toJson()}");
  }

  Future<String?> renvoicode(String token) async {
    var usecase = ref.watch(utilisateurInteractorProvider).renvoyerCodeUseCase;
    var res = await usecase.run(token);
    return res;
  }

  Future<String> getLocalToken() async {
    var usecase =
        ref.watch(utilisateurInteractorProvider).recuperationTokenUseCase;
    var res = await usecase.run();
    print("token $res");
    return res;
  }
}
