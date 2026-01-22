/// Payment Page
/// Handles payment for address viewing or delivery

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/search_flow_provider.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../widgets/search_flow_app_bar.dart';

// Use PaymentOption from domain entities instead of defining a local one

class PaymentPage extends ConsumerStatefulWidget {
  final String? option;

  const PaymentPage({super.key, this.option});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  String? _selectedPaymentMethod;
  bool _isLoading = false;
  String? _errorMessage;

  final List<_PaymentMethod> _paymentMethods = [
    _PaymentMethod(
      id: 'mobile_money',
      name: 'Mobile Money',
      icon: Iconsax.mobile,
      description: 'M-Pesa, Airtel Money, Orange Money',
    ),
    _PaymentMethod(
      id: 'card',
      name: 'Card Payment',
      icon: Iconsax.card,
      description: 'Visa, Mastercard, etc.',
    ),
    _PaymentMethod(
      id: 'cash',
      name: 'Cash on Delivery',
      icon: Iconsax.money,
      description: 'Pay when you receive',
      isAvailableForDeliveryOnly: true,
    ),
  ];

  double get _viewAddressPrice => 500.0; // CDF
  double get _deliveryPrice => 5000.0; // CDF

  PaymentOption get _selectedOption {
    final state = ref.read(searchFlowProvider);
    return state.selectedPaymentOption ?? PaymentOption.viewAddress;
  }

  double get _selectedPrice => _selectedOption == PaymentOption.viewAddress
      ? _viewAddressPrice
      : _deliveryPrice;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchFlowProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: 'payment'.tr.isEmpty ? 'Payment' : 'payment'.tr,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected hospital/blood bank summary - only distance shown
            if (state.selectedResult != null) ...[
              _BloodBankDistanceCard(result: state.selectedResult!),
              const SizedBox(height: 24),
            ],

            // Selected option summary (read-only)
            _SelectedOptionSummary(
              option: _selectedOption,
              price: _selectedPrice,
            ),

            const SizedBox(height: 24),

            // Payment method selection
            Text(
              'payment_method'.tr.isEmpty
                  ? 'Payment Method'
                  : 'payment_method'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 16),

            ..._paymentMethods.map((method) {
              final isAvailable =
                  !method.isAvailableForDeliveryOnly ||
                  _selectedOption == PaymentOption.delivery;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PaymentMethodCard(
                  method: method,
                  isSelected: _selectedPaymentMethod == method.id,
                  isAvailable: isAvailable,
                  onTap: isAvailable
                      ? () => setState(() => _selectedPaymentMethod = method.id)
                      : null,
                ),
              );
            }),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      size: 20,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total'.tr.isEmpty ? 'Total' : 'total'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${_selectedPrice.toStringAsFixed(0)} CDF',
                    style: GoogleFonts.ubuntu(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _canPay
                    ? (_isLoading ? null : _processPayment)
                    : null,
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Iconsax.lock, size: 20),
                label: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'pay_now'.tr.isEmpty ? 'Pay Now' : 'pay_now'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Security note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.shield_tick,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  'secure_payment'.tr.isEmpty
                      ? 'Secure payment powered by E-Blood'
                      : 'secure_payment'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _canPay => _selectedPaymentMethod != null;

  Future<void> _processPayment() async {
    if (!_canPay) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isDelivery = _selectedOption == PaymentOption.delivery;

      if (isDelivery) {
        await ref.read(searchFlowProvider.notifier).processDeliveryPayment({
          'amount': _selectedPrice,
          'method': _selectedPaymentMethod!,
          'option': 'delivery',
        });

        if (mounted) {
          context.push('/blood-search/live-tracking');
        }
      } else {
        await ref.read(searchFlowProvider.notifier).unlockAddress({
          'amount': _selectedPrice,
          'method': _selectedPaymentMethod!,
          'option': 'view_address',
        });

        if (mounted) {
          context.push('/blood-search/address-view');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

/// Shows only the distance to the blood bank (no name or address for privacy)
class _BloodBankDistanceCard extends StatelessWidget {
  final BloodSearchResult result;

  const _BloodBankDistanceCard({required this.result});

  @override
  Widget build(BuildContext context) {
    // Format distance
    String distanceText = 'nearby'.tr.isEmpty ? 'Nearby' : 'nearby'.tr;
    if (result.distanceKm != null) {
      distanceText = '${result.distanceKm!.toStringAsFixed(1)} km';
    } else if (result.distance != null && result.distance!.isNotEmpty) {
      distanceText = result.distance!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.routing,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'distance_from_you'.tr.isEmpty
                      ? 'Distance from you'
                      : 'distance_from_you'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distanceText,
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
              ],
            ),
          ),
          // Blood type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.fullBloodType.isNotEmpty
                  ? result.fullBloodType
                  : result.bloodType,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the selected option (read-only summary)
class _SelectedOptionSummary extends StatelessWidget {
  final PaymentOption option;
  final double price;

  const _SelectedOptionSummary({required this.option, required this.price});

  @override
  Widget build(BuildContext context) {
    final isDelivery = option == PaymentOption.delivery;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDelivery
            ? Colors.purple.shade50
            : ColorPages.COLOR_PRINCIPAL.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDelivery ? Colors.purple : ColorPages.COLOR_PRINCIPAL,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDelivery
                  ? Colors.purple.shade100
                  : ColorPages.COLOR_PRINCIPAL.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDelivery ? Iconsax.truck_fast : Iconsax.location,
              color: isDelivery ? Colors.purple : ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isDelivery
                          ? ('order_delivery'.tr.isEmpty
                                ? 'Order Delivery'
                                : 'order_delivery'.tr)
                          : ('view_address'.tr.isEmpty
                                ? 'View Address Only'
                                : 'view_address'.tr),
                      style: GoogleFonts.ubuntu(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDelivery
                            ? Colors.purple
                            : ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                    if (isDelivery) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BEST',
                          style: GoogleFonts.ubuntu(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isDelivery
                      ? ('have_blood_delivered'.tr.isEmpty
                            ? 'Have the blood product delivered to you'
                            : 'have_blood_delivered'.tr)
                      : ('get_hospital_location'.tr.isEmpty
                            ? 'Get the hospital location to visit yourself'
                            : 'get_hospital_location'.tr),
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${price.toStringAsFixed(0)}',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDelivery
                      ? Colors.purple
                      : ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              Text(
                'CDF',
                style: GoogleFonts.ubuntu(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final bool isAvailableForDeliveryOnly;

  const _PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.isAvailableForDeliveryOnly = false,
  });
}

class _PaymentMethodCard extends StatelessWidget {
  final _PaymentMethod method;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorPages.COLOR_PRINCIPAL.withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ColorPages.COLOR_PRINCIPAL
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorPages.COLOR_PRINCIPAL.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  method.icon,
                  color: isSelected
                      ? ColorPages.COLOR_PRINCIPAL
                      : Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? ColorPages.COLOR_PRINCIPAL
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.description,
                      style: GoogleFonts.ubuntu(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Iconsax.tick_circle5,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
