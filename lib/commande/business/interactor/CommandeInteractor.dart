import 'package:eblood_bank_mak_app/commande/business/interactor/usecase/panier/PanierUseCase.dart';
import 'package:eblood_bank_mak_app/commande/business/interactor/usecase/panier/RecupererPanierUseCase.dart';
import 'package:eblood_bank_mak_app/commande/business/interactor/usecase/panier/SupprimerPochePanierUseCase.dart';
import 'package:eblood_bank_mak_app/commande/business/service/panier/PanierNetworkService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../utilisateurs/business/service/utilisateurLocalService.dart';

part 'CommandeInteractor.g.dart';

class Commandeinteractor {
  PanierUseCase panierusecase;
  RecupererPanierUseCase recupererPanierUseCase;
  SupprimerPochePanierUseCase supprimerPochePanierUseCase;

  Commandeinteractor._(this.panierusecase, this.recupererPanierUseCase,
      this.supprimerPochePanierUseCase);

  static Commandeinteractor build(
    PanierNetworkService network,
    UtilisateurLocalService userLocale,
  ) {
    return Commandeinteractor._(
        PanierUseCase(network, userLocale),
        RecupererPanierUseCase(network, userLocale),
        SupprimerPochePanierUseCase(network, userLocale));
  }
}

@Riverpod(keepAlive: true)
Commandeinteractor commandeInteractor(Ref ref) {
  throw Exception("Non encore implementaté");
}
