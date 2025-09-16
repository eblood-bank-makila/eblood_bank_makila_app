import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/GestionStockInteractor.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/FavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/ui/pages/favoris/FavorisStatePage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'FavorisCtrl.g.dart';

@riverpod
class FavorisCtrl extends _$FavorisCtrl {
  @override
  FavorisStatePage build() {
    return FavorisStatePage();
  }




  // Ajout d'un favori
  Future<void> ajouterFavoris(String token, FavorisModele  favorite) async {
    state = state.copyWith(isLoading: true);

    var usecase = ref.watch(gestionstockInteractorProvider);
    var res = await usecase.favorisUseCase.run(favorite);
    state = state.copyWith(isLoading: false);
    return res;
  }

  // // Récupération des favoris
  // Future<List<FavorisRecupererModel>?> recupererFavoris(String token) async {
  //   state = state.copyWith(isLoading: true);
  //
  //     var usecase = ref.watch(gestionstockInteractorProvider);
  //     var favoris = await usecase.recupererFavorisBanqueUseCase.run(token);
  //     state = state.copyWith(isLoading: false, favoris: favoris);
  //     print("fffffffffffffffff $favoris");
  //     return favoris;
  //   }
  // }
  void recupererFavoris() async {
    state = state.copyWith(isLoading: true);

    try {
      var usecase = ref.watch(gestionstockInteractorProvider).recupererFavorisBanqueUseCase;
      var res = await usecase.run();

      // Assurez-vous que `res` est de type List<DactumFavorisModel>
      print('Réponse reçue: $res');

      // Vérifiez si `res` contient des données valides
      if (res != null) {
        state = state.copyWith(favoris: res, isLoading: false);
      } else {
        // Gérer le cas où `res` est nul
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Erreur lors de la récupération des favoris: $e');
      // Gérer l'erreur et mettre à jour l'état
      state = state.copyWith(isLoading: false);
    }
  }
// void recupererFavoris() async {
//
//   state = state.copyWith(isLoading: true);
//   var usecase = ref.watch(gestionstockInteractorProvider).recupererFavorisBanqueUseCase;
//   var res = await usecase.run();
//   print('ffffffffffffffffffffff $res');
//   state=state.copyWith(favoris: res);
// }


  Future<void> supprimerFavoris(FavorisModele data) async{
    var usecase = ref.watch(gestionstockInteractorProvider).supprimerFavorisUseCase;
    var bankid=data.blood_bank_id;
    var res = await usecase.run(bankid);
    // state= state.copyWith(banque: res);
    state= state.copyWith(supprimer_favoris: res);
  }

}

//
//   // Suppression d'un favori
//   Future<void> supprimerFavoris(String token, String favorisId) async {
//     state = state.copyWith(isLoading: true);
//     try {
//       var usecase = ref.watch(favorisUseCaseProvider);
//       await usecase.supprimerFavoris(token, favorisId);
//       state = state.copyWith(isLoading: false, errorMessage: null);
//     } catch (e) {
//       state = state.copyWith(isLoading: false, errorMessage: e.toString());
//     }
//   }
// }
//   void readLocalToken() async {
//     var usecase = ref.watch(utilisateurInteractorProvider).getUserLocalUseCase;
//     var res = await usecase.run();
//     print("token local ${res?.toJson()}");
//   }

