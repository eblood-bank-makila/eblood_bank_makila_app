import 'package:flutter_test/flutter_test.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/DeliveryController.dart';

void main() {
  test('hospital confirm sends a confirmation_method the backend enum accepts', () {
    // Backend EDeliveryConfirmationMethod = {manual, qr_scan}; 'code' was rejected with 400.
    expect(kDeliveryConfirmationMethodManual, 'manual');
    expect(['manual', 'qr_scan'], contains(kDeliveryConfirmationMethodManual));
  });
}
