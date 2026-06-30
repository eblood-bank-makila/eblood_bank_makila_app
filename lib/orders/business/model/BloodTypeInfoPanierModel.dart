import 'dart:convert';

BloodTypeInfoPanierModel recupererListeModeleFromJson(String str) =>
    BloodTypeInfoPanierModel.fromJson(json.decode(str));

String recupererListeModeleToJson(BloodTypeInfoPanierModel data) =>
    json.encode(data.toJson());

class BloodTypeInfoPanierModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodTypeName;

  BloodTypeInfoPanierModel({
    required this.id,
    required this.isActivated,
    required this.identifier,
    required this.createdAt,
    required this.bloodTypeName,
  });

  factory BloodTypeInfoPanierModel.fromJson(Map json) =>
      BloodTypeInfoPanierModel(
        id: json["_id"] ?? '',
        isActivated: json["is_activated"] ?? false,
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
