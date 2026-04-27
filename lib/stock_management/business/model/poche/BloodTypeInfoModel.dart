import 'dart:convert';

import 'package:eblood_bank_mak_app/stock_management/business/model/recherche/BloodTypeInfoRecherchePocheModel.dart';

BloodTypeInfoModel bloodTypeInfoModelFromJson(String str) =>
    BloodTypeInfoModel.fromJson(json.decode(str));

String bloodTypeInfoModelToJson(BloodTypeInfoModel data) => json.encode(data.toJson());

class BloodTypeInfoModel {

  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodTypeName;


  BloodTypeInfoModel({
    required this.id,
    this.isActivated =false,
    required this.identifier,
    required this.createdAt,
    required this.bloodTypeName,

  });

  factory BloodTypeInfoModel .fromRecherche(BloodTypeInfoRecherchePocheModel rechercheModel) {
    return BloodTypeInfoModel(
      isActivated:  rechercheModel.isActivated,
      identifier: rechercheModel.identifier,
      id: rechercheModel.id,
      createdAt: rechercheModel.createdAt,
bloodTypeName: rechercheModel.bloodTypeName

    );
  }

  factory BloodTypeInfoModel.fromJson(Map json) => BloodTypeInfoModel(
    id: json["_id"] ?? '',
    isActivated: json["is_activated"] ?? true, // Default to true if null
    identifier: json["identifier"] ?? '',
    createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
    bloodTypeName: json["blood_type_name"] ?? '',

  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "is_activated": isActivated,
    "identifier": identifier,
    "createdAt": createdAt.toIso8601String(),
    "blood_type_name": bloodTypeName,

  };
}





