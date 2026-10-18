import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:lokotro_pay/enums/lokotro_pay_theme.dart';

/// eBlood branding for the lokotro_pay checkout. Without it the SDK takes the
/// host's Material defaults / its own greens. Since lokotro_pay 3.4.0 every
/// SDK screen reads these, status colours included (Lokotro's default
/// success is turquoise).
final LokotroPayThemeConfig ebloodLokotroTheme = LokotroPayThemeConfig.light(
  primaryColor: ColorPages.COLOR_PRINCIPAL,
  secondaryColor: Colors.red.shade700,
  tertiaryColor: Colors.red.shade300,
  backgroundColor: Colors.white,
  successColor: Colors.green.shade600,
  warningColor: Colors.orange.shade700,
  infoColor: Colors.blue.shade600,
  errorColor: Colors.red.shade900,
);
