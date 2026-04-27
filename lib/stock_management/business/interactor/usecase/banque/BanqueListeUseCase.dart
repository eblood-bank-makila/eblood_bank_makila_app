

import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/banque/BanqueListeNetworkService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class BanqueListeUseCase{
  BanqueListeNetworkService network;
 UtilisateurLocalService local;


  BanqueListeUseCase(this.network,this.local);


  Future<List<BanqueModele>?> run() async{
    var token=await local.recupererTokenOtp();
    var res=await network.recuperationListeBanque( token?? "");
    if(res != null){
      //var user=BanqueModele.fromJson(res.toJson());
    //  local.saveUser(user);
    }
    return res;
  }
}