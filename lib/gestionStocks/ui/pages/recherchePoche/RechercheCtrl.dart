import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/GestionStockInteractor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../business/model/recherche/DatumRecherchePocheModel.dart';
import 'RecherchePageState.dart';

part 'RechercheCtrl.g.dart';

@Riverpod(keepAlive: true)
class RechercheCtrl extends _$RechercheCtrl {
  @override
  RecherchePageState build() {
    return RecherchePageState();
  }

  // Future<void> recherchelistebanque() async {
  //   var usecase = ref.watch(gestionstockInteractorProvider).rechercheListeUseCase;
  //   var res = await usecase.run();
  //   state = state.copyWith(banques: res);
  // }

// Dans votre classe RechercheCtrl
  Future<List<DatumRecherchePocheModel>> rechercheListeBanque(String searchKey, String authBearer) async {
    print('🎯 RechercheCtrl: Starting search for "$searchKey"');
    state = state.copyWith(isLoading: true);

    try {
      var usecase = ref.watch(gestionstockInteractorProvider).rechercheListeUseCase;
      print('🔧 RechercheCtrl: Calling use case...');
      var res = await usecase.run(searchKey, authBearer);
      print('📊 RechercheCtrl: Use case returned ${res.length} results');

      state = state.copyWith(recherche: res, isLoading: false);
      return res; // Assurez-vous de retourner les résultats
    } catch (error) {
      print('💥 RechercheCtrl: Erreur lors de la recherche de banques : $error');
      state = state.copyWith(isLoading: false,);
      return []; // Retournez une liste vide en cas d'erreur
    }
  }
}
