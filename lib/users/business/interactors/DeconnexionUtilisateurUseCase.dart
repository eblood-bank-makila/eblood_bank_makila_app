import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

class DeconnexionUtilisateurUseCase {
  UtilisateurLocalService local;
  UtilisateurNetworkService network;

  DeconnexionUtilisateurUseCase(this.network, this.local);

  Future<dynamic> run() async {
    var token = await local.recupererTokenOtp();
    // var res=await network.deconnexion(token);
    var res = await local.deconnexion();
    return res;
  }
}
