import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/BloodBagInfoRecherchePocheModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/BloodBankRecherchePocheModel.dart';

class DatumRecherchePocheModel {
  BloodBagInfoRecherchePocheModel bloodBagInfo;
  int bloodStockCount;
  String currency;
  int price;
  BloodBankRecherchePocheModel bloodBank;

  DatumRecherchePocheModel({
    required this.bloodBagInfo,
    this.bloodStockCount = 0,
    this.currency = "USD",
    this.price = 0,
    required this.bloodBank,
  });

  factory DatumRecherchePocheModel.fromJson(Map<String, dynamic> json) => DatumRecherchePocheModel(
    bloodBagInfo: BloodBagInfoRecherchePocheModel.fromJson(json["blood_bag_info"] ?? {}),
    bloodStockCount: json["blood_stock_count"] ?? 0,
    currency: json["currency"] ?? "USD",
    price: json["price"] ?? 0,
    bloodBank: BloodBankRecherchePocheModel.fromJson(json["blood_bank_info"] ?? json["blood_bank"] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    "blood_bag_info": bloodBagInfo.toJson(),
    "blood_stock_count": bloodStockCount,
    "currency": currency,
    "price": price,
    "blood_bank": bloodBank.toJson(),
  };
}