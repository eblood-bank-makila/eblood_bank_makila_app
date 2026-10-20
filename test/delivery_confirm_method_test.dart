import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/DeliveryController.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/confirm_reception_dialog.dart';

/// Records the assignment close, which must never run without the code check.
class _Api extends DeliveryApiService {
  final receipts = <String>[];

  @override
  Future<ApiResponse<bool>> confirmDeliveryReceipt(String deliveryId, String hospitalUserId) async {
    receipts.add(deliveryId);
    return ApiResponse.success(true);
  }
}

void main() {
  test('hospital confirm sends a confirmation_method the backend enum accepts', () {
    // Backend EDeliveryConfirmationMethod = {manual, qr_scan}; 'code' was rejected with 400.
    expect(kDeliveryConfirmationMethodManual, 'manual');
    expect(['manual', 'qr_scan'], contains(kDeliveryConfirmationMethodManual));
  });

  group('confirmDelivery never skips the code check (it releases the seller payment)', () {
    test('without the blood request id it refuses and closes nothing', () async {
      final api = _Api();
      final controller = IncomingDeliveriesController(api, 'h1', 'u1');

      expect(await controller.confirmDelivery('d1', bloodRequestId: '', verificationCode: '847332'), isFalse);
      expect(await controller.confirmDelivery('d1', verificationCode: '847332'), isFalse);
      expect(api.receipts, isEmpty);
    });

    test('without a code it refuses and closes nothing', () async {
      final api = _Api();
      final controller = IncomingDeliveriesController(api, 'h1', 'u1');

      expect(await controller.confirmDelivery('d1', bloodRequestId: 'br1', verificationCode: ''), isFalse);
      expect(await controller.confirmDelivery('d1', bloodRequestId: 'br1'), isFalse);
      expect(api.receipts, isEmpty);
    });
  });

  testWidgets('the reception confirm says it cannot check the code when the request id is missing', (t) async {
    await t.pumpWidget(ProviderScope(
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('fr', 'FR'),
        fallbackLocale: const Locale('fr', 'FR'),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => confirmReception(context, ref, deliveryId: 'd1', bloodRequestId: ''),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));

    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 750));

    expect(find.byType(AlertDialog), findsNothing); // no code asked for that could not be checked
    expect(find.text('Impossible de vérifier le code pour cette livraison.'), findsOneWidget);
  });
}
