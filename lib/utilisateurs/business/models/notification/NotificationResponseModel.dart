// To parse this JSON data, do
//
//     final notificationResponseModel = notificationResponseModelFromJson(jsonString);

import 'dart:convert';

import 'package:eblood_bank_mak_app/utilisateurs/business/models/notification/DatumNotificationModel.dart';

NotificationResponseModel notificationResponseModelFromJson(String str) =>
    NotificationResponseModel.fromJson(json.decode(str));

String notificationResponseModelToJson(NotificationResponseModel data) =>
    json.encode(data.toJson());

class NotificationResponseModel {
  int perpage;
  int max;
  List<DatumNotificationModel> data;
  int statusCode;
  bool success;

  NotificationResponseModel({
    required this.perpage,
    required this.max,
    required this.data,
    required this.statusCode,
    required this.success,
  });

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) =>
      NotificationResponseModel(
        perpage: json["perpage"] ?? 0,
        max: json["max"] ?? 0,
        data: (json["data"] as List?)?.map((x) {
              print(
                  "Mapping DactumModel: $x"); // Ajoutez cette ligne pour voir chaque élément
              return DatumNotificationModel.fromJson(x);
            }).toList() ??
            [],
        //data: List<DatumNotificationModel>.from(json["data"].map((x) => DatumNotificationModel.fromJson(x))),
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
