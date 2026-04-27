import 'package:eblood_bank_mak_app/stock_management/business/interactor/GestionStockInteractor.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/stock_management/ui/pages/poche/PocheState.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "PocheController.g.dart";

@riverpod
class PocheController extends _$PocheController {
  @override
  PocheState build() {
    return PocheState();
  }

// void recupererData() async {
//   var usecase = ref.watch(gestionstockInteractorProvider).pochelisteusecase;
//   var res = await usecase.run();
//   state = state.copyWith(poches: res);
// }


void setBanque(BanqueModele data) async{
  var usecase = ref.watch(gestionstockInteractorProvider).pochelisteusecase;
  var bankid=data.id;
  var res = await usecase.run(bankid);
 // state= state.copyWith(banque: res);
  state= state.copyWith(poches: res);
}


}
