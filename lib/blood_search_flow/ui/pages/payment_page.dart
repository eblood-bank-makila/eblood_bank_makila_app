/// Payment Page
/// Handles payment for address viewing or delivery

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/search_flow_provider.dart';
import '../../providers/recent_activity_provider.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../widgets/search_flow_app_bar.dart';
import '../../data/services/visitor_registration_service_impl.dart';
import '../../../payments/business/service/LokotroPayCheckoutService.dart';
import '../../../payments/business/service/PaymentApi.dart';

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
  bool _isPhoneVerified = false;
  bool _hasVisitorSession = false;
  bool _canPayOnDelivery = false;
  final _visitorService = VisitorRegistrationServiceImpl();
  final _phoneController = TextEditingController();
  String _phoneNumber = '';

  // Server-authoritative quote for the delivery option (bag + eBlood fee +
  // 10% platform fee). Fetched on load so the visitor sees the exact total
  // BEFORE checkout — the backend adds fees the client can't compute.
  VisitorPurchaseQuote? _deliveryQuote;
  bool _quoteLoading = false;

  final List<_PaymentMethod> _paymentMethods = [
    _PaymentMethod(
      id: 'mobile_money',
      name: 'Mobile Money',
      imagePath: 'assets/paymentmethods/mobile_money.png',
      description: 'M-Pesa, Airtel Money, Orange Money',
    ),
    _PaymentMethod(
      id: 'card',
      name: 'Card Payment',
      imagePath: 'assets/paymentmethods/card.png',
      description: 'Visa, Mastercard, etc.',
    ),
    _PaymentMethod(
      id: 'cash',
      name: 'cash_on_delivery',
      imagePath: 'assets/paymentmethods/pay_on_receive.png',
      description: 'pay_when_you_receive',
      isAvailableForDeliveryOnly: true,
    ),
  ];

  PaymentOption get _selectedOption {
    final state = ref.read(searchFlowProvider);
    return state.selectedPaymentOption ?? PaymentOption.viewAddress;
  }

  // Get price from backend blood bag result
  double get _bloodBagPrice {
    final state = ref.read(searchFlowProvider);
    return state.selectedResult?.price ?? 0.0;
  }

  String get _currency {
    final state = ref.read(searchFlowProvider);
    return state.selectedResult?.currency ?? 'USD';
  }

  String get _currencySymbol {
    final state = ref.read(searchFlowProvider);
    return state.selectedResult?.currencySymbol ?? r'$';
  }

  // View address price: 10% of blood bag price
  double get _viewAddressPrice => _bloodBagPrice * 0.10;
  
  // Delivery price: full blood bag price
  double get _deliveryPrice => _bloodBagPrice;

  double get _selectedPrice => _selectedOption == PaymentOption.viewAddress
      ? _viewAddressPrice
      : _deliveryPrice;

  // Amount actually charged, for DISPLAY. Delivery adds server-side fees on
  // top of the bag price, so show the quote (falls back to the bag price
  // while it loads). View-address is just the 10% fee — accurate locally.
  double get _displayPrice {
    if (_selectedOption == PaymentOption.delivery) {
      return _deliveryQuote?.total ?? _deliveryPrice;
    }
    return _viewAddressPrice;
  }

  @override
  void initState() {
    super.initState();
    _checkVisitorStatusAndPhoneVerification();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFetchDeliveryQuote());
    _phoneController.addListener(() {
      setState(() {
        _phoneNumber = _phoneController.text;
      });
    });
  }

  /// Fetch the exact delivery total (bag + fees) from the backend so the
  /// pre-checkout price matches what the SDK will charge. No-op for the
  /// view-address option (its 10% fee is computed accurately client-side).
  Future<void> _maybeFetchDeliveryQuote() async {
    if (_selectedOption != PaymentOption.delivery) return;
    final selected = ref.read(searchFlowProvider).selectedResult;
    if (selected == null || selected.id.isEmpty) return;
    setState(() => _quoteLoading = true);
    final quote =
        await PaymentApi.getVisitorDeliveryQuote(bloodBagId: selected.id);
    if (!mounted) return;
    setState(() {
      _deliveryQuote = quote;
      _quoteLoading = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkVisitorStatusAndPhoneVerification() async {
    final hasSession = await _visitorService.hasLocalVisitor();
    final isVerified = await _visitorService.hasVisitorPhoneNumber();
    
    // Check if user is authorized for cash on delivery from backend
    // This is stored in local storage when user logs in
    bool canPayOnDelivery = false;
    try {
      final storage = GetStorage();
      canPayOnDelivery = storage.read('visitor_can_pay_on_delivery') == true;
    } catch (e) {
      print('Error checking can_pay_on_delivery: $e');
    }
    
    if (mounted) {
      setState(() {
        _hasVisitorSession = hasSession;
        _isPhoneVerified = isVerified;
        _canPayOnDelivery = canPayOnDelivery;
      });
    }
  }

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
              price: _displayPrice,
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
              // Check if delivery-only (applies to all delivery options)
              final isDeliveryRequired =
                  method.isAvailableForDeliveryOnly &&
                  _selectedOption != PaymentOption.delivery;

              // Check if cash on delivery requires backend authorization
              final isCashRequiresAuth =
                  method.id == 'cash' && !_canPayOnDelivery;

              final isAvailable = !isDeliveryRequired && !isCashRequiresAuth;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PaymentMethodCard(
                  method: method,
                  isSelected: _selectedPaymentMethod == method.id,
                  isAvailable: isAvailable,
                  requiresBackofficeActivation:
                      method.id == 'cash' && !_canPayOnDelivery,
                  hasVisitorSession: _hasVisitorSession,
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
              child: Column(
                children: [
                  // Fee breakdown — only for the delivery purchase, once the
                  // server quote has loaded (bag + eBlood fee + platform fee).
                  if (_selectedOption == PaymentOption.delivery &&
                      _deliveryQuote != null) ...[
                    _QuoteLine(
                      label: 'blood_bag'.tr.isEmpty ? 'Blood bag' : 'blood_bag'.tr,
                      value: '$_currencySymbol${_deliveryQuote!.bagPrice.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 6),
                    _QuoteLine(
                      label: 'service_fees'.tr.isEmpty
                          ? 'Service fees'
                          : 'service_fees'.tr,
                      value:
                          '$_currencySymbol${(_deliveryQuote!.ebloodFee + _deliveryQuote!.platformFee).toStringAsFixed(2)}',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: Colors.grey.shade300),
                    ),
                  ],
                  Row(
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
                      _quoteLoading &&
                              _selectedOption == PaymentOption.delivery
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorPages.COLOR_PRINCIPAL,
                              ),
                            )
                          : Text(
                              '$_currencySymbol${_displayPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.ubuntu(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: ColorPages.COLOR_PRINCIPAL,
                              ),
                            ),
                    ],
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

    final method = _selectedPaymentMethod!;
    final isDelivery = _selectedOption == PaymentOption.delivery;
    final option =
        isDelivery ? PaymentOption.delivery : PaymentOption.viewAddress;

    // Mobile money: collect the phone number up-front (prefilled into the SDK).
    String? momoPhone;
    if (method == 'mobile_money') {
      final phoneNumber = await _showMobileMoneyPhoneBottomSheet();
      if (phoneNumber == null || phoneNumber.isEmpty) {
        // User cancelled or didn't enter a phone number
        return;
      }
      _phoneNumber = phoneNumber;
      momoPhone = '+243$_phoneNumber';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final selectedResult = ref.read(searchFlowProvider).selectedResult;

      // Amount + currency come from the selected blood bag (dynamic): the
      // address-view fee is 10% of the bag price, delivery is the full
      // price. The backend mints the gateway session bound to this amount.
      final paymentData = <String, dynamic>{
        'payment_method': method,
        'amount_cents': (_selectedPrice * 100).round(),
        'currency': _currency,
        if (selectedResult != null) 'blood_bank_id': selectedResult.bloodBankId,
        if (selectedResult != null) 'blood_bag_id': selectedResult.id,
        if (selectedResult != null) 'blood_bags_id': [selectedResult.id],
        if (momoPhone != null) 'phone_number': momoPhone,
      };

      // Cash on delivery: no online collection — the courier collects on
      // receipt. Skip the SDK entirely.
      if (method == 'cash') {
        ref.read(searchFlowProvider.notifier).markPaymentCollected(
              option,
              'COD-${DateTime.now().millisecondsSinceEpoch}',
            );
        _afterCollected(isDelivery);
        return;
      }

      // PHASE 1 — create the payment intent + gateway session.
      final initiate = await ref
          .read(searchFlowProvider.notifier)
          .beginPayment(option, paymentData);
      if (initiate == null) {
        // beginPayment already set errorMessage / paymentResult.
        final st = ref.read(searchFlowProvider);
        setState(() {
          _errorMessage = st.paymentResult?.message ??
              st.errorMessage ??
              'Payment could not be started. Please try again.';
        });
        return;
      }

      if (!mounted) return;

      // PHASE 2 — launch the lokotro_pay SDK checkout to actually collect
      // the money. onResponse/onError resolve the returned result.
      final sdkMethod = method == 'mobile_money' ? 'mobile_money' : 'card';
      final result = await LokotroPayCheckoutService.launchFromInitiate(
        context,
        initiate: initiate,
        paymentMethod: sdkMethod,
        phoneNumberOverride: momoPhone,
        mobileMoneyPhoneNumber: momoPhone,
        title: isDelivery
            ? 'Paiement de la livraison'
            : 'Paiement (accès adresse)',
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        // Cancelled or errored — do NOT navigate. Surface real errors only
        // (a user-cancelled checkout is silent).
        if (result.outcome == LokotroPayCheckoutOutcome.error) {
          setState(() {
            _errorMessage =
                result.message ?? 'Payment failed. Please try again.';
          });
        }
        return;
      }

      // Collected — record success and proceed.
      ref.read(searchFlowProvider.notifier).markPaymentCollected(
            option,
            result.customerReference,
            transactionId: result.transactionId,
          );
      _afterCollected(isDelivery);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Post-collection: refresh recent activity (auto-open the right tab) and
  /// return to the blood-search welcome page. Address reveal / delivery
  /// tracking then proceeds from the updated flow state.
  void _afterCollected(bool isDelivery) {
    if (!mounted) return;
    // Tab 0 = pending deliveries, Tab 1 = address requests
    ref.read(recentActivityProvider.notifier).fetchRecentActivity(
          autoOpenTab: isDelivery ? 0 : 1,
        );
    context.go('/blood-search');
  }

  Future<String?> _showMobileMoneyPhoneBottomSheet() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MobileMoneyPhoneBottomSheet(),
    );
  }
}

/// A label/value row used in the delivery fee breakdown.
class _QuoteLine extends StatelessWidget {
  final String label;
  final String value;

  const _QuoteLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
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
  final String imagePath;
  final String description;
  final bool isAvailableForDeliveryOnly;

  const _PaymentMethod({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
    this.isAvailableForDeliveryOnly = false,
  });
}

class _PaymentMethodCard extends StatelessWidget {
  final _PaymentMethod method;
  final bool isSelected;
  final bool isAvailable;
  final bool requiresBackofficeActivation;
  final bool hasVisitorSession;
  final VoidCallback? onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.isAvailable,
    this.requiresBackofficeActivation = false,
    this.hasVisitorSession = false,
    this.onTap,
  });

  void _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@eblood.com',
      query:
          'subject=${Uri.encodeComponent('Enable Pay on Delivery')}&body=${Uri.encodeComponent('Hello,\n\nI would like to enable pay on delivery for my account.\n\nThank you.')}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

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
                width: 66,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorPages.COLOR_PRINCIPAL.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    method.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Iconsax.card,
                        color: isSelected
                            ? ColorPages.COLOR_PRINCIPAL
                            : Colors.grey.shade600,
                        size: 20,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name.tr.isEmpty ? method.name : method.name.tr,
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
                      method.description.tr.isEmpty ? method.description : method.description.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (requiresBackofficeActivation) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            size: 12,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'backoffice_activation_required'.tr.isEmpty
                                  ? 'Requires activation from backoffice'
                                  : 'backoffice_activation_required'.tr,
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Support contact message
                      Text(
                        'contact_support_to_enable_cod'.tr.isEmpty
                            ? 'Contact eBlood support team to enable pay on delivery'
                            : 'contact_support_to_enable_cod'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Contact support button
                      TextButton.icon(
                        onPressed: () => _contactSupport(),
                        icon: Icon(
                          Iconsax.message,
                          size: 14,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                        label: Text(
                          'contact_support'.tr.isEmpty
                              ? 'Contact Support'
                              : 'contact_support'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ColorPages.COLOR_PRINCIPAL,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
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

/// Bottom sheet for entering mobile money phone number
class _MobileMoneyPhoneBottomSheet extends StatefulWidget {
  @override
  State<_MobileMoneyPhoneBottomSheet> createState() =>
      _MobileMoneyPhoneBottomSheetState();
}

class _MobileMoneyPhoneBottomSheetState
    extends State<_MobileMoneyPhoneBottomSheet> {
  final _phoneController = TextEditingController();
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _phoneNumber = _phoneController.text;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and title
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/paymentmethods/mobile_money.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Iconsax.mobile,
                                color: ColorPages.COLOR_PRINCIPAL,
                                size: 24,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'mobile_money_number'.tr.isEmpty
                                  ? 'Mobile Money Number'
                                  : 'mobile_money_number'.tr,
                              style: GoogleFonts.ubuntu(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'enter_number_for_payment'.tr.isEmpty
                                  ? 'Enter your number for payment'
                                  : 'enter_number_for_payment'.tr,
                              style: GoogleFonts.ubuntu(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Phone number input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _phoneNumber.length >= 10
                            ? ColorPages.COLOR_PRINCIPAL
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      style: GoogleFonts.ubuntu(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        letterSpacing: 1,
                      ),
                      decoration: InputDecoration(
                        hintText: '812345678',
                        hintStyle: GoogleFonts.ubuntu(
                          fontSize: 20,
                          color: Colors.grey.shade400,
                          letterSpacing: 1,
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  '+243',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                        suffixIcon: _phoneNumber.length >= 10
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Iconsax.tick_circle5,
                                  color: ColorPages.COLOR_PRINCIPAL,
                                  size: 28,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info message
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'mobile_money_info'.tr.isEmpty
                              ? 'You will receive a payment request on this number. Make sure it\'s active and has sufficient balance.'
                              : 'mobile_money_info'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _phoneNumber.length == 9
                          ? () => Navigator.pop(context, _phoneNumber)
                          : null,
                      icon: Icon(
                        Iconsax.tick_circle,
                        size: 22,
                      ),
                      label: Text(
                        'continue'.tr.isEmpty ? 'Continue' : 'continue'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 17,
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
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'cancel'.tr.isEmpty ? 'Cancel' : 'cancel'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
