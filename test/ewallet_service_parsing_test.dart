import 'package:flutter_test/flutter_test.dart';
import 'package:eblood_bank_mak_app/blood_bank/data/services/ewallet_service.dart';
import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';

void main() {
  test('paths', () {
    expect(ApiConfig.ewalletPayoutNumbers, '/eblood-connect/ewallet/payout-numbers');
    expect(ApiConfig.ewalletPayoutNumber('abc'), '/eblood-connect/ewallet/payout-numbers/abc');
    expect(ApiConfig.ewalletCashOuts, '/eblood-connect/ewallet/cash-outs');
  });
  test('parsePayoutNumbers accepts nested and flat envelopes', () {
    final row = {'id': 'n', 'sys_organization_id': 'o', 'phone_number': '+1', 'max_amount_per_day': 5, 'validation_status': 'validated'};
    expect(EwalletService.parsePayoutNumbers({'data': {'data': [row]}}).single.id, 'n');
    expect(EwalletService.parsePayoutNumbers({'data': [row]}).single.id, 'n');
    expect(EwalletService.parsePayoutNumbers([row]).single.id, 'n');
    expect(EwalletService.parsePayoutNumbers(null), isEmpty);
  });
  test('parseCashOuts', () {
    expect(EwalletService.parseCashOuts({'data': {'data': [{'id': 'c', 'amount': 1, 'status': 'withdrawn', 'phone_number': '+1', 'is_auto_checkout': false}], 'total': 1}}).single.status, 'withdrawn');
  });
}
