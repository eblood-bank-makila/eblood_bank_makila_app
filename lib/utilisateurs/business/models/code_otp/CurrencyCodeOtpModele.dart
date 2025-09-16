

class CurrencyCodeOtpModele {
  String id;
  String currencyName;
  int currencyNumber;
  String currencyCode;
  bool isActivated;
  String currencypic;

  CurrencyCodeOtpModele({
    required this.id,
   required this.currencyName,
  required  this.currencyNumber,
   required this.currencyCode,
  required  this.isActivated,
  required  this.currencypic,
  });

  factory CurrencyCodeOtpModele.fromJson(Map<String, dynamic> json) => CurrencyCodeOtpModele(
    id: json["_id"],
    currencyName: json["currency_name"],
    currencyNumber: json["currency_number"],
    currencyCode: json["currency_code"],
    isActivated: json["is_activated"],
    currencypic: json["currencypic"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "currency_name": currencyName,
    "currency_number": currencyNumber,
    "currency_code": currencyCode,
    "is_activated": isActivated,
    "currencypic": currencypic,
  };
}