import 'package:flutter_test/flutter_test.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/payout_number_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/ui/pages/WalletManagementPage.dart';

void main() {
  const n = PayoutNumberModel(
    id: 'n',
    sysOrganizationId: 'o',
    phoneNumber: '+1',
    holderName: '',
    maxAmountPerDay: 5,
    priority: 1,
    validationStatus: PayoutNumberStatus.validated,
  );

  test('validateWithdrawal', () {
    expect(validateWithdrawal(amount: 5, balance: 10, number: n), isNull);
    expect(validateWithdrawal(amount: 11, balance: 10, number: n), 'insufficient_balance');
    expect(validateWithdrawal(amount: 0, balance: 10, number: n), 'insufficient_balance');
    expect(validateWithdrawal(amount: 5, balance: 10, number: null), 'select_payout_number');
  });
}
