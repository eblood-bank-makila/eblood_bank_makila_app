import 'package:eblood_bank_mak_app/stock_management/business/model/favoris/FavorisModel.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/favoris/FavorisBanqueNetworkService.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

class FavorisUseCase {
  FavorisBanqueNetworkService network;
  UtilisateurLocalService local;

  FavorisUseCase(this.network, this.local);

  Future<Map<String, dynamic>> run(FavorisModele favorite) async {
    var token = await local.recupererTokenOtp();
    return await network.ajouterFavoris(token ?? "", favorite);
  }

// Future<void> call(BloodBank bloodBank) async {
//   final favorite = Favorite(bloodBankId: bloodBank.id);
//   await repository.addFavorite(favorite);
// }
}
