import 'dart:convert';

import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/BloodVolumeUnityInfoModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/BloodVolumeInfoRecherchePocheModel.dart';

BloodVolumeInfoModel bloodVolumeInfoModelFromJson(String str) =>
    BloodVolumeInfoModel.fromJson(json.decode(str));

String bloodVolumeInfoModelToJson(BloodVolumeInfoModel data) =>
    json.encode(data.toJson());

class BloodVolumeInfoModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodVolumeName;
  String bloodVolumeUnityId;
  BloodVolumeUnityInfoModel bloodVolumeUnityInfo;

  BloodVolumeInfoModel({
    required this.id,
    this.isActivated = false,
    required this.identifier,
    required this.createdAt,
    required this.bloodVolumeName,
    required this.bloodVolumeUnityId,
    required this.bloodVolumeUnityInfo,
  });

  factory BloodVolumeInfoModel.fromRecherche(BloodVolumeInforRecherchePocheModel rechercheModel){
    return BloodVolumeInfoModel(
      id:rechercheModel.id,
      isActivated:rechercheModel.isActivated,
      identifier:rechercheModel.identifier,
      createdAt: rechercheModel.createdAt,
      bloodVolumeName: rechercheModel.bloodVolumeName,
      bloodVolumeUnityId: rechercheModel.bloodVolumeUnityId,
      bloodVolumeUnityInfo:  BloodVolumeUnityInfoModel.fromRecherche(rechercheModel.bloodVolumeUnityInfo),


    );
  }

  factory BloodVolumeInfoModel.fromJson(Map json) => BloodVolumeInfoModel(
        id: json["_id"] ?? '',
        isActivated: json["is_activated"] ?? true, // Default to true if null
        identifier: json["identifier"] ?? '',
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
        bloodVolumeName: json["blood_volume_name"] ?? '',
        bloodVolumeUnityId: json["blood_volume_unity_id"] ?? '',
        bloodVolumeUnityInfo:
            BloodVolumeUnityInfoModel.fromJson(json["blood_volume_unity_info"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "is_activated": isActivated,
        "identifier": identifier,
        "createdAt": createdAt.toIso8601String(),
        "blood_volume_name": bloodVolumeName,
        "blood_volume_unity_id": bloodVolumeUnityId,
        "blood_volume_unity_info": bloodVolumeUnityInfo.toJson(),
      };
}
