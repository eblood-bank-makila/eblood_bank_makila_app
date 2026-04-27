



import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';

abstract class BanqueListeNetworkService {
  Future<List<BanqueModele>?> recuperationListeBanque(String authBarear);


}
