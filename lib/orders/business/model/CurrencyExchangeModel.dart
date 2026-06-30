class CurrencyExchangeModel {
  final String id;
  // Normalized to IDs for consistent usage in UI (e.g., payment submission)
  final String currencyFrom; // base currency id
  final String currencyFromCode; // base currency code (e.g., 'usd')
  final String currencyTo; // target currency id
  final String currencyToCode; // target currency code (e.g., 'cdf')
  final double exchangedValue; // rate
  final double amount; // requested amount (from API response)
  final double convertedAmount; // converted amount (from API response)

  CurrencyExchangeModel({
    required this.id,
    required this.currencyFrom,
    required this.currencyFromCode,
    required this.currencyTo,
    required this.currencyToCode,
    required this.exchangedValue,
    required this.amount,
    required this.convertedAmount,
  });

  factory CurrencyExchangeModel.fromJson(Map<String, dynamic> json) {
    print('🔧 Parsing CurrencyExchangeModel from JSON: $json');

    // Handle both legacy shape (flat fields) and new shape (nested currency objects)
    final cf = json['currency_from'];
    final ct = json['currency_to'];

    String currencyFromId = '';
    String currencyFromCode = '';
    String currencyToId = '';
    String currencyToCode = '';

    if (cf is String) {
      currencyFromId = cf;
    } else if (cf is Map) {
      currencyFromId = (cf['id'] ?? '').toString();
      currencyFromCode = (cf['code'] ?? '').toString();
    }

    if (ct is String) {
      currencyToId = ct;
    } else if (ct is Map) {
      currencyToId = (ct['id'] ?? '').toString();
      currencyToCode = (ct['code'] ?? '').toString();
    }

    // Fallback to legacy flat fields for codes if present
    if (currencyFromCode.isEmpty) {
      currencyFromCode = (json['currency_from_code'] ?? '').toString();
    }
    if (currencyToCode.isEmpty) {
      currencyToCode = (json['currency_to_code'] ?? '').toString();
    }

    final model = CurrencyExchangeModel(
      id: (json['_id'] ?? currencyToId).toString(),
      currencyFrom: currencyFromId,
      currencyFromCode: currencyFromCode,
      currencyTo: currencyToId,
      currencyToCode: currencyToCode,
      exchangedValue: (json['exchangedvalue'] ?? 0.0).toDouble(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      convertedAmount: (json['converted_amount'] ?? 0.0).toDouble(),
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
      'amount': amount,
      'converted_amount': convertedAmount,
    };
  }

  @override
  String toString() {
    return 'CurrencyExchangeModel(id: $id, fromCode: $currencyFromCode, toCode: $currencyToCode, rate: $exchangedValue, amount: $amount, converted: $convertedAmount)';
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
