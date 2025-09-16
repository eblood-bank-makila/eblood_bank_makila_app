import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurNetworkService.dart';

class OtpUtilisateurUseCase {
  UtilisateurNetworkService network;
  UtilisateurLocalService local;

  OtpUtilisateurUseCase(this.network, this.local);

  Future<DatumCodeOtpModele?> run(OtpModele data) async {
    var token = await local.recupererToken();
    var res = await network.verifyOtp(data, token);
    if (res != null) {
      await local.saveTokenCode(res.authBarear);
      var user = DatumCodeOtpModele.fromJson(res.toJson());
      await local.saveUserCode(user);
    }
    return res;
  }
}
