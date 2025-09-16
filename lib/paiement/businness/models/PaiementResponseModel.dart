import 'dart:convert';
import 'package:eblood_bank_mak_app/paiement/businness/models/DatumPaiementModel.dart';

PaiementResponseModel paiementResponseModelFromJson(String str) =>
    PaiementResponseModel.fromJson(json.decode(str));

String paiementResponseModelToJson(PaiementResponseModel data) =>
    json.encode(data.toJson());

class PaiementResponseModel {
  DatumPaiementModel? data; // Make data nullable
  String sms;
  int statusCode;
  bool success;

  PaiementResponseModel({
    required this.data,
    required this.sms,
    required this.statusCode,
    required this.success,
  });

  factory PaiementResponseModel.fromJson(Map<String, dynamic> json) =>
      PaiementResponseModel(
        data: json["data"] != null
            ? DatumPaiementModel.fromJson(json["data"])
            : null, // Check for null
        sms: json["sms"] ?? '',
        statusCode: json["status_code"] ?? 0,
        success: json["success"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "data": data?.toJson(), // Handle nullable data
        "sms": sms,
        "status_code": statusCode,
        "success": success,
      };
}
