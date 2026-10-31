import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../apps/config/theme/ColorPages.dart';
import '../../business/service/PaymentApi.dart';

/// Bottom sheet where the buyer picks the currency to pay in, each row
/// showing the exact amount in that currency (as the backend will charge it).
///
/// [pick] only opens the sheet when there is a real choice (two or more
/// currencies); with one it is returned as-is, with none `null`. A dismissed
/// sheet also yields `null`, so callers check [needsChoice] to tell the two apart.
class CurrencyChoiceSheet extends StatelessWidget {
  const CurrencyChoiceSheet({
    super.key,
    required this.currencies,
    required this.amountFor,
  });

  final List<PayableCurrency> currencies;
  final double Function(PayableCurrency) amountFor;

  static bool needsChoice(List<PayableCurrency> currencies) => currencies.length >= 2;

  static Future<PayableCurrency?> pick(
    BuildContext context,
    List<PayableCurrency> currencies, {
    required double Function(PayableCurrency) amountFor,
  }) {
    if (!needsChoice(currencies)) {
      return Future.value(currencies.isEmpty ? null : currencies.first);
    }
    return showModalBottomSheet<PayableCurrency>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencyChoiceSheet(currencies: currencies, amountFor: amountFor),
    );
  }

  static String formatAmount(double amount, PayableCurrency currency) {
    final n = NumberFormat('#,##0.00', Get.locale?.languageCode ?? 'fr').format(amount);
    return '$n ${currency.symbol ?? currency.code}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'choose_payment_currency'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              for (final c in currencies)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              c.code,
                              style: GoogleFonts.ubuntu(
                                fontWeight: FontWeight.bold,
                                color: ColorPages.COLOR_PRINCIPAL,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${'pay_in_currency'.tr} ${formatAmount(amountFor(c), c)}',
                              style: GoogleFonts.ubuntu(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Icon(Iconsax.arrow_right_3, color: Colors.grey.shade500, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
