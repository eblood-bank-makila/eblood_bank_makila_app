import 'dart:convert';

import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/TownInfoModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/BloodBankRecherchePocheModel.dart';

import '../../../../commande/business/model/BloodBankInfoPanierModel.dart';

BanqueModele banqueModeleFromJson(String str) =>
    BanqueModele.fromJson(json.decode(str));

String banqueModeleToJson(BanqueModele data) => json.encode(data.toJson());

class BanqueModele {
  final String id;
  final String identifier;
  final String blood_bank_name;
  final String blood_bank_logo;
  TownInfoModel townInfo;
  final double longitude;
  final double latitude;
  final String? distance; // Distance from user location
  final bool isFavorite; // Favorite status

  BanqueModele({
    required this.id,
    required this.identifier,
    required this.blood_bank_name,
    required this.blood_bank_logo,
    required this.longitude,
    required this.latitude,
    required this.townInfo,
    this.distance,
    this.isFavorite = false,
  });



  // Constructeur à partir de BloodBankRecherchePocheModel
  factory BanqueModele.fromRecherche(
      BloodBankRecherchePocheModel rechercheModel) {
    return BanqueModele(
      id: rechercheModel.id,
      identifier: rechercheModel.identifier,
      blood_bank_name: rechercheModel.bloodBankName,
      blood_bank_logo: rechercheModel.bloodBankLogo,
      longitude: double.tryParse(rechercheModel.longitude) ?? 0.0,
      latitude: double.tryParse(rechercheModel.latitude) ?? 0.0,
      distance: null, // Distance not available in search results
      isFavorite: false, // Default to false for search results
      // townInfo: TownInfoModel.fromJson(rechercheModel.townInfo as Map<String, dynamic>), // Ajustez selon votre modèle
      townInfo: TownInfoModel.fromRecherche(rechercheModel.townInfo),
    );
  }

  factory BanqueModele.fromJson(Map json) => BanqueModele(
        id: json['_id'] ?? '',
        identifier: json['identifier'] ?? json['_id'] ?? '', // Use _id as fallback if identifier is null
        blood_bank_name: json['blood_bank_name'] ?? '',
        blood_bank_logo: json['blood_bank_logo'] ?? '',
        latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
        longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
        distance: json['distance']?.toString(), // Distance from backend
        isFavorite: json['is_favorite'] ?? false, // Favorite status from backend
        townInfo: json["town_info"] != null
            ? TownInfoModel.fromJson(json["town_info"])
            : TownInfoModel.fromTownName(json["town_name"] ?? ''), // Handle town_name from server
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'identifier': identifier,
        'blood_bank_name': blood_bank_name,
        'blood_bank_logo': blood_bank_logo,
        'longitude': longitude,
        'latitude': latitude,
        'distance': distance,
        'is_favorite': isFavorite,
        "town_info": townInfo.toJson(),
      };
}

// class BanqueModele {
//   final String id;
//   final String identifier;
//   final String blood_bank_name;
//   final String blood_bank_logo;
//   TownInfoModel townInfo;
//   final double longitude;
//   final double latitude;
//
//   BanqueModele(
//       {required this.id,
//       required this.identifier,
//       required this.blood_bank_name,
//       required this.blood_bank_logo,
//       required this.longitude,
//       required this.latitude,
//       required this.townInfo});
//
//   factory BanqueModele.fromJson(Map json) => BanqueModele(
//         id: json['_id'],
//         identifier: json['identifier'],
//         blood_bank_name: json['blood_bank_name'],
//         blood_bank_logo: json['blood_bank_logo'],
//         latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
//         longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
//         townInfo: TownInfoModel.fromJson(json["town_info"]),
//       );
//
//   Map<String, dynamic> toJson() => {
//         '_id': id,
//         'identifier': identifier,
//         'blood_bank_name': blood_bank_name,
//         'blood_bank_logo': blood_bank_logo,
//         'longitude': longitude,
//         'latitude': latitude,
//         "town_info": townInfo.toJson(),
//       };
// }
