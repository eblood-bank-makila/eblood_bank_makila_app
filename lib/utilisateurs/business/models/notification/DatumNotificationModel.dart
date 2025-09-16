class DatumNotificationModel {
  String id;
  String concernedId;
  String notification;
  String title;
  bool isRead;
  bool softDeleted;
  DateTime createdAt;
  DateTime updatedAt;
  int v;

  DatumNotificationModel({
    required this.id,
    required this.concernedId,
    required this.notification,
    required this.title,
    required this.isRead,
    required this.softDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory DatumNotificationModel.fromJson(Map<String, dynamic> json) =>
      DatumNotificationModel(
        id: json["_id"],
        concernedId: json["concerned_id"],
        notification: json["notification"],
        title: json["title"],
        isRead: json["is_read"],
        softDeleted: json["soft_deleted"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "concerned_id": concernedId,
        "notification": notification,
        "title": title,
        "is_read": isRead,
        "soft_deleted": softDeleted,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "__v": v,
      };
}
