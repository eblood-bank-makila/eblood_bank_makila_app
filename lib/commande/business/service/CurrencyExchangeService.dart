import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/config/AppConfig.dart';
import '../../../utilisateurs/business/interactors/UtilisateurInteractor.dart';
import '../model/CurrencyExchangeModel.dart';

abstract class CurrencyExchangeService {
  Future<CurrencyExchangeResponse> getCurrencyExchanges();
}

class CurrencyExchangeServiceImpl implements CurrencyExchangeService {
  final String baseUrl;
  final Utilisateurinteractor userInteractor;

  CurrencyExchangeServiceImpl({
    required this.baseUrl,
    required this.userInteractor,
  });

  @override
  Future<CurrencyExchangeResponse> getCurrencyExchanges() async {
    try {
      // Get authentication token
      final token = await userInteractor.recuperationTokenOtpUseCase.run();

      final url = '$baseUrl/data/currencies-exchange';
      debugPrint('🌍 Fetching currency exchanges from: $url');
      debugPrint('🔑 Token available: ${token != null && token.isNotEmpty ? "Yes (${token.length} chars)" : "No"}');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'eblood-lockkeys': '0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31',
      };

      debugPrint('📤 Request headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('🌍 Currency exchange response status: ${response.statusCode}');
      debugPrint('🌍 Currency exchange response headers: ${response.headers}');
      debugPrint('🌍 Currency exchange response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Successful response, parsing JSON...');
        final jsonData = json.decode(response.body);
        debugPrint('📋 Parsed JSON structure: ${jsonData.runtimeType}');
        debugPrint('📋 JSON keys: ${jsonData is Map ? jsonData.keys.toList() : "Not a Map"}');

        if (jsonData is Map && jsonData.containsKey('data')) {
          debugPrint('📋 Data field type: ${jsonData['data'].runtimeType}');
          debugPrint('📋 Data field content: ${jsonData['data']}');
        }

        final currencyResponse = CurrencyExchangeResponse.fromJson(jsonData);

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
        debugPrint('❌ Failed to fetch currency exchanges: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        return CurrencyExchangeResponse(
          success: false,
          data: [],
          message: 'Failed to fetch currency exchanges: ${response.statusCode}',
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
  final userInteractor = ref.read(utilisateurInteractorProvider);
  final baseUrl = AppConfig.instance.baseUrl;
  
  return CurrencyExchangeServiceImpl(
    baseUrl: baseUrl,
    userInteractor: userInteractor,
  );
});

// Provider for currency exchange data
final currencyExchangeProvider = FutureProvider<CurrencyExchangeResponse>((ref) async {
  final service = ref.read(currencyExchangeServiceProvider);
  return await service.getCurrencyExchanges();
});
