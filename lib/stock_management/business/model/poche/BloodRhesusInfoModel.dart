import 'dart:convert';

import 'package:eblood_bank_mak_app/stock_management/business/model/recherche/BloodRhesusInfoRecherchePocheModel.dart';

BloodRhesusInfoModel bloodRhesusInfoModelFromJson(String str) =>
    BloodRhesusInfoModel.fromJson(json.decode(str));

String bloodRhesusInfoModelToJson(BloodRhesusInfoModel data) =>
    json.encode(data.toJson());

class BloodRhesusInfoModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodRheususName;

  BloodRhesusInfoModel({
    required this.id,
    this.isActivated = false,
    required this.identifier,
    required this.createdAt,
    required this.bloodRheususName,
  });

  factory BloodRhesusInfoModel.fromJson(Map json) => BloodRhesusInfoModel(
        id: json["_id"] ?? '',
        isActivated: json["is_activated"] ?? true, // Default to true if null
        identifier: json["identifier"] ?? '',
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
        bloodRheususName: json["blood_rheusus_name"] ?? '',
      );

  factory BloodRhesusInfoModel.fromRecherche(
      BloodRhesusInfoRecherchePocheModel rechercheModel) {
    return BloodRhesusInfoModel(
        id: rechercheModel.id,
        isActivated: rechercheModel.isActivated,
        identifier: rechercheModel.identifier,
        createdAt: rechercheModel.createdAt,
        bloodRheususName: rechercheModel.bloodRheususName);
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "is_activated": isActivated,
        "identifier": identifier,
        "createdAt": createdAt.toIso8601String(),
        "blood_rheusus_name": bloodRheususName,
      };
}
