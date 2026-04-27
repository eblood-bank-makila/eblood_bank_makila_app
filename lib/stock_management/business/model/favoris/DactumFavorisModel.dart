import 'dart:convert';


DactumFavorisModel dactumModelFromJson(String str) =>
    DactumFavorisModel.fromJson(json.decode(str));

String dactumModelToJson(DactumFavorisModel data) => json.encode(data.toJson());

class DactumFavorisModel {
  /// The favorite row id (Mongo ObjectId of the favorite document
  /// itself, NOT the blood bank).
  final String id;

  /// Sprint 13a — the blood-bank organisation id, surfaced as a
  /// distinct field so the remove endpoint (which keys on
  /// (user_id, blood_bank_org_id)) can be called without a second
  /// fetch. Empty string for legacy responses that don't carry it.
  final String bloodBankOrgId;

  final String identifier;
  final String bloodBankName;
  final double longitude;
  final double latitude;

  DactumFavorisModel({
    required this.id,
    required this.bloodBankOrgId,
    required this.identifier,
    required this.bloodBankName,
    required this.longitude,
    required this.latitude,
  });

  factory DactumFavorisModel.fromJson(Map<String, dynamic> json) => DactumFavorisModel(
    id: json["_id"] ?? '',
    // Sprint 13a — new key; legacy responses won't have it.
    bloodBankOrgId: json["blood_bank_org_id"]?.toString() ?? '',
    identifier: json["identifier"] ?? '',
    bloodBankName: json["blood_bank_name"] ?? '',
    longitude: double.tryParse(json["longitude"]?.toString() ?? '0') ?? 0.0,
    latitude: double.tryParse(json["latitude"]?.toString() ?? '0') ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "blood_bank_org_id": bloodBankOrgId,
    "identifier": identifier,
    "blood_bank_name": bloodBankName,
    "longitude": longitude,
    "latitude": latitude,
  };
}






















