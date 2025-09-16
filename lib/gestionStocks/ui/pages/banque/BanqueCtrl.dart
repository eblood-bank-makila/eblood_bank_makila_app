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
    var usecase = ref.watch(gestionstockInteractorProvider).banquelisteusecase;
    var res = await usecase.run();
    state = state.copyWith(banques: res);
  }
}
