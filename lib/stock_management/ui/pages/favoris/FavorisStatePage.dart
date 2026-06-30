import 'package:eblood_bank_mak_app/stock_management/business/model/favoris/DactumFavorisModel.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/favoris/FavorisBanqueModel.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/favoris/SupprimerFavorisModel.dart';

class FavorisStatePage {
  bool isLoading;
  final List<DactumFavorisModel> favoris;
  FavorisBanqueModel? favoriss;
  SupprimerFavorisModel? supprimer_favoris;

  FavorisStatePage(
      {this.isLoading = false,
      this.favoris = const [],
      this.favoriss = null,
      this.supprimer_favoris
      //chargement
      });

  FavorisStatePage copyWith(
          {bool? isLoading,
          List<DactumFavorisModel>? favoris,
          FavorisBanqueModel? favoriss,
          SupprimerFavorisModel? supprimer_favoris}) =>
      FavorisStatePage(
          isLoading: isLoading ?? this.isLoading,
          favoris: favoris ?? this.favoris,
          favoriss: favoriss ?? this.favoriss,
          supprimer_favoris: supprimer_favoris ?? this.supprimer_favoris);
}
