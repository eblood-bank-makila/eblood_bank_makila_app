import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierCtrl.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../business/model/CurrencyExchangeModel.dart';
import '../../business/service/CurrencyExchangeService.dart';

class CurrencySelectionWidget extends ConsumerStatefulWidget {
  final int totalPrice;
  final Function(CurrencyExchangeModel?, double) onCurrencySelected;
  final CurrencyExchangeModel? selectedCurrency;

  const CurrencySelectionWidget({
    super.key,
    required this.totalPrice,
    required this.onCurrencySelected,
    this.selectedCurrency,
  });

  @override
  ConsumerState<CurrencySelectionWidget> createState() => _CurrencySelectionWidgetState();
}

class _CurrencySelectionWidgetState extends ConsumerState<CurrencySelectionWidget> {
  CurrencyExchangeModel? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.selectedCurrency;
  }



  @override
  Widget build(BuildContext context) {
    final panierState = ref.watch(panierCtrlProvider);
    final cartCurrency = panierState.paniers?.data.isNotEmpty == true
        ? panierState.paniers!.data[0].currency
        : 'USD';
    final cart = panierState.paniers?.data.isNotEmpty == true ? panierState.paniers!.data[0] : null;
    final itemCurrencyId = (cart?.cartItems.isNotEmpty == true) ? cart!.cartItems[0].currencyId : '';
    final currencyId = itemCurrencyId.isNotEmpty ? itemCurrencyId : (cart?.refCurrencyId ?? '');
    final currencyExchangeAsync = ref.watch(
      currencyExchangeProvider(
        CurrencyExchangeParams(amount: widget.totalPrice.toDouble(), refCurrencyId: currencyId),
      ),
    );

    return currencyExchangeAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Chargement des devises...',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Erreur de chargement des devises',
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
      data: (currencyResponse) {
        if (!currencyResponse.success || currencyResponse.data.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Iconsax.info_circle,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucune devise disponible',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.money_change,
                    color: ColorPages.COLOR_PRINCIPAL,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Choisir une devise',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Default cart currency option
              _buildCurrencyOption(
                null,
                cartCurrency,
                widget.totalPrice.toDouble(),
                'Devise par défaut',
              ),
              
              // Currency exchange options (use server-provided converted_amount)
              ...currencyResponse.data.map((currency) => _buildCurrencyOption(
                currency,
                currency.currencyToCode,
                currency.convertedAmount,
                'Taux: ${currency.exchangedValue.toStringAsFixed(4)}',
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOption(
    CurrencyExchangeModel? currency,
    String currencyCode,
    double amount,
    String subtitle,
  ) {
    final isSelected = (_selectedCurrency?.id == currency?.id) || 
                     (_selectedCurrency == null && currency == null);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _selectedCurrency = currency;
            });
            widget.onCurrencySelected(currency, amount);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorPages.COLOR_PRINCIPAL,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currencyCode,
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.black87,
                            ),
                          ),
                          Text(
                            '${amount.toStringAsFixed(2)} $currencyCode',
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
