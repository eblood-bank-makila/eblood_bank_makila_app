
import 'package:eblood_bank_mak_app/payments/business/interactors/usecase/AjouterPochePaiementUseCase.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaiementNetworkService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'PaiementInteractor.g.dart';



class Paiementinteractor {
  AjouterPochePaiementUseCase ajouterPochePaiementUseCase;




  Paiementinteractor._(
      this.ajouterPochePaiementUseCase,



      );

  static Paiementinteractor build(
      PaiementNetworkService network,
      UtilisateurLocalService userLocale,
      ) {
    return Paiementinteractor._(
        AjouterPochePaiementUseCase(network,userLocale),


    );
  }
}

@Riverpod(keepAlive: true)
Paiementinteractor paiementInteractor(Ref ref) {
  // This will be overridden in main.dart with the actual implementation
  throw UnimplementedError("PaiementInteractor should be overridden in main.dart");
}