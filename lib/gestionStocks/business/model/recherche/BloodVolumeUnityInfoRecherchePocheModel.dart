class BloodVolumeUnityInfoRecherchePocheModel {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodVolumeUnityName;

  BloodVolumeUnityInfoRecherchePocheModel({
    this.id = "",
    this.isActivated = true,
    this.identifier = "",
    DateTime? createdAt,
    required this.bloodVolumeUnityName,
  }) : createdAt = createdAt ?? DateTime.now();




  factory BloodVolumeUnityInfoRecherchePocheModel.fromJson(
      Map<String, dynamic> json) =>
      BloodVolumeUnityInfoRecherchePocheModel(
        id: json["_id"]?.toString() ?? "",
        isActivated: json["is_activated"] ?? true,
        identifier: json["identifier"]?.toString() ?? "",
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
        bloodVolumeUnityName: json["blood_volume_unity_name"]?.toString() ?? "",
      );

  Map<String, dynamic> toJson() =>
      {
        "_id": id,
        "is_activated": isActivated,
        "identifier": identifier,
        "createdAt": createdAt.toIso8601String(),
        "blood_volume_unity_name": bloodVolumeUnityName,
      };
}