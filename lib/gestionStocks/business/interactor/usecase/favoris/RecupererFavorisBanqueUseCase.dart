
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/DactumFavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/favoris/FavorisBanqueNetworkService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';


class  RecupererFavorisBanqueUseCase{

  FavorisBanqueNetworkService network;
  UtilisateurLocalService local;


  RecupererFavorisBanqueUseCase(this.network,this.local);

  Future<List<DactumFavorisModel>?> run() async{
    var token=await local.recupererTokenOtp();
    var favorite=await network.recuperationFavorisBanque(token ?? "");
    return favorite;
  }


  // Future<List<DactumFavorisModel>?> run() async{
  //   var token=await local.recupererTokenOtp();
  //   var favorite=await network.recuperationFavorisBanque(token ?? "");
  //   return favorite;
  // }
}

