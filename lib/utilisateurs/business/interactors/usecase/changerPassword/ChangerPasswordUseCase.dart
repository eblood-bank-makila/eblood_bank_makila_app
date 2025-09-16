import 'package:eblood_bank_mak_app/utilisateurs/business/models/changerPassword/ChangerPasswordModel.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/changerPassword/PasswordChangerModel.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurNetworkService.dart';

class ChangerPasswordUseCase {
  UtilisateurNetworkService network;
  UtilisateurLocalService local;

  ChangerPasswordUseCase(this.network, this.local);

  Future<PasswordChangerModel?> run(ChangerPasswordModel data) async {
    var token = await local.recupererTokenChanger();
    var res = await network.changerPassword(data, token);
    if (res != null) {
      await local.saveTokenCode;
     // var user = OtpCodeReinitialiserModele.fromJson(res.toJson());
      //await local.saveUserCode(user);
    }
    return res;
  }



}
