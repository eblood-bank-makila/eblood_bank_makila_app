// import 'dart:convert';
//
// import 'package:eblood_bank_mak_app/orders/business/model/TownInfoPanierModel.dart';
//
// BloodBankInfoPanierModel bloodBankInfoPanierModelFromJson(String str) =>
//     BloodBankInfoPanierModel.fromJson(json.decode(str));
//
// String bloodBankInfoPanierModelToJson(BloodBankInfoPanierModel data) =>
//     json.encode(data.toJson());
//
// class BloodBankInfoPanierModel {
//   String id;
//   String identifier;
//   String bloodBankName;
//   String bloodBankLogo;
//   TownInfoPanierModel townInfo;
//   String longitude;
//   String latitude;
//   DateTime createdAt;
//
//   BloodBankInfoPanierModel({
//    required this.id,
//   required  this.identifier,
//   required  this.bloodBankName,
//  required   this.bloodBankLogo,
//   required  this.townInfo,
//  required   this.longitude,
//   required  this.latitude,
//    required this.createdAt,
//   });
//
//   factory BloodBankInfoPanierModel.fromJson(Map json) => BloodBankInfoPanierModel(
//     id: json["_id"],
//     identifier: json["identifier"],
//     bloodBankName: json["blood_bank_name"],
//     bloodBankLogo: json["blood_bank_logo"],
//     townInfo: TownInfoPanierModel.fromJson(json["town_info"]),
//     longitude: json["longitude"],
//     latitude: json["latitude"],
//     createdAt: DateTime.parse(json["createdAt"]),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "_id": id,
//     "identifier": identifier,
//     "blood_bank_name": bloodBankName,
//     "blood_bank_logo": bloodBankLogo,
//     "town_info": townInfo.toJson(),
//     "longitude": longitude,
//     "latitude": latitude,
//     "createdAt": createdAt.toIso8601String(),
//   };
// }
import 'dart:convert';
import 'package:eblood_bank_mak_app/orders/business/model/TownInfoPanierModel.dart';

BloodBankInfoPanierModel bloodBankInfoPanierModelFromJson(String str) =>
    BloodBankInfoPanierModel.fromJson(json.decode(str));

String bloodBankInfoPanierModelToJson(BloodBankInfoPanierModel data) =>
    json.encode(data.toJson());

class BloodBankInfoPanierModel {
  String id;
  String identifier;
  String bloodBankName;
  String bloodBankLogo;
  TownInfoPanierModel townInfo;
  String longitude;
  String latitude;
  DateTime createdAt;

  BloodBankInfoPanierModel({
    required this.id,
    required this.identifier,
    required this.bloodBankName,
    required this.bloodBankLogo,
    required this.townInfo,
    required this.longitude,
    required this.latitude,
    required this.createdAt,
  });

  factory BloodBankInfoPanierModel.fromJson(Map<String, dynamic> json) {
    return BloodBankInfoPanierModel(
      id: json["_id"] ?? '',  // Valeur par défaut si null
      identifier: json["identifier"] ?? '',
      bloodBankName: json["blood_bank_name"] ?? '',
      bloodBankLogo: json["blood_bank_logo"] ?? '',
      townInfo: TownInfoPanierModel.fromJson(json["town_info"] ?? {}),
      longitude: json["longitude"] ?? '',
      latitude: json["latitude"] ?? '',
      createdAt: DateTime.tryParse(json["createdAt"] ?? '') ?? DateTime.now(), // Valeur par défaut
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "identifier": identifier,
    "blood_bank_name": bloodBankName,
    "blood_bank_logo": bloodBankLogo,
    "town_info": townInfo.toJson(),
    "longitude": longitude,
    "latitude": latitude,
    "createdAt": createdAt.toIso8601String(),
  };
}