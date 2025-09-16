import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/ReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/ReinitialiserPasswordModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurNetworkService.dart';

class PasswordReinitialiserUseCase {
  UtilisateurNetworkService network;
  UtilisateurLocalService local;

  PasswordReinitialiserUseCase(this.network, this.local);


  Future<ReinitialiserModele?> run(ReinitialiserPasswordModele  datas) async {
    var token = await local.recupererTokenPassword();
    var res = await network.passwordReinitialiser(datas, token);
    if (res != null) {
   //  await local.saveTokenPassword(res.data);
      var user = ReinitialiserModele.fromJson(res.toJson());
     // await local.saveUser(user);
    }
    return res;
  }




}
