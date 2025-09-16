



import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';

abstract class BanqueListeNetworkService {
  Future<List<BanqueModele>?> recuperationListeBanque(String authBarear);


}
