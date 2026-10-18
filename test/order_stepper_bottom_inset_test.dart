import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/blood_bank/providers/structure_validation_provider.dart';
import 'package:eblood_bank_mak_app/stock_management/ui/pages/banque/BloodBagOrderStepperPage.dart';

/// The app draws edge-to-edge (Android 15+), so the system navigation bar /
/// Galaxy Fold taskbar overlaps the bottom of the screen. The order stepper's
/// content — whose last item on the confirm step is the "Payer" button — must
/// end above that inset instead of under it.
void main() {
  testWidgets('step content stops above the system navigation bar', (t) async {
    const bottomInsetLogical = 60.0;
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 2.0;
    t.view.padding = const FakeViewPadding(bottom: bottomInsetLogical * 2);
    t.view.viewPadding = const FakeViewPadding(bottom: bottomInsetLogical * 2);
    addTearDown(t.view.reset);

    await t.pumpWidget(ProviderScope(
      overrides: [myStructureProvider.overrideWith((ref) async => null)],
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('fr', 'FR'),
        home: const BloodBagOrderStepperPage(bloodType: 'A-', bloodBanks: []),
      ),
    ));
    await t.pump(const Duration(milliseconds: 100));

    final screenHeight = t.view.physicalSize.height / t.view.devicePixelRatio;
    final content = t.getRect(find.byKey(BloodBagOrderStepperPage.stepContentKey));
    expect(content.bottom, lessThanOrEqualTo(screenHeight - bottomInsetLogical));
  });
}
