



import 'package:eblood_bank_mak_app/stock_management/business/model/recherche/DatumRecherchePocheModel.dart';

import '../../../../../utilisateurs/business/service/utilisateurLocalService.dart';
import '../../../service/recherche/RechercheListeNetworkService.dart';

class RechercheListeUseCase{
  RechercheListeNetworkService network;
  UtilisateurLocalService local;


  RechercheListeUseCase(this.network,this.local);


  Future<List<DatumRecherchePocheModel>> run(String search_key, String authBearer ) async{
    var token=await local.recupererTokenOtp();
    var res=await network.recuperationRechercheListeBanque(search_key, token?? "");
    if(res != null){
      //var user=BanqueModele.fromJson(res.toJson());
      //  local.saveUser(user);
    }
    return res;
  }
}