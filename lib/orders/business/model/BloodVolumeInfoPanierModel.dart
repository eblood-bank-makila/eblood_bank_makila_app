import 'dart:convert';

import 'package:eblood_bank_mak_app/orders/business/model/BloodVolumeUnityInfoPanierModel.dart';

BloodVolumeInfoPanierModel recupererListeModeleFromJson(String str) =>
    BloodVolumeInfoPanierModel.fromJson(json.decode(str));

String recupererListeModeleToJson(BloodVolumeInfoPanierModel data) =>
    json.encode(data.toJson());

class BloodVolumeInfoPanierModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodVolumeName;
  String bloodVolumeUnityId;
  BloodVolumeUnityInfoPanierModel bloodVolumeUnityInfo;

  BloodVolumeInfoPanierModel({
  required  this.id,
   required this.isActivated,
   required this.identifier,
  required  this.createdAt,
   required this.bloodVolumeName,
   required this.bloodVolumeUnityId,
   required this.bloodVolumeUnityInfo,
  });

  factory BloodVolumeInfoPanierModel.fromJson(Map json) => BloodVolumeInfoPanierModel(
    id: json["_id"] ?? '',
    isActivated: json["is_activated"] ?? false,
    identifier: json["identifier"] ?? '',
    createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
    bloodVolumeName: json["blood_volume_name"] ?? '',
    bloodVolumeUnityId: json["blood_volume_unity_id"] ?? '',
    bloodVolumeUnityInfo: json["blood_volume_unity_info"] != null
        ? BloodVolumeUnityInfoPanierModel.fromJson(json["blood_volume_unity_info"])
        : BloodVolumeUnityInfoPanierModel(
            id: '',
            isActivated: false,
            identifier: '',
            createdAt: DateTime.now(),
            bloodVolumeUnityName: '',
          ),
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
