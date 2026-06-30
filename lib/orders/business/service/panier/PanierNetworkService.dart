import 'package:eblood_bank_mak_app/orders/business/model/PanierModel.dart';
import 'package:eblood_bank_mak_app/orders/business/model/PanierReponseModel.dart';
import 'package:eblood_bank_mak_app/orders/business/model/RecupererPanierResponseModel.dart';

import '../../model/panier/SuppressionPanierResponseModel.dart';

abstract class PanierNetworkService {
  Future<PanierReponseModel?> ajouterPanier(PanierModel data, String authBearer);

  Future<RecupererPanierResponseModel> recuperationListePanier(String authBarear);

  Future<SuppressionPanierResponseModel> supprimerPochePanier(String cartId, String bloodBagId, String authBearer);
}
