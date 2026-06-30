import 'package:eblood_bank_mak_app/stock_management/business/model/recherche/BloodRhesusInfoRecherchePocheModel.dart';

import 'BloodTypeInfoRecherchePocheModel.dart';
import 'BloodVolumeInfoRecherchePocheModel.dart';

class BloodBagInfoRecherchePocheModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodTypeId;
  String bloodRhesusId;
  String bloodVolumeId;
  BloodTypeInfoRecherchePocheModel bloodTypeInfo;
  BloodRhesusInfoRecherchePocheModel bloodRhesusInfo;
  BloodVolumeInforRecherchePocheModel bloodVolumeInfo;

  BloodBagInfoRecherchePocheModel({
    required this.id,
    this.isActivated = true,
    this.identifier = "",
    DateTime? createdAt,
    this.bloodTypeId = "",
    this.bloodRhesusId = "",
    this.bloodVolumeId = "",
    required this.bloodTypeInfo,
    required this.bloodRhesusInfo,
    required this.bloodVolumeInfo,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BloodBagInfoRecherchePocheModel.fromJson(Map<String, dynamic> json) =>
      BloodBagInfoRecherchePocheModel(
    id: json["_id"]?.toString() ??
      json["id"]?.toString() ??
      json["blood_bag_id"]?.toString() ??
      json["identifier"]?.toString() ??
      "",
        isActivated: json["is_activated"] ?? true,
    identifier: json["identifier"]?.toString() ??
      json["_id"]?.toString() ??
      json["id"]?.toString() ??
      "",
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
        bloodTypeId: json["blood_type_id"]?.toString() ?? "",
        bloodRhesusId: json["blood_rhesus_id"]?.toString() ?? "",
        bloodVolumeId: json["blood_volume_id"]?.toString() ?? "",
        bloodTypeInfo:
            BloodTypeInfoRecherchePocheModel.fromJson(json["blood_type_info"] ?? {}),
        bloodRhesusInfo: BloodRhesusInfoRecherchePocheModel.fromJson(
            json["blood_rhesus_info"] ?? {}),
        bloodVolumeInfo: BloodVolumeInforRecherchePocheModel.fromJson(
            json["blood_volume_info"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "is_activated": isActivated,
        "identifier": identifier,
        "createdAt": createdAt.toIso8601String(),
        "blood_type_id": bloodTypeId,
        "blood_rhesus_id": bloodRhesusId,
        "blood_volume_id": bloodVolumeId,
        "blood_type_info": bloodTypeInfo.toJson(),
        "blood_rhesus_info": bloodRhesusInfo.toJson(),
        "blood_volume_info": bloodVolumeInfo.toJson(),
      };
}
