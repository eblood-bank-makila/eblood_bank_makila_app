import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../model/CurrencyExchangeModel.dart';

abstract class CurrencyExchangeService {
  Future<CurrencyExchangeResponse> getCurrencyExchanges();
}

class CurrencyExchangeServiceImpl implements CurrencyExchangeService {
  final DioClient dioClient;

  CurrencyExchangeServiceImpl({
    required this.dioClient,
  });

  @override
  Future<CurrencyExchangeResponse> getCurrencyExchanges() async {
    try {
      debugPrint('🌍 Fetching currency exchanges from: /eblood-connect/currencies-exchange');

      final response = await dioClient.get<Map<String, dynamic>>(
        '/eblood-connect/currencies-exchange',
      );

      debugPrint('🌍 Currency exchange response: $response');

      if (response != null) {
        debugPrint('✅ Successful response, parsing JSON...');
        debugPrint('📋 Parsed JSON structure: ${response.runtimeType}');
        debugPrint('📋 JSON keys: ${response is Map ? response.keys.toList() : "Not a Map"}');

        if (response is Map && response.containsKey('data')) {
          debugPrint('📋 Data field type: ${response['data'].runtimeType}');
          debugPrint('📋 Data field content: ${response['data']}');
        }

        if (response is Map && response.containsKey('currency_exchanges')) {
          debugPrint('📋 Currency exchanges field type: ${response['currency_exchanges'].runtimeType}');
          debugPrint('📋 Currency exchanges field content: ${response['currency_exchanges']}');
        }

        // Parse currency_exchanges field if it exists, otherwise use data field
        final currencyExchangesData = response['currency_exchanges'] ?? response['data'];

        final currencyResponse = CurrencyExchangeResponse.fromJson({
          'success': response['success'] ?? true,
          'message': response['message'] ?? 'Currency exchanges fetched successfully',
          'data': currencyExchangesData,
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
        debugPrint('❌ Failed to fetch currency exchanges: null response');
        return CurrencyExchangeResponse(
          success: false,
          data: [],
          message: 'Failed to fetch currency exchanges: null response',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching currency exchanges: $e');
      return CurrencyExchangeResponse(
        success: false,
        data: [],
        message: 'Error fetching currency exchanges: $e',
      );
    }
  }
}

// Provider for the currency exchange service
final currencyExchangeServiceProvider = Provider<CurrencyExchangeService>((ref) {
  final dioClient = DioClient();

  return CurrencyExchangeServiceImpl(
    dioClient: dioClient,
  );
});

// Provider for currency exchange data
final currencyExchangeProvider = FutureProvider<CurrencyExchangeResponse>((ref) async {
  final service = ref.read(currencyExchangeServiceProvider);
  return await service.getCurrencyExchanges();
});
