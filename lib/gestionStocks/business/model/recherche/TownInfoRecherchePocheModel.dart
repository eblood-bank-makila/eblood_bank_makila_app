class TownInfoRecherchePocheModel {
  String id;
  String townName;

  TownInfoRecherchePocheModel({
    this.id = "",
    this.townName = "",
  });

  factory TownInfoRecherchePocheModel.fromJson(Map<String, dynamic> json) => TownInfoRecherchePocheModel(
        id: json["_id"]?.toString() ?? "",
        townName: json["town_name"]?.toString() ?? "",
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "town_name": townName,
      };
}
