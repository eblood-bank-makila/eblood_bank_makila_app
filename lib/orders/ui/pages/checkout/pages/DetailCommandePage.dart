import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/core/config/app_config.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import 'package:eblood_bank_mak_app/orders/business/model/DatumPanierModel.dart';
import 'package:eblood_bank_mak_app/orders/ui/pages/panier/PanierPageState.dart';
import 'package:eblood_bank_mak_app/payments/business/service/LokotroPayCheckoutService.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaymentApi.dart';
import 'package:eblood_bank_mak_app/payments/ui/pages/PaiementCtrl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../apps/config/utils/DottedDivider.dart';
import '../../../../../apps/widgets/DetailCommandeWidget.dart';
import '../../../../../payments/ui/pages/message/MessagePaiementEchouer.dart';
import '../../../../../payments/ui/pages/message/MessagePaiementReussiPage.dart';
import '../../panier/PanierCtrl.dart';
import '../widgets/PhoneNumberBottomSheet.dart';
import 'PaymentStatusPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'BloodRequestConfigDialog.dart';

import 'package:eblood_bank_mak_app/payments/ui/widgets/currency_choice_sheet.dart';

class DetailCommandePage extends ConsumerStatefulWidget {
  final DatumModel paiement;

  const DetailCommandePage({super.key, required this.paiement});

  @override
  ConsumerState createState() => _DetailCommandePageState();
}

class _DetailCommandePageState extends ConsumerState<DetailCommandePage> {
  bool _isAnimating = false;
  List<Widget> _listOfPages = [];
  bool _isLoading = false;

  // Blood request config captured before payment
  String? _requestFor;
  String? _requestReason;
  String? _patientId;
  String? _requestType;
  String? _urgencyLevel;

  // Server-authoritative quote for the cart (bags + eBlood fee + platform
  // fee + km delivery fee) — what /cart/initiate-lokotro-payment will
  // actually charge. Null (quote failed) falls back to the client total.
  VisitorPurchaseQuote? _cartQuote;
  bool _isQuoteLoading = false;

  String apiResponseMessage = "";
  String apiResponseMessageTitle = "";

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  final _pageController = PageController();

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));

    // Initialize currency exchange data

    // Fetch the server-side price breakdown (includes the km delivery fee
    // the client cannot compute) for the cart being checked out.
    _fetchCartQuote();
  }

  /// widget.paiement IS the cart document (DatumModel.id == cart `_id`), so
  /// the quote endpoint can price it directly. Must run before payment —
  /// initiate-lokotro-payment flips the cart out of ACTIVE.
  Future<void> _fetchCartQuote() async {
    final cartId = widget.paiement.id;
    if (cartId.isEmpty) return;
    setState(() => _isQuoteLoading = true);
    final quote = await PaymentApi.getCartPurchaseQuote(cartId: cartId);
    debugPrint(quote != null
        ? '💰 Cart quote: total=${quote.total} km_fee=${quote.kmFee} distance=${quote.distanceKm}'
        : '⚠️ Cart quote unavailable — falling back to client total');
    if (!mounted) return;
    setState(() {
      _cartQuote = quote;
      _isQuoteLoading = false;
    });
  }

  onPaymentResult(
      {required int page,
      required String title,
      required String message,
      required bool paymentSucceed}) {
    if (context.canPop()) {
      context.pop();
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      apiResponseMessageTitle = title;
      apiResponseMessage = message;
      setState(() {});
      _pageController.jumpToPage(page);
      if (paymentSucceed) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Widget _buildCurrencyPaymentButtons(int totalPrice) {
    // Exact totals per payable currency come from /cart/purchase-quote; the
    // backend converts and mints the gateway session in the chosen currency.
    final currencies = _cartQuote?.payableCurrencies ?? const <PayableCurrency>[];
    if (currencies.length < 2) return _buildDefaultPaymentButton(totalPrice);
    return Column(
      children: [
        for (final c in currencies)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: _buildPaymentButton(
                label: 'Payer ${CurrencyChoiceSheet.formatAmount(c.total, c)}',
                subtitle: c == currencies.first ? '${c.code} (Original)' : '${c.code} (Converti)',
                onPressed: () => _processPaymentWithCurrency(c.id),
                isPrimary: c == currencies.first,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(panierCtrlProvider);

    _listOfPages = [
      _verification(state),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 10.0,
              bottom: 10.0,
            ),
            margin:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              color: CupertinoColors.extraLightBackgroundGray,
            ),
            child: OpsErrorScreen(
              can_show_go_back_btn: true,
              hidde_all_btn: false,
              goBack: () {
                _pageController.jumpToPage(
                  0,
                );
              },
              message: apiResponseMessage,
              title: apiResponseMessageTitle,
              onClosing: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            ),
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            // don't specify a direction, blast randomly
            shouldLoop: false,
            // start again as soon as the animation is finished
            // manually specify the colors to be used
            createParticlePath: drawStar, // define a custom shape/path.
          ),
          Container(
            padding: const EdgeInsets.only(
              top: 10.0,
              bottom: 10.0,
            ),
            margin:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              color: CupertinoColors.extraLightBackgroundGray,
            ),
            child: OpsSuccessScreen(
              message: apiResponseMessage,
              hidde_all_btn: false,
              title: apiResponseMessageTitle,
              onClosing: () {
                debugPrint('🔘 DetailCommandePage: onClosing callback triggered');
                // Use a post-frame callback to ensure navigation happens after current frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    if (mounted) {
                      debugPrint('🔘 DetailCommandePage: Widget is mounted, attempting navigation');
                      // Navigate back to main app using GoRouter
                      context.go('/app/MainApp');
                      debugPrint('✅ DetailCommandePage: Navigation to main app completed successfully');
                    } else {
                      debugPrint('❌ DetailCommandePage: Widget not mounted, cannot navigate');
                    }
                  } catch (e) {
                    debugPrint('❌ DetailCommandePage: Navigation error: $e');
                    // Fallback: try simple pop
                    try {
                      if (mounted && context.canPop()) {
                        context.pop();
                      }
                    } catch (fallbackError) {
                      debugPrint('❌ DetailCommandePage: Fallback navigation also failed: $fallbackError');
                    }
                  }
                });
              },
            ),
          ),
        ],
      ),
    ];
    return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade100,
                Colors.red.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced Header
                _buildModernHeader(context),

                // Content
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        _body(context),
                        if (_isLoading) _buildModernLoading(), // Enhanced loading
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _body(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _listOfPages.length,
      itemBuilder: (context, index) {
        return _listOfPages[index];
      },
    );
  }

  Widget _verification(PanierPageState state) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Header
            _buildOrderSummaryHeader(),

            const SizedBox(height: 20),

            // Cart Items List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: state.paniers?.data.isNotEmpty == true
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.paniers!.data[0].cartItems.length,
                        itemBuilder: (context, index) {
                          final paniers = state.paniers!.data[0];
                          return FadeInUp(
                            delay: Duration(milliseconds: 400 + (index * 100)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DetailCommandeWidget(
                                paniers: paniers,
                                index: index,
                              ),
                            ),
                          );
                        },
                      )
                    : _buildEmptyCartState(),
              ),
            ),

            const SizedBox(height: 20),

            // Enhanced Price Summary Card
            _buildPriceSummaryCard(state),

            const SizedBox(height: 20),

            // Enhanced Payment Button
            _buildPaymentSection(state),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Iconsax.shopping_cart,
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
                'Résumé de la commande',
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vérifiez vos articles avant le paiement',
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.verify,
                size: 14,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'À vérifier',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Iconsax.shopping_cart,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Panier vide',
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun article dans le panier',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard(PanierPageState state) {
    final totalPrice = state.paniers?.data.isNotEmpty == true
        ? state.paniers!.data[0].totalPrice
        : 0;

    // Get currency from cart data
    final currency = state.paniers?.data.isNotEmpty == true
        ? state.paniers!.data[0].currency
        : 'CDF';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Price breakdown — server quote when available (it alone knows
          // the km delivery fee), client cart total otherwise.
          _buildPriceRow(
            'Prix des poches',
            '$currency ${(_cartQuote?.bagPrice ?? totalPrice).toStringAsFixed(2)}',
          ),

          if (_cartQuote != null) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              'Frais eBlood',
              '$currency ${_cartQuote!.ebloodFee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildPriceRow(
              'Frais de service',
              '$currency ${_cartQuote!.platformFee.toStringAsFixed(2)}',
            ),
            if (_cartQuote!.kmFee > 0) ...[
              const SizedBox(height: 12),
              _buildPriceRow(
                _cartQuote!.distanceKm != null
                    ? 'Frais de distance (${_cartQuote!.distanceKm!.toStringAsFixed(1)} km)'
                    : 'Frais de distance',
                '$currency ${_cartQuote!.kmFee.toStringAsFixed(2)}',
              ),
            ],
          ],

          const SizedBox(height: 12),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                  Colors.grey.shade300,
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à payer',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isQuoteLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '$currency ${(_cartQuote?.total ?? totalPrice).toStringAsFixed(2)}',
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// One label/value line of the price summary card.
  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(PanierPageState state) {
    final totalPrice = state.paniers?.data.isNotEmpty == true
        ? state.paniers!.data[0].totalPrice
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Payment info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.card,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paiement sécurisé',
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vos données sont protégées',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.shield_tick,
                      size: 12,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SSL',
                      style: GoogleFonts.ubuntu(
                        fontSize: 10,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Currency payment buttons
          _buildCurrencyPaymentButtons(totalPrice),
        ],
      ),
    );
  }

  void _showDebugOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Debug Options',
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultPaymentButton(int totalPrice) {
    // Get currency from cart data
    var state = ref.watch(panierCtrlProvider);
    final currency = state.paniers?.data.isNotEmpty == true
        ? state.paniers!.data[0].currency
        : 'CDF';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _processPaymentWithCurrency(null),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Traitement...',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.card, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Payer $currency ${(_cartQuote?.total ?? totalPrice).toStringAsFixed(2)}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPaymentButton({
    required String label,
    required String subtitle,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      height: 70,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? ColorPages.COLOR_PRINCIPAL : Colors.white,
          foregroundColor: isPrimary ? Colors.white : ColorPages.COLOR_PRINCIPAL,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          side: isPrimary ? null : BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.ubuntu(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isPrimary ? Colors.white70 : ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _processPaymentWithCurrency(String? currencyId) async {
    debugPrint('💳 Processing payment with currency ID: $currencyId');

    // 1) Ask for blood request configuration (patient/storage, reason, etc.)
    final config = await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BloodRequestConfigDialog(
        patientCrudInfo: ref.read(rbacProvider.notifier).getCrudInfoByPath(
          'flutter_apps_eblood_bank_hosp_home_patients',
        ),
      ),
    );

    if (config == null) {
      debugPrint('❌ Payment cancelled: no configuration provided');
      return;
    }

    setState(() {
      _requestFor = config['request_for'];
      _patientId = config['patient_id'];
      _requestType = config['request_type'];
      _urgencyLevel = config['urgency_level'];
      _requestReason = config['request_reason'];
    });

    // 2) Ask for phone number and proceed
    _showPhoneNumberBottomSheet(currencyId);
  }

  Widget _buildModernHeader(BuildContext context) {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Back Button
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Iconsax.arrow_left_2,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Title Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Iconsax.verify,
                          color: ColorPages.COLOR_PRINCIPAL,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Vérification',
                        style: GoogleFonts.ubuntu(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Vérifiez votre commande avant paiement',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: ColorPages.COLOR_PRINCIPAL,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Debug Button (in development) or Security Badge
            GestureDetector(
              onTap: () {
                _showDebugOptions();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.code,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Debug',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLoading() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpinner.ring(
                size: 60,
                showMessage: false,
              ),
              const SizedBox(height: 20),
              Text(
                'Traitement en cours...',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez patienter',
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhoneNumberBottomSheet(String? currencyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhoneNumberBottomSheet(
        onPhoneNumberSubmitted: (phoneNumber) {
          _processPaymentWithPhoneAndCurrency(phoneNumber, currencyId);
        },
      ),
    );
  }

  Future<void> _processPaymentWithPhoneAndCurrency(String phoneNumber, String? currencyId) async {
    debugPrint("🚀 Starting payment process with phone: $phoneNumber");
    debugPrint("💰 Currency ID to send: $currencyId");
    debugPrint("💰 Currency explanation: ${currencyId == null ? 'null = USD (default)' : 'Target currency ID'}");
    debugPrint("📦 Cart data: ${widget.paiement.toJson()}");

    setState(() {
      _isLoading = true;
    });

    try {
      // Km-pricing — go through /eblood-connect/cart/initiate-lokotro-payment
      // (same call as BloodBagOrderStepperPage._submitPayment). The old
      // /payments/initiate/payment path CLIENT-declared
      // `totalPrice * 100` cents, which underpays now that the backend
      // adds a km delivery fee: here the backend materializes the cart
      // into a blood request and computes bags + eblood_fee + platform
      // fee + km fee server-side — the app never declares what a cart
      // costs. Response shape is identical (full lokotro widget config).
      debugPrint("💳 POST /eblood-connect/cart/initiate-lokotro-payment — cart ${widget.paiement.id}");
      final initiate = await PaymentApi.initiateCartPurchase(
        cartId: widget.paiement.id,
        phoneNumber: phoneNumber,
        transactionalCurrencyId: currencyId,
        requestFor: _requestFor,
        patientId: _patientId,
        requestType: _requestType,
        urgencyLevel: _urgencyLevel,
        requestReason: _requestReason,
      );

      if (!initiate.isSuccess || initiate.customerReference == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(initiate.errorMessage
                  ?? 'Erreur lors de l\'initiation du paiement'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final customerRef = initiate.customerReference!;
      debugPrint("🎉 Intent created. Launching lokotro_pay with ref=$customerRef");

      // Sprint 15 — hand off to lokotro_pay's checkout widget with the
      // full config from the backend. The webhook reconciles the final
      // state regardless of the SDK callback, so we always navigate to
      // PaymentStatusPage afterwards.
      if (mounted) {
        final outcome = await LokotroPayCheckoutService.launchFromInitiate(
          context,
          initiate: initiate,
          paymentMethod: 'wallet',
          phoneNumberOverride: phoneNumber,
          mobileMoneyPhoneNumber: phoneNumber,
          title: 'Paiement eblood',
        );
        debugPrint('🪙 lokotro_pay checkout outcome: ${outcome.outcome}');
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final baseUrl = AppConfig.apiBaseUrl;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentStatusPage(
              systemRef: customerRef,
              baseUrl: baseUrl,
              onPaymentResult: onPaymentResult,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      debugPrint("💥 Payment error: $e");
      debugPrint("📍 Stack trace: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
