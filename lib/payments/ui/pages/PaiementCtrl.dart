import 'package:eblood_bank_mak_app/orders/business/model/DatumPanierModel.dart';
import 'package:eblood_bank_mak_app/payments/business/interactors/PaiementInteractor.dart';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementResponseModel.dart';
import 'package:eblood_bank_mak_app/payments/ui/pages/PaiementState.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'PaiementCtrl.g.dart';

@Riverpod(keepAlive: true)
class PaiementCtrl extends _$PaiementCtrl {
  @override
  PaiementState build() {
    return PaiementState();
  }


  Future<PaiementResponseModel?> ajouterPaiment(
    DatumModel paiement, {
    String? phoneNumber,
    String? transactionalCurrencyId,
    String? requestFor,
    String? requestReason,
    String? patientId,
    String? requestType,
    String? urgencyLevel,
    int? amountCents,
    String? currency,
  }) async {
    var usecase = ref.watch(paiementInteractorProvider).ajouterPochePaiementUseCase;
    var res = await usecase.run(
      paiement,
      phoneNumber: phoneNumber,
      transactionalCurrencyId: transactionalCurrencyId,
      requestFor: requestFor,
      requestReason: requestReason,
      patientId: patientId,
      requestType: requestType,
      urgencyLevel: urgencyLevel,
      amountCents: amountCents,
      currency: currency,
    );
    state = state.copyWith(paiement: res);

    return res;
  }




}




