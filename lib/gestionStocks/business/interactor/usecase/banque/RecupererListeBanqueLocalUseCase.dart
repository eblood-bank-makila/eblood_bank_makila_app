import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/banque/BanqueListeLocalService.dart';

class RecupererListeBanqueLocalUseCase{
  BanqueListeLocalService local;

  RecupererListeBanqueLocalUseCase(this.local);

  Future<List<BanqueModele>?> run() async{
    var res = await local.getBanque();
    return res;
  }


}