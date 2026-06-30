import 'dart:convert';

BloodVolumeUnityInfoPanierModel recupererListeModeleFromJson(String str) =>
    BloodVolumeUnityInfoPanierModel.fromJson(json.decode(str));

String recupererListeModeleToJson(BloodVolumeUnityInfoPanierModel data) =>
    json.encode(data.toJson());

class BloodVolumeUnityInfoPanierModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodVolumeUnityName;

  BloodVolumeUnityInfoPanierModel({
    required this.id,
  required  this.isActivated,
  required  this.identifier,
 required   this.createdAt,
  required  this.bloodVolumeUnityName,
  });

  factory BloodVolumeUnityInfoPanierModel.fromJson(Map json) => BloodVolumeUnityInfoPanierModel(
    id: json["_id"] ?? '',
    isActivated: json["is_activated"] ?? false,
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
