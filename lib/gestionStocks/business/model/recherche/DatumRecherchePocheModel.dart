import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/BloodBagInfoRecherchePocheModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/BloodBankRecherchePocheModel.dart';

class DatumRecherchePocheModel {
  BloodBagInfoRecherchePocheModel bloodBagInfo;
  int bloodStockCount;
  String currency;
  int price;
  BloodBankRecherchePocheModel bloodBank;
  String? bloodProductType;
  String? status;
  String? batchNumber;
  String? expireDate;
  int? daysUntilExpiry;
  String? bloodBagCondition;
  String? currencyId;
  String? currencySymbol;
  String? currencyCode;
  String? description;

  DatumRecherchePocheModel({
    required this.bloodBagInfo,
    this.bloodStockCount = 0,
    this.currency = "USD",
    this.price = 0,
    required this.bloodBank,
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

  factory DatumRecherchePocheModel.fromJson(Map<String, dynamic> json) => DatumRecherchePocheModel(
    bloodBagInfo: BloodBagInfoRecherchePocheModel.fromJson(json["blood_bag_info"] ?? {}),
    bloodStockCount: json["blood_stock_count"] ?? 0,
    currency: json["currency"] ?? "USD",
    price: json["price"] ?? 0,
    bloodBank: BloodBankRecherchePocheModel.fromJson(json["blood_bank_info"] ?? json["blood_bank"] ?? {}),
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
    "currency": currency,
    "price": price,
    "blood_bank": bloodBank.toJson(),
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