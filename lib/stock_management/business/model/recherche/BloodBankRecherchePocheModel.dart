import 'package:eblood_bank_mak_app/stock_management/business/model/recherche/TownInfoRecherchePocheModel.dart';

class BloodBankRecherchePocheModel {
  String id;
  String identifier;
  String bloodBankName;
  String bloodBankLogo;
  TownInfoRecherchePocheModel townInfo;
  String longitude;
  String latitude;
  DateTime createdAt;

  BloodBankRecherchePocheModel({
    this.id = "",
    this.identifier = "",
    this.bloodBankName = "",
    this.bloodBankLogo = "",
    TownInfoRecherchePocheModel? townInfo,
    this.longitude = "",
    this.latitude = "",
    DateTime? createdAt,
  }) : townInfo = townInfo ?? TownInfoRecherchePocheModel(),
       createdAt = createdAt ?? DateTime.now();

  factory BloodBankRecherchePocheModel.fromJson(Map<String, dynamic> json) =>
      BloodBankRecherchePocheModel(
        id: json["_id"]?.toString() ?? "",
        identifier: json["identifier"]?.toString() ?? "",
        bloodBankName: json["blood_bank_name"]?.toString() ?? "",
        bloodBankLogo: json["blood_bank_logo"]?.toString() ?? "",
        townInfo: json["town_info"] != null
            ? TownInfoRecherchePocheModel.fromJson(json["town_info"])
            : null,
        longitude: json["longitude"]?.toString() ?? "",
        latitude: json["latitude"]?.toString() ?? "",
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "identifier": identifier,
        "blood_bank_name": bloodBankName,
        "blood_bank_logo": bloodBankLogo,
        "town_info": townInfo.toJson(),
        "longitude": longitude,
        "latitude": latitude,
        "createdAt": createdAt.toIso8601String(),
      };
}
