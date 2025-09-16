import 'dart:convert';

PanierModel anierModelFromJson(String str) =>
    PanierModel.fromJson(json.decode(str));

String panierModelToJson(PanierModel data) => json.encode(data.toJson());

class PanierModel {
  String blood_bank_id;
  String blood_bag_id;
  int quantity;

  PanierModel({
    required this.blood_bank_id,
    required this.blood_bag_id,
    required this.quantity,
  });

  factory PanierModel.fromJson(Map<String, dynamic> json) => PanierModel(
        blood_bank_id: json["blood_bank_id"],
        blood_bag_id: json["blood_bag_id"],
        quantity: json["quantity"],
      );

  Map<String, dynamic> toJson() => {
        "blood_bank_id": blood_bank_id,
        "blood_bag_id": blood_bag_id,
        "quantity": quantity,
      };
}
