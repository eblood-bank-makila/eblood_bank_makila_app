// To parse this JSON data, do
//
//     final suppresionResponseNotificationModel = suppresionResponseNotificationModelFromJson(jsonString);

import 'dart:convert';

SuppresionResponseNotificationModel suppresionResponseNotificationModelFromJson(String str) => SuppresionResponseNotificationModel.fromJson(json.decode(str));

String suppresionResponseNotificationModelToJson(SuppresionResponseNotificationModel data) => json.encode(data.toJson());

class SuppresionResponseNotificationModel {
  int statusCode;
  String sms;
  bool success;

  SuppresionResponseNotificationModel({
  required  this.statusCode,
   required this.sms,
   required this.success,
  });

  factory SuppresionResponseNotificationModel.fromJson(Map<String, dynamic> json) => SuppresionResponseNotificationModel(
    statusCode: json["status_code"],
    sms: json["sms"],
    success: json["success"],
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "sms": sms,
    "success": success,
  };
}
