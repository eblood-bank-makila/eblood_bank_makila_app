import 'package:eblood_bank_mak_app/utilisateurs/business/models/notification/DatumNotificationModel.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurNetworkService.dart';
import '../../../models/notification/NotificationResponseModel.dart';

class RecuperationNotifcationUseCase {
  UtilisateurNetworkService network;
  UtilisateurLocalService local;

  RecuperationNotifcationUseCase(this.network, this.local);

  Future<List<DatumNotificationModel>?> run() async {
    var token = await local.recupererTokenOtp();
    var res = await network.recuperationNotification(token ?? "");
    if (res != null) {
      //var user=BanqueModele.fromJson(res.toJson());
      //  local.saveUser(user);
    }
    return res;
  }
}
