import 'dart:convert';

PaiementModel paiementModelFromJson(String str) =>
    PaiementModel.fromJson(json.decode(str));

String paiementModelToJson(PaiementModel data) =>
    json.encode(data.toJson());

class PaiementModel {
  final String cartId;
  final String? phoneNumber;
  final String? transactionalCurrencyId;

  PaiementModel({
    required this.cartId,
    this.phoneNumber,
    this.transactionalCurrencyId,
  });

  factory PaiementModel.fromJson(Map json) => PaiementModel(
    cartId: json['cart_id'],
    phoneNumber: json['phone_number'],
    transactionalCurrencyId: json['transactional_currency_id'],
  );

  Map<String, dynamic> toJson() => {
    'cart_id': cartId,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (transactionalCurrencyId != null) 'transactional_currency_id': transactionalCurrencyId,
  };
}
