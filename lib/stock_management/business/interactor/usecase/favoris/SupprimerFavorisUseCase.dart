import 'package:eblood_bank_mak_app/stock_management/business/model/favoris/FavorisModel.dart';

import '../../../../../utilisateurs/business/service/utilisateurLocalService.dart';
import '../../../model/favoris/SupprimerFavorisModel.dart';
import '../../../service/favoris/FavorisBanqueNetworkService.dart';

class SupprimerFavorisUseCase {
  FavorisBanqueNetworkService network;
  UtilisateurLocalService local;

  SupprimerFavorisUseCase(this.network, this.local);

  Future<SupprimerFavorisModel?> run (String id) async {
     var token =await local.recupererTokenOtp();
    await network.removeFavorite(id, token ?? "");
  }
}
