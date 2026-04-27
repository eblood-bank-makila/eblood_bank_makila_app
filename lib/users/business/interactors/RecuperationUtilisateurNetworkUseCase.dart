import 'package:eblood_bank_mak_app/users/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

class RecuperationUtilisateurNetworkUseCase{
  UtilisateurNetworkService network;
  UtilisateurLocalService local;


  RecuperationUtilisateurNetworkUseCase(this.network,this.local);

  Future<AuthentificationModel?> run() async{
    var token=await local.recupererToken();
    var res=await network.recuperationUtilisateur(token);
    if(res != null){
      var user=AuthentificationModel.fromJson(res.toJson());
      await local.saveUser(user);
    }
    return res;
  }
}