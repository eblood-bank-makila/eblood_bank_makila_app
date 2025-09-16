import '../../../../../utilisateurs/business/service/utilisateurLocalService.dart';
import '../../../model/panier/SuppressionPanierResponseModel.dart';
import '../../../service/panier/PanierNetworkService.dart';

class SupprimerPochePanierUseCase {
  PanierNetworkService network;
  UtilisateurLocalService local;

  SupprimerPochePanierUseCase(this.network, this.local);

  Future<SuppressionPanierResponseModel?> run(String cartId, String bloodBagId) async {
    var token = await local.recupererTokenOtp();
    var result = await network.supprimerPochePanier(cartId, bloodBagId, token ?? "");
    return result;
  }
}
