import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/OtpCodeReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/OtpReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/motdepasse/OtpCodePasswordStatePage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'OtpCodePasswordCtrl.g.dart';

@riverpod
class OtpCodePasswordCtrl extends _$OtpCodePasswordCtrl {
  @override
  OtpCodePasswordStatePage build() {
    return OtpCodePasswordStatePage();
  }

  //envoi des données vers framework
  Future<OtpCodeReinitialiserModele?> otpcode(String code) async {
    var data = OtpReinitialiserModele(
      code: code,
    );
    var usecase =
        ref.watch(utilisateurInteractorProvider).otpCodePasswordUseCase;
    state = state.copyWith(isLoading: true);
    var res = await usecase.run(data);
    state = state.copyWith(isLoading: false);
    return res;
  }

  Future<String?> renvoicodePassword(String token) async {
    var usecase =
        ref.watch(utilisateurInteractorProvider).renvoyerCodePasswordUseCase;
    var res = await usecase.run(token);
    return res;
  }

  Future<String> getLocalToken() async {
    var usecase =
        ref.watch(utilisateurInteractorProvider).recupererTokenPasswordUseCase;
    var res = await usecase.run();
    print("token $res");
    return res;
  }
}
