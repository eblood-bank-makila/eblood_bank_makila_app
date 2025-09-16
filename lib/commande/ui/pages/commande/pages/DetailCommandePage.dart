import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:binoxuspay/model/binoxuspay_response.dart';
import 'package:confetti/confetti.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierPageState.dart';
import 'package:eblood_bank_mak_app/paiement/ui/pages/PaiementCtrl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../apps/config/utils/DottedDivider.dart';
import '../../../../../apps/widgets/DetailCommandeWidget.dart';
import '../../../../../paiement/ui/pages/message/MessagePaiementEchouer.dart';
import '../../../../../paiement/ui/pages/message/MessagePaiementReussiPage.dart';
import '../../panier/PanierCtrl.dart';
import 'package:binoxuspay/binoxuspay.dart';
import '../widgets/PhoneNumberBottomSheet.dart';
import 'PaymentStatusPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import '../../../../business/service/CurrencyExchangeService.dart';
import '../../../debug/CurrencyExchangeDebugPage.dart';

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
    _initializeCurrencyExchange();
  }

  void _initializeCurrencyExchange() {
    debugPrint('🚀 Initializing currency exchange in initState');

    // This will trigger the currencyExchangeProvider to fetch data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          // Force the provider to fetch data immediately by reading it
          final asyncValue = ref.read(currencyExchangeProvider);
          debugPrint('🔄 Currency exchange provider triggered');
          debugPrint('📊 Initial state: ${asyncValue.runtimeType}');

          // Check the current state
          asyncValue.when(
            loading: () => debugPrint('🔄 Provider is loading...'),
            error: (error, stack) => debugPrint('❌ Provider error: $error'),
            data: (response) {
              debugPrint('✅ Provider has data: ${response.success}');
              debugPrint('📊 Currencies loaded: ${response.data.length}');
            },
          );
        } catch (e) {
          debugPrint('❌ Error triggering currency exchange provider: $e');
        }
      }
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
    final currencyExchangeAsync = ref.watch(currencyExchangeProvider);

    return currencyExchangeAsync.when(
      loading: () {
        debugPrint('🔄 Currency Exchange: Loading state');
        return _buildLoadingPaymentButton(totalPrice);
      },
      error: (error, stack) {
        debugPrint('❌ Currency Exchange Error: $error');
        debugPrint('❌ Stack trace: $stack');
        return _buildDefaultPaymentButton(totalPrice);
      },
      data: (currencyResponse) {
        debugPrint('📊 Currency Exchange Response received');
        debugPrint('📊 Success: ${currencyResponse.success}');
        debugPrint('📊 Data length: ${currencyResponse.data.length}');
        debugPrint('📊 Message: ${currencyResponse.message}');

        if (currencyResponse.data.isNotEmpty) {
          debugPrint('📊 First currency data: ${currencyResponse.data.first.toString()}');
        }

        if (!currencyResponse.success || currencyResponse.data.isEmpty) {
          debugPrint('⚠️ No currency data available, showing default button');
          return _buildDefaultPaymentButton(totalPrice);
        }

        // Find the USD to other currency conversion (not the reverse)
        // We want to convert FROM USD TO another currency
        final usdConversion = currencyResponse.data.firstWhere(
          (currency) => currency.currencyFromCode.toLowerCase() == 'usd',
          orElse: () => currencyResponse.data.first,
        );

        final convertedAmount = totalPrice.toDouble() * usdConversion.exchangedValue;

        debugPrint('💱 Currency conversion:');
        debugPrint('💱 Available currencies: ${currencyResponse.data.length}');
        for (var currency in currencyResponse.data) {
          debugPrint('💱   ${currency.currencyFromCode} → ${currency.currencyToCode}: ${currency.exchangedValue}');
          debugPrint('💱     From ID: ${currency.currencyFrom}, To ID: ${currency.currencyTo}');
        }
        debugPrint('💱 Selected conversion: ${usdConversion.currencyFromCode} → ${usdConversion.currencyToCode}');
        debugPrint('💱 Rate: ${usdConversion.exchangedValue}');
        debugPrint('💱 Original amount: \$${totalPrice.toStringAsFixed(2)} USD');
        debugPrint('💱 Converted amount: ${convertedAmount.toStringAsFixed(2)} ${usdConversion.currencyToCode.toUpperCase()}');
        debugPrint('💱 Currency IDs: From=${usdConversion.currencyFrom}, To=${usdConversion.currencyTo}');
        debugPrint('💱 Will send transactional_currency_id: ${usdConversion.currencyTo}');

        return Column(
          children: [
            // Currency exchange info
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.money_change,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Taux de change: 1 USD = ${usdConversion.exchangedValue.toStringAsFixed(4)} ${usdConversion.currencyToCode.toUpperCase()}',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Two payment buttons
            Row(
              children: [
                // Blood request currency button (USD)
                Expanded(
                  child: _buildPaymentButton(
                    label: 'Payer \$${totalPrice.toStringAsFixed(2)}',
                    subtitle: 'USD (Original)',
                    onPressed: () => _processPaymentWithCurrency(null), // null = USD default
                    isPrimary: true,
                  ),
                ),

                const SizedBox(width: 12),

                // Converted currency button
                Expanded(
                  child: _buildPaymentButton(
                    label: 'Payer ${_formatCurrency(convertedAmount, usdConversion.currencyToCode)}',
                    subtitle: '${usdConversion.currencyToCode.toUpperCase()} (Converti)',
                    onPressed: () => _processPaymentWithCurrency(usdConversion.currencyTo),
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
                ColorPages.COLOR_PRINCIPAL,
                ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
                Colors.grey.shade50,
              ],
              stops: const [0.0, 0.15, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
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
          // Price breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prix des poches',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '\$ ${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),

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
                child: Text(
                  '\$ ${totalPrice.toStringAsFixed(2)}',
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

  String _formatCurrency(double amount, String currencyCode) {
    final currency = currencyCode.toLowerCase();

    // For currencies that typically have large amounts (like CDF), show without decimals
    if (currency == 'cdf' || currency == 'ugx' || currency == 'rwf') {
      // Format with thousand separators
      final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String result = amount.toStringAsFixed(0).replaceAllMapped(formatter, (Match m) => '${m[1]},');
      return result;
    }

    // For other currencies (USD, EUR, etc.), show with 2 decimal places
    return amount.toStringAsFixed(2);
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

            // Refresh Currency Data
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: Text(
                'Refresh Currency Data',
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Reload currency exchange rates',
                style: GoogleFonts.ubuntu(fontSize: 12),
              ),
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                }
                ref.invalidate(currencyExchangeProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Currency data refreshed',
                      style: GoogleFonts.ubuntu(),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),

            // Open Debug Page
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: Text(
                'Open Debug Page',
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'View detailed currency exchange info',
                style: GoogleFonts.ubuntu(fontSize: 12),
              ),
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurrencyExchangeDebugPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPaymentButton(int totalPrice) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.grey.shade600,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultPaymentButton(int totalPrice) {
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
                    'Payer \$${totalPrice.toStringAsFixed(2)}',
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
                      color: isPrimary ? Colors.white70 : ColorPages.COLOR_PRINCIPAL.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  void _processPaymentWithCurrency(String? currencyId) {
    debugPrint('💳 Processing payment with currency ID: $currencyId');
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Iconsax.arrow_left_2,
                  color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Iconsax.verify,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Vérification',
                        style: GoogleFonts.ubuntu(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Vérifiez votre commande avant paiement',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
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
      debugPrint("🔧 Getting payment controller...");
      var ctrl = ref.read(paiementCtrlProvider.notifier);

      debugPrint("💳 Calling payment API with transactional_currency_id: $currencyId");
      var resultat = await ctrl.ajouterPaiment(
        widget.paiement,
        phoneNumber: phoneNumber,
        transactionalCurrencyId: currencyId,
      );

      print("🎯 Payment result: $resultat");
      print("✅ Success: ${resultat?.success}");
      print("📄 Message: ${resultat?.sms}");
      print("🔗 SystemRef: ${resultat?.data?.systemRef}");

      setState(() {
        _isLoading = false;
      });

      if (resultat?.success == true && resultat?.data?.systemRef != null) {
        print("🎉 Payment initiated successfully, navigating to status page...");

        // Navigate to payment status page
        String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.30.132:3101/eblood-hstdapi/v1';

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentStatusPage(
                systemRef: resultat!.data!.systemRef,
                baseUrl: baseUrl,
                onPaymentResult: onPaymentResult,
              ),
            ),
          );
        }
      } else {
        print("❌ Payment failed: ${resultat?.sms}");

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultat?.sms ?? 'Erreur lors du traitement du paiement'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      print("💥 Payment error: $e");
      print("📍 Stack trace: $stackTrace");

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
