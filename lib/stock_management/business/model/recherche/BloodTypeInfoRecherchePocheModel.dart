class BloodTypeInfoRecherchePocheModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodTypeName;

  BloodTypeInfoRecherchePocheModel({
    this.id = "",
    this.isActivated = true,
    this.identifier = "",
    DateTime? createdAt,
    required this.bloodTypeName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BloodTypeInfoRecherchePocheModel.fromJson(Map<String, dynamic> json) => BloodTypeInfoRecherchePocheModel(
    id: json["_id"]?.toString() ?? "",
    isActivated: json["is_activated"] ?? true,
    identifier: json["identifier"]?.toString() ?? "",
    createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
    bloodTypeName: json["blood_type_name"]?.toString() ?? "",
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "is_activated": isActivated,
    "identifier": identifier,
    "createdAt": createdAt.toIso8601String(),
    "blood_type_name": bloodTypeName,
  };
}