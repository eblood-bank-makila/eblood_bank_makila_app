import 'dart:convert';

import 'package:eblood_bank_mak_app/commande/business/model/PanierModel.dart';
import 'package:eblood_bank_mak_app/commande/business/model/PanierReponseModel.dart';
import 'package:eblood_bank_mak_app/commande/business/service/panier/PanierNetworkService.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/poche/PocheModel.dart';

import '../../../../../utilisateurs/business/service/utilisateurLocalService.dart';

class PanierUseCase{
  PanierNetworkService network;
  UtilisateurLocalService local;


  PanierUseCase(this.network, this.local);




  Future<PanierReponseModel?> run(PocheModel poche, BanqueModele banque, {required int quantity}) async {
    // Utilisez la quantité dans votre logique, par exemple :
    var token = await local.recupererTokenOtp();

    print('🧾 [PanierUseCase] Preparing add-to-cart payload');
    print('   BanqueModele: id=${banque.id}, identifier=${banque.identifier}, name=${banque.blood_bank_name}');
    print('   Banque location: town=${banque.townInfo.townName} (id=${banque.townInfo.id}), lat=${banque.latitude}, lng=${banque.longitude}');
    print('   PocheModel bloodBag: id=${poche.bloodBagInfo.id}, identifier=${poche.bloodBagInfo.identifier}, type=${poche.bloodBagInfo.bloodTypeId}/${poche.bloodBagInfo.bloodRhesusId}');
    print('   PocheModel raw: ${jsonEncode(poche.toJson())}');

    // Fallback: some legacy payloads keep the identifier only in the raw map
    final Map<String, dynamic> rawPoche = poche.toJson();
    final Map<String, dynamic> rawBag = (rawPoche['blood_bag_info'] as Map<String, dynamic>?) ?? const {};

    final String computedBloodBagId = poche.bloodBagInfo.id.isNotEmpty
        ? poche.bloodBagInfo.id
        : (poche.bloodBagInfo.identifier.isNotEmpty
            ? poche.bloodBagInfo.identifier
            : (rawBag['_id']?.toString() ?? rawBag['identifier']?.toString() ?? rawBag['blood_bag_id']?.toString() ?? ''));

    if (poche.bloodBagInfo.id.isEmpty && computedBloodBagId.isNotEmpty) {
      print('   ⚠️ No id on BloodBagInfo, falling back to computedBloodBagId=$computedBloodBagId');
    }

    // Créer un objet PanierModel avec la quantité spécifiée
    var panierData = PanierModel(
      blood_bank_id: banque.id,
      blood_bag_id: computedBloodBagId,
      quantity: quantity, // Utilisez la quantité ici
    );

    print('   ➡️ PanierModel built: ${jsonEncode(panierData.toJson())}');

    var res = await network.ajouterPanier(panierData, token ?? "");
    return res;
  }






}