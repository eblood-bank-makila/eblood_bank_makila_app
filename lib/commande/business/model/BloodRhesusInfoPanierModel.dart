import 'dart:convert';

BloodRhesusInfoPanierModel recupererListeModeleFromJson(String str) =>
    BloodRhesusInfoPanierModel.fromJson(json.decode(str));

String recupererListeModeleToJson(BloodRhesusInfoPanierModel data) =>
    json.encode(data.toJson());

class BloodRhesusInfoPanierModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodRheususName;

  BloodRhesusInfoPanierModel({
   required this.id,
  required  this.isActivated,
  required  this.identifier,
 required   this.createdAt,
 required   this.bloodRheususName,
  });

  factory BloodRhesusInfoPanierModel.fromJson(Map json) => BloodRhesusInfoPanierModel(
    id: json["_id"] ?? '',
    isActivated: json["is_activated"] ?? false,
    identifier: json["identifier"] ?? '',
    createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
    bloodRheususName: json["blood_rheusus_name"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "is_activated": isActivated,
    "identifier": identifier,
    "createdAt": createdAt.toIso8601String(),
    "blood_rheusus_name": bloodRheususName,
  };
}
