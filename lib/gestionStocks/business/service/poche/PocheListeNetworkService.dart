import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';

abstract class PocheListeNetworkService {
  Future<List<PocheModel>?> recuperationListePoche(String _id, String authBarear);
}
