import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/BloodVolumeUnityInfoRecherchePocheModel.dart';

class BloodVolumeInforRecherchePocheModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodVolumeName;
  String bloodVolumeUnityId;
  BloodVolumeUnityInfoRecherchePocheModel bloodVolumeUnityInfo;

  BloodVolumeInforRecherchePocheModel({
    this.id = "",
    this.isActivated = true,
    this.identifier = "",
    DateTime? createdAt,
    required this.bloodVolumeName,
    this.bloodVolumeUnityId = "",
    required this.bloodVolumeUnityInfo,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BloodVolumeInforRecherchePocheModel.fromJson(
          Map<String, dynamic> json) =>
      BloodVolumeInforRecherchePocheModel(
        id: json["_id"]?.toString() ?? "",
        isActivated: json["is_activated"] ?? true,
        identifier: json["identifier"]?.toString() ?? "",
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
        bloodVolumeName: json["blood_volume_name"]?.toString() ?? "",
        bloodVolumeUnityId: json["blood_volume_unity_id"]?.toString() ?? "",
        bloodVolumeUnityInfo:
            BloodVolumeUnityInfoRecherchePocheModel.fromJson(json["blood_volume_unity_info"] ?? {}),
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
