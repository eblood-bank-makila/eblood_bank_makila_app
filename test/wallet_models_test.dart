import 'package:flutter_test/flutter_test.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/ewallet_models.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/payout_number_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/cash_out_model.dart';

void main() {
  test('history maps every settlement flag to a local origin', () {
    const flags = ['blood_request_payment_hold', 'blood_request_escrow_release', 'blood_bag_sale', 'cnts_commission',
      'platform_flat_fee', 'platform_percent_fee', 'km_delivery_fee', 'blood_request_refund', 'cash_out_debit', 'cash_out_refund'];
    for (final f in flags) {
      final h = EWalletHistoryModel.fromBackendJson({'_id': 'h', 'movement_type': 'credit', 'operation_origin_flag': f, 'amount': 1.0,
        'balance_before': 0.0, 'balance_after': 1.0});
      expect(h.operationOrigin, isNot(EWalletOperationOrigin.none), reason: f);
      expect(h.localOriginKey, 'wallet_origin_$f');
    }
  });

  test('payout number parses status and payload round-trips', () {
    final n = PayoutNumberModel.fromJson({'id': 'n1', 'sys_organization_id': 'o', 'phone_number': '+243998857000', 'holder_name': 'BB',
      'operator_hint': 'mpesa', 'max_amount_per_day': 500, 'priority': 1, 'validation_status': 'validated', 'rejection_reason': null});
    expect(n.isValidated, isTrue);
    expect(n.toPayload(), {'phone_number': '+243998857000', 'holder_name': 'BB', 'operator_hint': 'mpesa', 'max_amount_per_day': 500.0, 'priority': 1});
    expect(PayoutNumberModel.fromJson({'id': 'x', 'sys_organization_id': 'o', 'phone_number': '+1', 'max_amount_per_day': 1, 'validation_status': 'weird'}).validationStatus,
      PayoutNumberStatus.pendingValidation);
  });

  test('cash-out parses float amount and nullable refs', () {
    final c = CashOutModel.fromJson({'id': 'c', 'amount': 8.5, 'status': 'withdrawn', 'phone_number': '+1', 'provider_ref': null,
      'failure_reason': null, 'is_auto_checkout': true, 'ops_ewallet_id': 'w', 'created_at': null, 'withdrawed_at': null});
    expect(c.amount, 8.5); expect(c.providerRef, isNull); expect(c.isAutoCheckout, isTrue);
  });
}
