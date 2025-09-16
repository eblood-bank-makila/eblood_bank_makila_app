import 'dart:convert';

TownInfoPanierModel recupererListeModeleFromJson(String str) =>
    TownInfoPanierModel.fromJson(json.decode(str));

String recupererListeModeleToJson(TownInfoPanierModel data) =>
    json.encode(data.toJson());

class TownInfoPanierModel {
  String id;
  String townName;

  TownInfoPanierModel({
    required this.id,
    required this.townName,
  });

  factory TownInfoPanierModel.fromJson(Map<String, dynamic> json) => TownInfoPanierModel(
    id: json["_id"] ?? '',  // Valeur par défaut si null
    townName: json["town_name"] ?? '',  // Valeur par défaut si null
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "town_name": townName,
  };
}