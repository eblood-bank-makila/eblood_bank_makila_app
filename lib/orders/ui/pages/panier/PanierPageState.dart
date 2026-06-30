import 'package:eblood_bank_mak_app/orders/business/model/PanierReponseModel.dart';
import 'package:eblood_bank_mak_app/orders/business/model/RecupererPanierResponseModel.dart';

import '../../../business/model/panier/SuppressionPanierResponseModel.dart';

class PanierPageState {
  bool isLoading;
  PanierReponseModel? panier;
  RecupererPanierResponseModel? paniers;
  SuppressionPanierResponseModel? supprimer_panier;


  PanierPageState(
      {this.isLoading = false, this.panier = null, this.paniers = null, this.supprimer_panier
      //chargements
      });

  PanierPageState copyWith(
          {bool? isLoading,
          PanierReponseModel? panier,
          RecupererPanierResponseModel? paniers,
            SuppressionPanierResponseModel? supprimer_panier, SuppressionPanierResponseModel? SuppressionPanierResponseModel

          }) =>
      PanierPageState(
          isLoading: isLoading ?? this.isLoading,
          panier: panier ?? this.panier,
          paniers: paniers ?? this.paniers,
        supprimer_panier: supprimer_panier
      );
}
