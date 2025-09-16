// To parse this JSON data, do
//
//     final recherchePocheResponseModel = recherchePocheResponseModelFromJson(jsonString);

import 'dart:convert';

import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/DatumRecherchePocheModel.dart';

RecherchePocheResponseModel recherchePocheResponseModelFromJson(String str) => RecherchePocheResponseModel.fromJson(json.decode(str));

String recherchePocheResponseModelToJson(RecherchePocheResponseModel data) => json.encode(data.toJson());

class RecherchePocheResponseModel {
  int max;
  int perpage;
  List<DatumRecherchePocheModel> data;
  int statusCode;
  bool success;

  RecherchePocheResponseModel({
  required  this.max,
 required   this.perpage,
 required   this.data,
  required  this.statusCode,
  required  this.success,
  });

  factory RecherchePocheResponseModel.fromJson(Map<String, dynamic> json) => RecherchePocheResponseModel(
    max: json["max"],
    perpage: json["perpage"],
    data: List<DatumRecherchePocheModel>.from(json["data"].map((x) => DatumRecherchePocheModel.fromJson(x))),
    statusCode: json["status_code"],
    success: json["success"],
  );

  Map<String, dynamic> toJson() => {
    "max": max,
    "perpage": perpage,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "status_code": statusCode,
    "success": success,
  };
}