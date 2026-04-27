import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementModel.dart';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementResponseModel.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaiementNetworkService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class AjouterPochePaiementUseCase {
  PaiementNetworkService network;
  UtilisateurLocalService local;

  AjouterPochePaiementUseCase(this.network, this.local);

  Future<PaiementResponseModel?> run(
    DatumModel panier_id, {
    String? phoneNumber,
    String? transactionalCurrencyId,
    String? requestFor,
    String? requestReason,
    String? patientId,
    String? requestType,
    String? urgencyLevel,
  }) async {
    var token = await local.recupererTokenOtp();

    var paiementData = PaiementModel(
      cartId: panier_id.id,
      phoneNumber: phoneNumber,
      transactionalCurrencyId: transactionalCurrencyId,
      requestFor: requestFor,
      requestReason: requestReason,
      patientId: patientId,
      requestType: requestType,
      urgencyLevel: urgencyLevel,
    );

    var res = await network.ajouterPaiement(paiementData, token ?? "");
    return res;
  }
}
