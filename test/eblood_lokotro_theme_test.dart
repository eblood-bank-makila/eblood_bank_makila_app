import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lokotro_pay/constants/lokotro_pay_colors.dart';

import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/payments/business/service/eblood_lokotro_theme.dart';

/// The lokotro_pay checkout was opened without a `themeConfig`, so every brand
/// colour fell back to the host theme / the SDK's own greens — the loader
/// spinner (colorScheme.secondary) did not look like eBlood. The checkout now
/// gets eBlood's reds, whatever the host theme is.
void main() {
  testWidgets('checkout theme resolves to eBlood reds, not the host or SDK greens', (t) async {
    late ThemeData resolved;
    await t.pumpWidget(MaterialApp(
      // A host theme that is deliberately green: none of it may leak through.
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32))),
      home: Builder(builder: (context) {
        resolved = ebloodLokotroTheme.buildThemeData(context);
        return const SizedBox();
      }),
    ));

    final scheme = resolved.colorScheme;
    expect(scheme.primary, ColorPages.COLOR_PRINCIPAL);
    expect(scheme.secondary, Colors.red.shade700, reason: 'the loader spinner uses secondary');
    expect(scheme.tertiary, Colors.red.shade300);
    expect(scheme.surface, Colors.white);
    for (final c in [scheme.primary, scheme.secondary, scheme.tertiary]) {
      expect(c, isNot(LokotroPayColors.primary));
      expect(c, isNot(LokotroPayColors.secondary));
    }
  });
}
