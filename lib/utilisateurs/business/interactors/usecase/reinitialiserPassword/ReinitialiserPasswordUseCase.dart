import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/MotDePasseModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/MotDePasseOublieModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurNetworkService.dart';

class ReinitialiserPasswordUseCase {
  UtilisateurNetworkService network;
  UtilisateurLocalService local;

  ReinitialiserPasswordUseCase(this.network, this.local);

  Future<MotDePasseModele?> run(MotDePasseOublieModele data) async {
    var res = await network.reinitialiserPassword(data);
    if (res != null) {
      await local.saveTokenPassword(res.token);
   //   var user = MotDePasseModele.fromJson(res.toJson());
    }
    return res;
  }
}
