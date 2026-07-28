/// Regression test for the blank "payment failed" banner.
///
/// The payment initiate endpoints answer FLAT — the Lokotro checkout config
/// sits at the top level with no `{success, data, message}` envelope —
/// because the web checkout consumes exactly that shape. `IApiResponse`
/// assumes the envelope, so an HTTP 201 arrived as `success: false`,
/// `data: null`, `message: ''`. The payment was then reported as failed,
/// and because `??` does not fire on an empty string the user saw an error
/// banner containing no text at all.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaymentApi.dart';

/// A real 201 body from POST /api/v1/payments/initiate/payment, which
/// FastAPI serialises straight from PaymentInitiateResponse.
Map<String, dynamic> _flatInitiateBody() => <String, dynamic>{
      'customer_reference': 'EB-1234567890',
      'state': 'pending',
      'purpose': 'address_access',
      'amount': 1.0,
      'amount_cents': 100,
      'currency': 'usd',
      'app_key': 'sess_ucISTajsCQK',
      'is_production': true,
      'notify_url': 'https://app.api.e-bloodbank.org/api/v1/payments/'
          'payment-gateway-callback',
      'merchant': <String, dynamic>{'name': 'eblood'},
    };

void main() {
  group('initiate response parsing', () {
    test('reads the FLAT body that IApiResponse reports as a failure', () {
      // Exactly what fromData() produces for a flat 201: no envelope keys.
      final res = IApiResponse(
        success: false,
        message: '',
        data: null,
        raw: _flatInitiateBody(),
      );

      final payload = PaymentApi.initiatePayload(res);

      expect(payload, isNotNull);
      expect(payload!['customer_reference'], 'EB-1234567890');
      expect(payload['app_key'], 'sess_ucISTajsCQK');
    });

    test('still reads a normal {data: ...} envelope', () {
      final res = IApiResponse(
        success: true,
        message: 'ok',
        data: _flatInitiateBody(),
        raw: <String, dynamic>{'data': _flatInitiateBody()},
      );

      final payload = PaymentApi.initiatePayload(res);

      expect(payload, isNotNull);
      expect(payload!['app_key'], 'sess_ucISTajsCQK');
    });

    test('returns null for a body that carries no checkout config', () {
      final res = IApiResponse(
        success: false,
        message: 'Boom',
        data: null,
        raw: <String, dynamic>{'detail': 'something went wrong'},
      );

      expect(PaymentApi.initiatePayload(res), isNull);
    });

    test('blank message falls back to the French default, never empty', () {
      final res = IApiResponse(success: false, message: '', raw: null);

      expect(
        PaymentApi.initiateErrorMessage(res),
        'Échec de l\'initiation du paiement.',
      );
    });

    test('a real server message is preserved', () {
      final res = IApiResponse(
        success: false,
        message: 'Could not start the payment',
        raw: null,
      );

      expect(
        PaymentApi.initiateErrorMessage(res),
        'Could not start the payment',
      );
    });
  });
}
