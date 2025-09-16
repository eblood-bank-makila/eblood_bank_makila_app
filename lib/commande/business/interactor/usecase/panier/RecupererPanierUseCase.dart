import '../../../../../utilisateurs/business/service/utilisateurLocalService.dart';
import '../../../model/RecupererPanierResponseModel.dart';
import '../../../service/panier/PanierNetworkService.dart';

class RecupererPanierUseCase {
  PanierNetworkService network;
  UtilisateurLocalService local;

  RecupererPanierUseCase(this.network, this.local);

  Future<RecupererPanierResponseModel> run() async {
    var token = await local.recupererTokenOtp();
    var res = await network.recuperationListePanier(token ?? "");
    if (res != null) {}
    return res;
  }
}
