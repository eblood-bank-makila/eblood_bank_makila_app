// notification_use_case.dart

import 'package:eblood_bank_mak_app/users/business/service/utilisateurNetworkService.dart';

import '../../../models/notification/SuppressionDatumNotificationModel.dart';
import '../../../models/notification/SuppressionResponseNotificationModel.dart';
import '../../../service/utilisateurLocalService.dart';

class SuppressionNotificationUseCase {
  final UtilisateurNetworkService network;
  UtilisateurLocalService local;

  SuppressionNotificationUseCase(this.network, this.local);

  Future<SuppressionDatumNotificationModel> run(String _id) async {
    var token = await local.recupererTokenOtp();
    return await network.suppressionNotification(_id, token ?? "");
  }
}
