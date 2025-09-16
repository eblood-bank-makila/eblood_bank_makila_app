class BloodRhesusInfoRecherchePocheModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodRheususName;

  BloodRhesusInfoRecherchePocheModel({
    this.id = "",
    this.isActivated = true,
    this.identifier = "",
    DateTime? createdAt,
    required this.bloodRheususName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BloodRhesusInfoRecherchePocheModel.fromJson(Map<String, dynamic> json) => BloodRhesusInfoRecherchePocheModel(
    id: json["_id"]?.toString() ?? "",
    isActivated: json["is_activated"] ?? true,
    identifier: json["identifier"]?.toString() ?? "",
    createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
    bloodRheususName: json["blood_rheusus_name"]?.toString() ?? "",
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "is_activated": isActivated,
    "identifier": identifier,
    "createdAt": createdAt.toIso8601String(),
    "blood_rheusus_name": bloodRheususName,
  };
}