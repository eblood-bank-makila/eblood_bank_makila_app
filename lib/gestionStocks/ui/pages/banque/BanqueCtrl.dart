import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/GestionStockInteractor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'BanquePageState.dart';

part 'BanqueCtrl.g.dart';

@Riverpod(keepAlive: true)
class BanqueCtrl extends _$BanqueCtrl {
  @override
  BanquePageState build() {
    return BanquePageState();
  }

  Future<void> listebanque() async {
    // Set loading state to true
    state = state.copyWith(isLoading: true);

    try {
      var usecase = ref.watch(gestionstockInteractorProvider).banquelisteusecase;
      var res = await usecase.run();
      state = state.copyWith(banques: res, isLoading: false);
    } catch (e) {
      // Handle error and set loading to false
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Update favorite status for a specific blood bank in the list
  void updateBankFavoriteStatus(String bankId, bool isFavorite) {
    final updatedBanques = state.banques.map((banque) {
      if (banque.id == bankId) {
        return banque.copyWith(isFavorite: isFavorite);
      }
      return banque;
    }).toList();

    state = state.copyWith(banques: updatedBanques);
  }
}
