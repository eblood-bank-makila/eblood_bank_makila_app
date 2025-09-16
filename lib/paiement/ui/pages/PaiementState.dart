import 'package:eblood_bank_mak_app/commande/business/model/PanierReponseModel.dart';
import 'package:eblood_bank_mak_app/commande/business/model/RecupererPanierResponseModel.dart';
import 'package:eblood_bank_mak_app/paiement/businness/models/PaiementResponseModel.dart';


class PaiementState {
  bool isLoading;
  PaiementResponseModel? paiement;


  PaiementState(
      {this.isLoading = false, this.paiement = null,
      });

  PaiementState copyWith(
      {bool? isLoading,
        PaiementResponseModel? paiement,

      }) =>
      PaiementState(
          isLoading: isLoading ?? this.isLoading,
          paiement: paiement ?? this.paiement,
      );
}
