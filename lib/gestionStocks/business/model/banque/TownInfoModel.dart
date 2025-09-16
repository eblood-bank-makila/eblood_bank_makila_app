// import 'dart:convert';
//
// import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/BloodBagInfoModel.dart';
//
// TownInfoModel pocheModelFromJson(String str) =>
//     TownInfoModel.fromJson(json.decode(str));
//
// String pocheModelToJson(TownInfoModel data) => json.encode(data.toJson());
//
//
//
// class TownInfoModel {
//   String id;
//   String townName;
//
//   TownInfoModel({
//     required this.id,
//     required this.townName,
//   });
//
//   factory TownInfoModel.fromJson(Map<String, dynamic> json) => TownInfoModel(
//     id: json["_id"],
//     townName: json["town_name"],
//   );
//
//   Map<String, dynamic> toJson() =>
//       {
//         "_id": id,
//         "town_name": townName,
//       };}


import 'dart:convert';

import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/TownInfoRecherchePocheModel.dart';

TownInfoModel townInfoModelFromJson(String str) =>
    TownInfoModel.fromJson(json.decode(str));

String townInfoModelToJson(TownInfoModel data) => json.encode(data.toJson());

class TownInfoModel {
  String id;
  String townName;

  TownInfoModel({
    required this.id,
    required this.townName,
  });

  factory TownInfoModel.fromRecherche(TownInfoRecherchePocheModel rechercheModel){
    return TownInfoModel(
      id: rechercheModel.id,
      townName: rechercheModel.townName
    );
  }

  // Constructor for when we only have town_name from server response
  factory TownInfoModel.fromTownName(String townName) => TownInfoModel(
    id: '', // Default empty id when not provided
    townName: townName,
  );

  factory TownInfoModel.fromJson(Map<String, dynamic> json) => TownInfoModel(
    id: json["_id"] ?? '',
    townName: json["town_name"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "town_name": townName,
  };
}