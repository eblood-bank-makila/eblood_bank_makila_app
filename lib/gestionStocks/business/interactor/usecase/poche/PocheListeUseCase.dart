
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/poche/PocheListeNetworkService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class  PocheListeUseCase{

  PocheListeNetworkService network;
  UtilisateurLocalService local;


  PocheListeUseCase(this.network,this.local);

  Future<List<PocheModel>?> run(String _id) async{
    var token=await local.recupererTokenOtp();
    return await network.recuperationListePoche(_id,token ?? "");
  }
}

