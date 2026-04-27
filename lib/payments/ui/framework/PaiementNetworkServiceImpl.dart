import 'dart:io';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementModel.dart';
import 'package:eblood_bank_mak_app/payments/business/models/PaiementResponseModel.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaiementNetworkService.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaiementServiceNetworkImpl implements PaiementNetworkService {
  String baseURL;

  PaiementServiceNetworkImpl(this.baseURL);

  @override
  Future<PaiementResponseModel?> ajouterPaiement(
      PaiementModel data, String authBearer) async {
    try {
      // Use dio_client for automatic auth header injection
      final response = await postWithDio(
        '/eblood-connect/cart/submit-payment',
        body: {
          'cart_id': data.cartId,
          if (data.phoneNumber != null) 'phone_number': data.phoneNumber,
          if (data.transactionalCurrencyId != null)
            'transactional_currency_id': data.transactionalCurrencyId,
          if (data.requestFor != null) 'request_for': data.requestFor,
          if (data.requestReason != null) 'request_reason': data.requestReason,
          if (data.patientId != null) 'patient_id': data.patientId,
          if (data.requestType != null) 'request_type': data.requestType,
          if (data.urgencyLevel != null) 'urgency_level': data.urgencyLevel,
        },
      );

      if (response.success && response.data != null) {
        print("✅ Payment Response: ${response.message}");

        // Extract data from IApiResponse
        final responseData = response.data as Map<String, dynamic>?;

        if (responseData != null) {
          // Create PaiementResponseModel from new response format
          var responseFinal = PaiementResponseModel.fromJson({
            'success': true,
            'message': response.message ?? 'Payment submitted successfully',
            'data': responseData,
          });
          return responseFinal;
        }
      }

      print("❌ Payment failed: ${response.message ?? 'Invalid response'}");
      return null;

    } catch (e) {
      print("❌ Payment error: $e");
      return null;
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = new MyHttpOverrides();
  String baseUrl = dotenv.env['BASE_URL'] ?? '';
  var impl = PaiementServiceNetworkImpl(baseUrl);
  var authBearer =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0wOS0zMFQxMTozNDoxOS41ODVaIiwiaWF0IjoxNzI3Njk1NzU5LCJleHAiOjE3Mjc5NTQ5NTl9.DeRfSlq90U9DylDtzqbEbSIuazLd9n2PoN9wFSbFoJ8';
  var card = PaiementModel(cartId: "66fd405f337dfdc01e1bd9c4");

  //String cart_id = "66fd405f337dfdc01e1bd9c4";

  impl.ajouterPaiement(card, authBearer);
}
