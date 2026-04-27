import 'dart:convert';
import 'package:eblood_bank_mak_app/stock_management/business/model/poche/BloodBagInfoModel.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/recherche/DatumRecherchePocheModel.dart';

PocheModel pocheModelFromJson(String str) =>
    PocheModel.fromJson(json.decode(str));

String pocheModelToJson(PocheModel data) => json.encode(data.toJson());

class PocheModel {
  final BloodBagInfo bloodBagInfo;
  final int bloodStockCount;
  final int price;
  final String? bloodProductType;
  final String? status;
  final String? batchNumber;
  final String? expireDate;
  final int? daysUntilExpiry;
  final String? bloodBagCondition;
  final String? currencyId;
  final String? currencySymbol;
  final String? currencyCode;
  final String? description;

  PocheModel({
    required this.bloodBagInfo,
    required this.bloodStockCount,
    required this.price,
    this.bloodProductType,
    this.status,
    this.batchNumber,
    this.expireDate,
    this.daysUntilExpiry,
    this.bloodBagCondition,
    this.currencyId,
    this.currencySymbol,
    this.currencyCode,
    this.description,
  });

  factory PocheModel.fromRecherche(DatumRecherchePocheModel rechercheModel) {
    return PocheModel(
      bloodBagInfo: BloodBagInfo.fromRecherche(rechercheModel.bloodBagInfo),
      bloodStockCount: rechercheModel.bloodStockCount,
      price: rechercheModel.price,
      bloodProductType: rechercheModel.bloodProductType,
      status: rechercheModel.status,
      batchNumber: rechercheModel.batchNumber,
      expireDate: rechercheModel.expireDate,
      daysUntilExpiry: rechercheModel.daysUntilExpiry,
      bloodBagCondition: rechercheModel.bloodBagCondition,
      currencyId: rechercheModel.currencyId,
      currencySymbol: rechercheModel.currencySymbol,
      currencyCode: rechercheModel.currencyCode,
      description: rechercheModel.description,
    );
  }

  factory PocheModel.fromJson(Map<String, dynamic> json) => PocheModel(
        bloodBagInfo: BloodBagInfo.fromJson(json["blood_bag_info"] ?? {}),
        bloodStockCount: json["blood_stock_count"] ?? 1,
        price: json["price"] ?? 0,
        bloodProductType: json["blood_product_type"],
        status: json["status"],
        batchNumber: json["batch_number"],
        expireDate: json["expire_date"],
        daysUntilExpiry: json["days_until_expiry"],
        bloodBagCondition: json["blood_bag_condition"],
        currencyId: json["currency_id"],
        currencySymbol: json["currency_symbol"],
        currencyCode: json["currency_code"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "blood_bag_info": bloodBagInfo.toJson(),
        "blood_stock_count": bloodStockCount,
        "price": price,
        "blood_product_type": bloodProductType,
        "status": status,
        "batch_number": batchNumber,
        "expire_date": expireDate,
        "days_until_expiry": daysUntilExpiry,
        "blood_bag_condition": bloodBagCondition,
        "currency_id": currencyId,
        "currency_symbol": currencySymbol,
        "currency_code": currencyCode,
        "description": description,
      };
}
