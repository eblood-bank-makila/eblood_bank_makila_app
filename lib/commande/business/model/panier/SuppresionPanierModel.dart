import 'dart:convert';

SuppressionPanierModel suppressionPanierModelFromJson(String str) =>
    SuppressionPanierModel.fromJson(json.decode(str));

String suppressionPanierModelToJson(SuppressionPanierModel data) =>
    json.encode(data.toJson());

class SuppressionPanierModel {
  final String blood_bag_id;

  SuppressionPanierModel({
    required this.blood_bag_id,
  });

  factory SuppressionPanierModel.fromJson(Map json) => SuppressionPanierModel(
    blood_bag_id: json['blood_bag_id'],
  );

  Map<String, dynamic> toJson() => {
    'blood_bag_id': blood_bag_id,
  };
}
