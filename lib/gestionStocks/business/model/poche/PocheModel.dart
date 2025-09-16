import 'dart:convert';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/BloodBagInfoModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/DatumRecherchePocheModel.dart';

PocheModel pocheModelFromJson(String str) =>
    PocheModel.fromJson(json.decode(str));

String pocheModelToJson(PocheModel data) => json.encode(data.toJson());

class PocheModel {
  final BloodBagInfo bloodBagInfo;
  final int bloodStockCount;
  final int price;

  PocheModel({
    required this.bloodBagInfo,
    required this.bloodStockCount,
    required this.price,
  });

  factory PocheModel.fromRecherche(DatumRecherchePocheModel rechercheModel) {
    return PocheModel(
      bloodBagInfo: BloodBagInfo.fromRecherche(rechercheModel.bloodBagInfo),
      bloodStockCount: rechercheModel.bloodStockCount,
      price: rechercheModel.price, // Ajustez selon votre modèle
    );
  }

  factory PocheModel.fromJson(Map<String, dynamic> json) => PocheModel(
        bloodBagInfo: BloodBagInfo.fromJson(json["blood_bag_info"] ?? {}),
        bloodStockCount: json["blood_stock_count"] ?? 1, // Default to 1 if not provided
        price: json["price"] ?? 0, // Default to 0 if not provided
      );

  Map<String, dynamic> toJson() => {
        "blood_bag_info": bloodBagInfo.toJson(),
        "blood_stock_count": bloodStockCount,
        "price": price,
      };
}
