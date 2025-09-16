import 'dart:convert';

import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';

RecupererPanierResponseModel panierReponseModelFromJson(String str) =>
    RecupererPanierResponseModel.fromJson(json.decode(str));

String panierReponseModelToJson(RecupererPanierResponseModel data) =>
    json.encode(data.toJson());

class RecupererPanierResponseModel {
  int perpage;
  int max;
  List<DatumModel> data;
  int statusCode;
  bool success;

  RecupererPanierResponseModel({
    required this.perpage,
    required this.max,
    required this.data,
    required this.statusCode,
    required this.success,
  });

  factory RecupererPanierResponseModel.fromJson(Map<String, dynamic> json) =>
      RecupererPanierResponseModel(
        perpage: json["perpage"] ?? 0,
        max: json["max"] ?? 0,
        data: List<DatumModel>.from(
            json["data"].map((x) => DatumModel.fromJson(x))),
        //data: json["data"] != null ? List<DatumModel>.from(json["data"].map((x) => DatumModel.fromJson(x))) : [], // Retourne une liste vide si 'data' est null
        statusCode: json["status_code"] ?? 0,
        success: json["success"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "perpage": perpage,
        "max": max,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "status_code": statusCode,
        "success": success,
      };
}
