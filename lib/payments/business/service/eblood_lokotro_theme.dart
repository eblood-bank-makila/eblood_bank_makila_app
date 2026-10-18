import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:lokotro_pay/enums/lokotro_pay_theme.dart';

/// eBlood branding for the lokotro_pay checkout. Without it the SDK takes the
/// host's Material defaults / its own greens (the loader spinner reads
/// `colorScheme.secondary`). Some SDK widgets still hard-code
/// `LokotroPayColors` (hosted-checkout progress bar, step indicator default,
/// payment-form gradient) — those need a change in the SDK itself.
final LokotroPayThemeConfig ebloodLokotroTheme = LokotroPayThemeConfig.light(
  primaryColor: ColorPages.COLOR_PRINCIPAL,
  secondaryColor: Colors.red.shade700,
  tertiaryColor: Colors.red.shade300,
  backgroundColor: Colors.white,
);
