import 'dart:async';

import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/banque/BanqueListeLocalService.dart';
import 'package:sembast/sembast.dart';

class BanqueListeServiceLocalImpl implements BanqueListeLocalService {
  Database db;
  String banqueKey = 'BanqueKey';
  String tokenKey = "TokenKey";

  var stockage = StoreRef.main();

  BanqueListeServiceLocalImpl(this.db);

  @override
  Future<String?> recupererTokenOtp() async {
    var data = await stockage.record(tokenKey).get(db) as String?;
    print("data token: $data");
    return Future.value(data);
  }

  @override
  Future<bool> saveListeBanque(List<BanqueModele> banques) async {
     // Map data = banques as Map <String,dynamic>;
    await stockage.record(banqueKey).put(db, banques.toString());
return true;
  }

  // Future<void> saveListeBanque(List<BanqueModele> banques) async {
  //   // Convertir la liste de BanqueModele en une liste de Maps
  //   List<Map<String, dynamic>> banquesJson = banques.map((banque) => banque.toJson()).toList();
  //
  //   // Créer un Map pour le stockage
  //   Map<String, dynamic> dataToSave = {
  //     'banques': banquesJson,
  //   };
  //
  //   // Sauvegarder les données dans le stockage
  //   await stockage.record(banqueKey).put(db, dataToSave);
  //
  //   print("Données sauvegardées : $dataToSave");
  // }

  @override
  // Future<List<BanqueModele>?> getBanque() async {
  //   var data = await stockage.record(banqueKey).get(db) as Map<dynamic, dynamic>?;
  //   print("data local user $data");
  //
  //   // Vérifiez si les données sont nulles ou vides
  //   if (data == null || data.isEmpty) {
  //     return null; // ou une liste vide, selon votre logique
  //   }
  //
  //   // Conversion des données en liste de BanqueModele
  //   return (data['banques'] as List<dynamic>?)
  //       ?.map((item) => BanqueModele.fromJson(item as Map<String, dynamic>))
  //       .toList();
  // }
  Future<List<BanqueModele>?> getBanque() async {
    var data =
        await stockage.record(banqueKey).get(db) as Map<dynamic, dynamic>?;
    print("data local user $data");

    // Cast to Map<String, dynamic> before passing to fromJson
    return Future.value(data as FutureOr<List<BanqueModele>?>?);
  }
}
