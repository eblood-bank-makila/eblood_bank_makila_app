// import 'dart:convert';
//
// import 'package:eblood_bank_mak_app/commande/business/model/BloodBankInfoPanierModel.dart';
//
// import 'CartItemPanierModel.dart';
//
// DatumModel recupererListeModeleFromJson(String str) =>
//     DatumModel.fromJson(json.decode(str));
//
// String recupererListeModeleToJson(DatumModel data) =>
//     json.encode(data.toJson());
//
// class DatumModel {
//   String id;
//   String identifier;
//   DateTime createdAt;
//   List<CartItemPanierModel> cartItems;
//   String currency;
//   int totalCartBloodBags;
//   int totalPrice;
//   double totalFees;
//
//   DatumModel(
//       {required this.id,
//       required this.identifier,
//       required this.createdAt,
//       required this.cartItems,
//       required this.currency,
//       required this.totalCartBloodBags,
//       required this.totalPrice,
//       required this.totalFees});
//
//   factory DatumModel.fromJson(Map json) => DatumModel(
//         id: json["_id"],
//         identifier: json["identifier"],
//         createdAt: DateTime.parse(json["createdAt"]),
//
//         cartItems: List<CartItemPanierModel>.from(
//             json["cart_items"].map((x) => CartItemPanierModel.fromJson(x))),
//         //cartItems:CartItemPanierModel.fromJson(json["cartItems"]),
//
//         currency: json["currency"],
//         totalCartBloodBags: json["total_cart_blood_bags"],
//         totalPrice: json["total_price"],
//     totalFees: json["total_fees"].toDouble(),
//       );
//
//   Map<String, dynamic> toJson() => {
//         "_id": id,
//         "identifier": identifier,
//         "createdAt": createdAt.toIso8601String(),
//
//         "cart_items": List<dynamic>.from(cartItems.map((x) => x.toJson())),
//         //"cartItems": cartItems.toJson(),
//
//         "currency": currency,
//         "total_cart_blood_bags": totalCartBloodBags,
//         "total_price": totalPrice,
//     "total_fees": totalFees,
//
//       };
// }



import 'dart:convert';
import 'CartItemPanierModel.dart';

DatumModel recupererListeModeleFromJson(String str) =>
    DatumModel.fromJson(json.decode(str));

String recupererListeModeleToJson(DatumModel data) =>
    json.encode(data.toJson());

class DatumModel {
  String id;
  String identifier;
  DateTime createdAt;
  List<CartItemPanierModel> cartItems;
  String currency;
  int totalCartBloodBags;
  int totalPrice;
  double totalFees;

  DatumModel({
    required this.id,
    required this.identifier,
    required this.createdAt,
    required this.cartItems,
    required this.currency,
    required this.totalCartBloodBags,
    required this.totalPrice,
    required this.totalFees,
  });

  factory DatumModel.fromJson(Map<String, dynamic> json) => DatumModel(
    id: json["_id"] ?? '',
    identifier: json["identifier"] ?? '',
    createdAt: DateTime.tryParse(json["createdAt"] ?? '') ?? DateTime.now(),
    cartItems: json["cart_items"] != null
        ? List<CartItemPanierModel>.from(
        json["cart_items"].map((x) => CartItemPanierModel.fromJson(x)))
        : [],
    currency: json["currency"] ?? '',
    totalCartBloodBags: json["total_cart_blood_bags"] ?? 0,
    totalPrice: json["total_price"] ?? 0,
    totalFees: (json["total_fees"] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "identifier": identifier,
    "createdAt": createdAt.toIso8601String(),
    "cart_items": List<dynamic>.from(cartItems.map((x) => x.toJson())),
    "currency": currency,
    "total_cart_blood_bags": totalCartBloodBags,
    "total_price": totalPrice,
    "total_fees": totalFees,
  };
}