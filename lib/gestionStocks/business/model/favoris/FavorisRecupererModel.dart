import 'dart:convert';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/DactumFavorisModel.dart';

FavorisRecupererModel favorisRecupererModelFromJson(String str) =>
    FavorisRecupererModel.fromJson(json.decode(str));

String favorisRecupererModelToJson(FavorisRecupererModel data) =>
    json.encode(data.toJson());

class FavorisRecupererModel {
  final int perpage;
  final int max;
  final List<DactumFavorisModel> data;
  final int statusCode;
  final bool success;

  FavorisRecupererModel({
    required this.perpage,
    required this.max,
    required this.data,
    required this.statusCode,
    required this.success,
  });

  factory FavorisRecupererModel.fromJson(Map<String, dynamic> json) {
    print("Parsed JSON: $json"); // Ajoutez cette ligne pour déboguer
    return FavorisRecupererModel(
      perpage: json["perpage"] ?? 0,
      max: json["max"] ?? 0,
      data: (json["data"] as List?)?.map((x) {
        print("Mapping DactumModel: $x"); // Ajoutez cette ligne pour voir chaque élément
        return DactumFavorisModel.fromJson(x);
      }).toList() ?? [],
      statusCode: json["status_code"] ?? 0,
      success: json["success"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "perpage": perpage,
    "max": max,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "status_code": statusCode,
    "success": success,
  };
}