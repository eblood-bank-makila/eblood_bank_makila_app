import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/FavorisBanqueModel.dart';

class FavorisPageState {
  bool isLoading;
  FavorisBanqueModel? favoriss;



  FavorisPageState({
    this.isLoading = false,
    this.favoriss = null,
    //chargement
  });

  FavorisPageState copyWith({bool? isLoading, FavorisBanqueModel? favoriss,}) =>
      FavorisPageState(
          isLoading: isLoading ?? this.isLoading,
          favoriss: favoriss ?? this.favoriss,


      );
}
