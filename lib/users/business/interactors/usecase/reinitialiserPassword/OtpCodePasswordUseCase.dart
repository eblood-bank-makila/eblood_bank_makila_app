import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/OtpCodeReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/OtpReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

class OtpCodePasswordUseCase {
  UtilisateurNetworkService network;
  UtilisateurLocalService local;

  OtpCodePasswordUseCase(this.network, this.local);

  Future<OtpCodeReinitialiserModele?> run(OtpReinitialiserModele data) async {
    var token = await local.recupererTokenPassword();
    var res = await network.verifyOtpPassword(data, token);
    if (res != null) {
      await local.saveTokenPassword(res.data);
      var user = OtpCodeReinitialiserModele.fromJson(res.toJson());
      //await local.saveUserCode(user);
    }
    return res;
  }
}
