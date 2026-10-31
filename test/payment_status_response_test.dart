/// Regression test for « Échec du paiement » on a payment the gateway had
/// already approved.
///
/// `GET /payments/get-payment-status` answers FLAT (a `PaymentStatusResponse`
/// with no `{success, data}` envelope), so `IApiResponse` reports it as
/// `data: null`. `PaymentApi.getStatus` guarded on `res.data is! Map` and
/// therefore failed EVERY poll; the status page kept showing « Vérification
/// du statut… » and gave up after 11 checks, while the webhook had marked the
/// intent `succeeded` 29 s after it was created (PAY-1793454071837-702eb0,
/// 2026-10-31). On top of that, neither the display mapping nor the status
/// page knew the backend's `succeeded` value.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaymentApi.dart';

/// A real 200 body from GET /api/v1/payments/get-payment-status.
Map<String, dynamic> _flatStatusBody(String state) => <String, dynamic>{
      'customer_reference': 'PAY-1793454071837-702eb0',
      'state': state,
      'purpose': 'blood_bag_purchase',
      'entity_id': '6ae5eff7e0efb6990137ca4e',
      'amount_cents': 210,
      'currency': 'USD',
      'is_terminal': state == 'succeeded',
      'initiated_at': '2026-10-31T13:41:11.837000',
      'gateway_transaction_id': '6ae5effa23cc2859f321bb65',
    };

void main() {
  group('status response parsing', () {
    test('reads the FLAT body that IApiResponse reports as data:null', () {
      final res = IApiResponse(
        success: false,
        message: '',
        data: null,
        raw: _flatStatusBody('succeeded'),
      );
      final payload = PaymentApi.statusPayload(res);
      expect(payload, isNotNull);
      expect(payload!['state'], 'succeeded');
    });

    test('maps the backend state « succeeded » to paid', () {
      final status = PaymentStatusResult.fromJson(_flatStatusBody('succeeded'));
      expect(status.display, PaymentDisplayState.paid);
      expect(status.isTerminal, isTrue);
    });

    test('keeps pending/processing as pending', () {
      for (final s in ['pending', 'processing']) {
        expect(PaymentStatusResult.fromJson(_flatStatusBody(s)).display,
            PaymentDisplayState.pending);
      }
    });
  });
}
