import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/FavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/favoris/FavorisBanqueNetworkService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class FavorisUseCase {
  FavorisBanqueNetworkService network;
  UtilisateurLocalService local;

  FavorisUseCase(this.network, this.local);

  Future<dynamic> run(FavorisModele favorite) async {
    var token = await local.recupererTokenOtp();
    await network.ajouterFavoris(token ?? "", favorite);
  }

// Future<void> call(BloodBank bloodBank) async {
//   final favorite = Favorite(bloodBankId: bloodBank.id);
//   await repository.addFavorite(favorite);
// }
}
