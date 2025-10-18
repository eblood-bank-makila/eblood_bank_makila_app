import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/DactumFavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/FavorisModel.dart';

import '../../model/favoris/SupprimerFavorisModel.dart';

abstract class FavorisBanqueNetworkService {
  Future<Map<String, dynamic>> ajouterFavoris(String authBarear, FavorisModele favorite);

  Future<List<BanqueModele>> recupererFavorites();

  Future<void> supprimerFavorite(String id);

  Future<List<DactumFavorisModel>?> recuperationFavorisBanque(
      String authBarear);

  Future<SupprimerFavorisModel> removeFavorite(String id, String authBearer);
}
