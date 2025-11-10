import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/config/api/dio_client.dart';
import '../model/CurrencyExchangeModel.dart';

abstract class CurrencyExchangeService {
  Future<CurrencyExchangeResponse> getCurrencyExchanges(
    double amount,
    String refCurrencyId,
  );
}

class CurrencyExchangeServiceImpl implements CurrencyExchangeService {
  CurrencyExchangeServiceImpl();

  @override
  Future<CurrencyExchangeResponse> getCurrencyExchanges(
    double amount,
    String refCurrencyId,
  ) async {
    try {
      final trimmedId = refCurrencyId.trim();
      if (trimmedId.isEmpty) {
        debugPrint('⚠️ Skipping currency conversion POST: ref_currency_id is empty');
        return CurrencyExchangeResponse(
          success: false,
          data: [],
          message: 'Missing ref_currency_id',
        );
      }

      debugPrint('🌍 Posting currency conversions to: /eblood-connect/amount-exchances');

      final apiResponse = await postWithDio(
        '/eblood-connect/amount-exchances',
        body: {
          'amount': amount,
          'ref_currency_id': trimmedId,
        },
      );

      debugPrint('🌍 Currency conversion response: ${apiResponse.raw ?? apiResponse.data}');

      if (apiResponse.success) {
        debugPrint('✅ Successful response, parsing JSON...');

        final currencyResponse = CurrencyExchangeResponse.fromJson({
          'success': apiResponse.success,
          'message': apiResponse.message ?? 'Currency conversions fetched successfully',
          'data': apiResponse.data,
        });

        debugPrint('✅ Successfully parsed response:');
        debugPrint('✅ Success: ${currencyResponse.success}');
        debugPrint('✅ Data length: ${currencyResponse.data.length}');
        debugPrint('✅ Message: ${currencyResponse.message}');

        for (int i = 0; i < currencyResponse.data.length; i++) {
          final currency = currencyResponse.data[i];
          debugPrint('💱 Currency $i: ${currency.toString()}');
        }

        return currencyResponse;
      } else {
        debugPrint('❌ Failed to fetch currency conversions: ${apiResponse.message}');
        return CurrencyExchangeResponse(
          success: false,
          data: [],
          message: apiResponse.message ?? 'Failed to fetch currency conversions',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching currency conversions: $e');
      return CurrencyExchangeResponse(
        success: false,
        data: [],
        message: 'Error fetching currency conversions: $e',
      );
    }
  }
}

// Provider for the currency exchange service
final currencyExchangeServiceProvider = Provider<CurrencyExchangeService>((ref) {
  return CurrencyExchangeServiceImpl();
});

// Strongly-typed params to avoid rebuild loops (Map identity)
class CurrencyExchangeParams {
  final double amount;
  final String refCurrencyId;
  const CurrencyExchangeParams({required this.amount, required this.refCurrencyId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyExchangeParams &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          refCurrencyId == other.refCurrencyId;

  @override
  int get hashCode => Object.hash(amount, refCurrencyId);

  @override
  String toString() => 'CurrencyExchangeParams(amount: $amount, refCurrencyId: $refCurrencyId)';
}

// Provider for currency exchange data with parameters
final currencyExchangeProvider = FutureProvider.family<CurrencyExchangeResponse, CurrencyExchangeParams>((ref, params) async {
  final service = ref.read(currencyExchangeServiceProvider);
  final amountParam = params.amount;
  final refCurrencyId = params.refCurrencyId.trim();

  if (refCurrencyId.isEmpty) {
    debugPrint('currencyExchangeProvider: missing ref_currency_id; skipping API call.');
    return CurrencyExchangeResponse(
      success: false,
      data: [],
      message: 'Missing ref_currency_id',
    );
  }

  return await service.getCurrencyExchanges(amountParam, refCurrencyId);
});
