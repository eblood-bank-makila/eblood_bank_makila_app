// import 'dart:convert';
//
// import 'package:eblood_bank_mak_app/orders/business/model/BloodBagInfoPanierModel.dart';
// import 'package:eblood_bank_mak_app/orders/business/model/BloodBankInfoPanierModel.dart';
//
// CartItemPanierModel recupererListeModeleFromJson(String str) =>
//     CartItemPanierModel.fromJson(json.decode(str));
//
// String recupererListeModeleToJson(CartItemPanierModel data) =>
//     json.encode(data.toJson());
//
// class CartItemPanierModel {
//   // String id;
//   // String currencyId;
//   // String bloodBagId;
//   // int price;
//   // int quantity;
//   // String currency;
//   // BloodBagInfoPanierModel bloodBagInfo;
//
//   String id;
//   String currencyId;
//   String bloodBagId;
//   int price;
//   int quantity;
//   String currency;
//   BloodBagInfoPanierModel bloodBagInfo;
//   String bloodBankId;
//   BloodBankInfoPanierModel bloodBankInfo;
//
//   CartItemPanierModel(
//       {required this.id,
//       required this.currencyId,
//       required this.bloodBagId,
//       required this.price,
//       required this.quantity,
//       required this.currency,
//       required this.bloodBagInfo,
//       required this.bloodBankInfo,
//       required this.bloodBankId});
//
//   factory CartItemPanierModel.fromJson(Map json) => CartItemPanierModel(
//       id: json["_id"],
//       currencyId: json["currency_id"],
//       bloodBagId: json["blood_bag_id"],
//       price: json["price"],
//       quantity: json["quantity"],
//       currency: json["currency"],
//       bloodBagInfo: BloodBagInfoPanierModel.fromJson(json["blood_bag_info"]),
//       bloodBankInfo: BloodBankInfoPanierModel.fromJson(json["blood_bank_info"]),
//     bloodBankId: json["blood_bank_id"],
//
//
//   );
//
//
//   Map<String, dynamic> toJson() => {
//         "_id": id,
//         "currency_id": currencyId,
//         "blood_bag_id": bloodBagId,
//         "price": price,
//         "quantity": quantity,
//         "currency": currency,
//         "blood_bag_info": bloodBagInfo.toJson(),
//     "blood_bank_id": bloodBankId,
//     "blood_bank_info": bloodBankInfo.toJson(),
//       };
// }


import 'dart:convert';
import 'package:eblood_bank_mak_app/orders/business/model/BloodBagInfoPanierModel.dart';
import 'package:eblood_bank_mak_app/orders/business/model/BloodBankInfoPanierModel.dart';

CartItemPanierModel recupererListeModeleFromJson(String str) =>
    CartItemPanierModel.fromJson(json.decode(str));

String recupererListeModeleToJson(CartItemPanierModel data) =>
    json.encode(data.toJson());

class CartItemPanierModel {
  String id;
  String currencyId;
  String bloodBagId;
  int price;
  int quantity;
  String currency;
  BloodBagInfoPanierModel bloodBagInfo;
  String bloodBankId;
  BloodBankInfoPanierModel bloodBankInfo;

  CartItemPanierModel({
    required this.id,
    required this.currencyId,
    required this.bloodBagId,
    required this.price,
    required this.quantity,
    required this.currency,
    required this.bloodBagInfo,
    required this.bloodBankInfo,
    required this.bloodBankId,
  });

  factory CartItemPanierModel.fromJson(Map<String, dynamic> json) =>
      CartItemPanierModel(
        id: json["_id"] ?? '',
        currencyId: json["currency_id"] ?? '',
        bloodBagId: json["blood_bag_id"] ?? '',
        price: json["price"] ?? 0,
        quantity: json["quantity"] ?? 0,
        currency: json["currency"] ?? '',
        bloodBagInfo: BloodBagInfoPanierModel.fromJson(json["blood_bag_info"] ?? {}),
        bloodBankInfo: BloodBankInfoPanierModel.fromJson(json["blood_bank_info"] ?? {}),
        bloodBankId: json["blood_bank_id"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "currency_id": currencyId,
    "blood_bag_id": bloodBagId,
    "price": price,
    "quantity": quantity,
    "currency": currency,
    "blood_bag_info": bloodBagInfo.toJson(),
    "blood_bank_id": bloodBankId,
    "blood_bank_info": bloodBankInfo.toJson(),
  };
}