import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';

abstract class BanqueListeLocalService {
  Future<bool> saveListeBanque(List<BanqueModele> banques);

  Future<List<BanqueModele>?> getBanque();
}
