class CurrencyExchangeModel {
  final String id;
  final dynamic currencyFrom;
  final String currencyFromCode;
  final dynamic currencyTo;
  final String currencyToCode;
  final double exchangedValue;

  CurrencyExchangeModel({
    required this.id,
    required this.currencyFrom,
    required this.currencyFromCode,
    required this.currencyTo,
    required this.currencyToCode,
    required this.exchangedValue,
  });

  factory CurrencyExchangeModel.fromJson(Map<String, dynamic> json) {
    print('🔧 Parsing CurrencyExchangeModel from JSON: $json');

    final model = CurrencyExchangeModel(
      id: json['_id'] ?? '',
      currencyFrom: json['currency_from'],
      currencyFromCode: json['currency_from_code'] ?? '',
      currencyTo: json['currency_to'],
      currencyToCode: json['currency_to_code'] ?? '',
      exchangedValue: (json['exchangedvalue'] ?? 0.0).toDouble(),
    );

    print('🔧 Created model: ${model.toString()}');
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'currency_from': currencyFrom,
      'currency_from_code': currencyFromCode,
      'currency_to': currencyTo,
      'currency_to_code': currencyToCode,
      'exchangedvalue': exchangedValue,
    };
  }

  @override
  String toString() {
    return 'CurrencyExchangeModel(id: $id, fromCode: $currencyFromCode, toCode: $currencyToCode, rate: $exchangedValue)';
  }
}

class CurrencyExchangeResponse {
  final bool success;
  final List<CurrencyExchangeModel> data;
  final String message;

  CurrencyExchangeResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory CurrencyExchangeResponse.fromJson(Map<String, dynamic> json) {
    print('🔧 Parsing CurrencyExchangeResponse from JSON: $json');

    final success = json['success'] ?? false;
    final message = json['message'] ?? '';
    final dataRaw = json['data'];

    print('🔧 Success: $success');
    print('🔧 Message: $message');
    print('🔧 Data raw: $dataRaw (type: ${dataRaw.runtimeType})');

    List<CurrencyExchangeModel> currencies = [];

    if (dataRaw is List) {
      print('🔧 Data is a List with ${dataRaw.length} items');
      for (int i = 0; i < dataRaw.length; i++) {
        print('🔧 Processing item $i: ${dataRaw[i]}');
        try {
          final currency = CurrencyExchangeModel.fromJson(dataRaw[i]);
          currencies.add(currency);
        } catch (e) {
          print('❌ Error parsing currency item $i: $e');
        }
      }
    } else if (dataRaw is Map) {
      print('🔧 Data is a single Map object');
      try {
        final currency = CurrencyExchangeModel.fromJson(Map<String, dynamic>.from(dataRaw));
        currencies.add(currency);
      } catch (e) {
        print('❌ Error parsing single currency: $e');
      }
    } else {
      print('🔧 Data is neither List nor Map: ${dataRaw.runtimeType}');
    }

    final response = CurrencyExchangeResponse(
      success: success,
      data: currencies,
      message: message,
    );

    print('🔧 Final response: success=$success, data_length=${currencies.length}, message=$message');
    return response;
  }
}
