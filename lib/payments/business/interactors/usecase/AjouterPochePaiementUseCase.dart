import 'package:eblood_bank_mak_app/orders/business/model/DatumPanierModel.dart';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementModel.dart';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementResponseModel.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaiementNetworkService.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

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
    // Sprint 15 — the gateway-agnostic /payments/initiate endpoint
    // needs the amount and currency upfront. Callers now pass these
    // explicitly; if omitted, fall back to the cart's totals.
    int? amountCents,
    String? currency,
  }) async {
    var token = await local.recupererTokenOtp();

    final fallbackAmountCents = amountCents
        ?? (panier_id.totalPrice * 100).round();
    final fallbackCurrency = currency ?? panier_id.currency;

    var paiementData = PaiementModel(
      cartId: panier_id.id,
      phoneNumber: phoneNumber,
      transactionalCurrencyId: transactionalCurrencyId,
      requestFor: requestFor,
      requestReason: requestReason,
      patientId: patientId,
      requestType: requestType,
      urgencyLevel: urgencyLevel,
      amountCents: fallbackAmountCents,
      currency: fallbackCurrency,
    );

    var res = await network.ajouterPaiement(paiementData, token ?? "");
    return res;
  }
}
