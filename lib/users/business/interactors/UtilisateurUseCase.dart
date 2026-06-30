import 'package:eblood_bank_mak_app/users/business/models/authentification/Authentification.dart';
import 'package:eblood_bank_mak_app/users/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

class UtilisateurUseCase {
  UtilisateurNetworkService network;
  UtilisateurLocalService local;

  UtilisateurUseCase(this.network, this.local);

  Future<AuthentificationModel?> run(AuthenticateRequestBody data) async {
    var res = await network.login(data);
    if (res != null) {
      // Only save temporary token for OTP verification
      // DO NOT save user data until OTP is verified
      await local.saveToken(res.token);
      print("🔐 Login successful - Token saved, waiting for OTP verification");
    }
    return res;
  }
}
