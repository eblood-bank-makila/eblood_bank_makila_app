import 'dart:convert';

SuppressionNotificationModel suppressionNotificationModelFromJson(String str) =>
    SuppressionNotificationModel.fromJson(json.decode(str));

String suppressionNotificationModelToJson(SuppressionNotificationModel data) =>
    json.encode(data.toJson());

class SuppressionNotificationModel {
  int perpage;
  int max;
  List<SuppressionNotificationModel> data;
  int statusCode;
  bool success;

  SuppressionNotificationModel({
    required this.perpage,
    required this.max,
    required this.data,
    required this.statusCode,
    required this.success,
  });

  factory SuppressionNotificationModel.fromJson(Map<String, dynamic> json) =>
      SuppressionNotificationModel(
        perpage: json["perpage"],
        max: json["max"],
        data: List<SuppressionNotificationModel>.from(
            json["data"].map((x) => SuppressionNotificationModel.fromJson(x))),
        statusCode: json["status_code"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "perpage": perpage,
        "max": max,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "status_code": statusCode,
        "success": success,
      };
}
