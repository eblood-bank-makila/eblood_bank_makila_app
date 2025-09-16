import 'dart:convert';

import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/BloodVolumeUnityInfoRecherchePocheModel.dart';

BloodVolumeUnityInfoModel bloodVolumeUnityInfoModelFromJson(String str) =>
    BloodVolumeUnityInfoModel.fromJson(json.decode(str));

String bloodVolumeUnityInfoModelToJson(BloodVolumeUnityInfoModel data) =>
    json.encode(data.toJson());

class BloodVolumeUnityInfoModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodVolumeUnityName;

  BloodVolumeUnityInfoModel({
    required this.id,
    this.isActivated = false,
    required this.identifier,
    required this.createdAt,
    required this.bloodVolumeUnityName,
  });

  factory BloodVolumeUnityInfoModel.fromRecherche(BloodVolumeUnityInfoRecherchePocheModel rechercheModel){
    return  BloodVolumeUnityInfoModel(
      id: rechercheModel.id,
      isActivated: rechercheModel.isActivated,
      identifier: rechercheModel.identifier,
      createdAt: rechercheModel.createdAt,
      bloodVolumeUnityName: rechercheModel.bloodVolumeUnityName

    );
  }

  factory BloodVolumeUnityInfoModel.fromJson(Map json) =>
      BloodVolumeUnityInfoModel(
        id: json["_id"] ?? '',
        isActivated: json["is_activated"] ?? true, // Default to true if null
        identifier: json["identifier"] ?? '',
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
        bloodVolumeUnityName: json["blood_volume_unity_name"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "is_activated": isActivated,
        "identifier": identifier,
        "createdAt": createdAt.toIso8601String(),
        "blood_volume_unity_name": bloodVolumeUnityName,
      };
}
