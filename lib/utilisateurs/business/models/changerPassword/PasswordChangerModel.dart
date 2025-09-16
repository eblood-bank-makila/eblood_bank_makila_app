// To parse this JSON data, do
//
//     final passwordChangerModel = passwordChangerModelFromJson(jsonString);

import 'dart:convert';

PasswordChangerModel passwordChangerModelFromJson(String str) => PasswordChangerModel.fromJson(json.decode(str));

String passwordChangerModelToJson(PasswordChangerModel data) => json.encode(data.toJson());

class PasswordChangerModel {
  String sms;

  bool success;

  PasswordChangerModel({
   required this.sms,

  required  this.success,
  });

  factory PasswordChangerModel.fromJson(Map<String, dynamic> json) => PasswordChangerModel(
    sms: json["sms"],

    success: json["success"],
  );

  Map<String, dynamic> toJson() => {
    "sms": sms,

    "success": success,
  };
}
