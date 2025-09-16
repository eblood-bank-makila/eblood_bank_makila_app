

import 'package:eblood_bank_mak_app/commande/business/model/PanierModel.dart';
import 'package:eblood_bank_mak_app/commande/business/model/PanierReponseModel.dart';
import 'package:eblood_bank_mak_app/commande/business/service/panier/PanierNetworkService.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';

import '../../../../../utilisateurs/business/service/utilisateurLocalService.dart';

class PanierUseCase{
  PanierNetworkService network;
  UtilisateurLocalService local;


  PanierUseCase(this.network, this.local);




  Future<PanierReponseModel?> run(PocheModel poche, BanqueModele banque, {required int quantity}) async {
    // Utilisez la quantité dans votre logique, par exemple :
    var token = await local.recupererTokenOtp();

    // Créer un objet PanierModel avec la quantité spécifiée
    var panierData = PanierModel(
      blood_bank_id: banque.id,
      blood_bag_id: poche.bloodBagInfo.id,
      quantity: quantity, // Utilisez la quantité ici
    );

    var res = await network.ajouterPanier(panierData, token ?? "");
    return res;
  }






}