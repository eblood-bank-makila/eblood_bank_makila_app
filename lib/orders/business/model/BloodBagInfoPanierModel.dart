import 'dart:convert';

import 'package:eblood_bank_mak_app/orders/business/model/BloodRhesusInfoPanierModel.dart';
import 'package:eblood_bank_mak_app/orders/business/model/BloodTypeInfoPanierModel.dart';
import 'package:eblood_bank_mak_app/orders/business/model/BloodVolumeInfoPanierModel.dart';
import 'package:eblood_bank_mak_app/orders/business/model/BloodVolumeUnityInfoPanierModel.dart';

BloodBagInfoPanierModel recupererListeModeleFromJson(String str) =>
    BloodBagInfoPanierModel.fromJson(json.decode(str));

String recupererListeModeleToJson(BloodBagInfoPanierModel data) =>
    json.encode(data.toJson());

class BloodBagInfoPanierModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodTypeId;
  String bloodRhesusId;
  String bloodVolumeId;
  BloodTypeInfoPanierModel bloodTypeInfo;
  BloodRhesusInfoPanierModel bloodRhesusInfo;
  BloodVolumeInfoPanierModel bloodVolumeInfo;

  BloodBagInfoPanierModel({
    required this.id,
    required this.isActivated,
    required this.identifier,
    required this.createdAt,
    required this.bloodTypeId,
    required this.bloodRhesusId,
    required this.bloodVolumeId,
    required this.bloodTypeInfo,
    required this.bloodRhesusInfo,
    required this.bloodVolumeInfo,
  });

  factory BloodBagInfoPanierModel.fromJson(Map json) => BloodBagInfoPanierModel(
        id: json["_id"] ?? '',
        isActivated: json["is_activated"] ?? false, // Default to false if null
        identifier: json["identifier"] ?? '',
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
        bloodTypeId: json["blood_type_id"] ?? '',
        bloodRhesusId: json["blood_rhesus_id"] ?? '',
        bloodVolumeId: json["blood_volume_id"] ?? '',
        bloodTypeInfo: json["blood_type_info"] != null
            ? BloodTypeInfoPanierModel.fromJson(json["blood_type_info"])
            : BloodTypeInfoPanierModel(
                id: '',
                isActivated: false,
                identifier: '',
                createdAt: DateTime.now(),
                bloodTypeName: '',
              ),
        bloodRhesusInfo: json["blood_rhesus_info"] != null
            ? BloodRhesusInfoPanierModel.fromJson(json["blood_rhesus_info"])
            : BloodRhesusInfoPanierModel(
                id: '',
                isActivated: false,
                identifier: '',
                createdAt: DateTime.now(),
                bloodRheususName: '',
              ),
        bloodVolumeInfo: json["blood_volume_info"] != null
            ? BloodVolumeInfoPanierModel.fromJson(json["blood_volume_info"])
            : BloodVolumeInfoPanierModel(
                id: '',
                isActivated: false,
                identifier: '',
                createdAt: DateTime.now(),
                bloodVolumeName: '',
                bloodVolumeUnityId: '',
                bloodVolumeUnityInfo: BloodVolumeUnityInfoPanierModel(
                  id: '',
                  isActivated: false,
                  identifier: '',
                  createdAt: DateTime.now(),
                  bloodVolumeUnityName: '',
                ),
              ),
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
