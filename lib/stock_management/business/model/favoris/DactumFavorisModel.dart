import 'dart:convert';


DactumFavorisModel dactumModelFromJson(String str) =>
    DactumFavorisModel.fromJson(json.decode(str));

String dactumModelToJson(DactumFavorisModel data) => json.encode(data.toJson());

class DactumFavorisModel {
  final String id;
  final String identifier;
  final String bloodBankName;
  final double longitude;
  final double latitude;

  DactumFavorisModel({
    required this.id,
    required this.identifier,
    required this.bloodBankName,
    required this.longitude,
    required this.latitude,
  });

  factory DactumFavorisModel.fromJson(Map<String, dynamic> json) => DactumFavorisModel(
    id: json["_id"] ?? '',
    identifier: json["identifier"] ?? '',
    bloodBankName: json["blood_bank_name"] ?? '',
    longitude: double.tryParse(json["longitude"]?.toString() ?? '0') ?? 0.0,
    latitude: double.tryParse(json["latitude"]?.toString() ?? '0') ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "identifier": identifier,
    "blood_bank_name": bloodBankName,
    "longitude": longitude,
    "latitude": latitude,
  };
}






















