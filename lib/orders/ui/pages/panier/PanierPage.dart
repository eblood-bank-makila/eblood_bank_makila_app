import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/apps/widgets/ModernSpinnerWidget.dart';
import 'package:eblood_bank_mak_app/apps/widgets/PanierWidget.dart';
import 'package:eblood_bank_mak_app/orders/ui/pages/orders/pages/DetailCommandePage.dart';
import 'package:eblood_bank_mak_app/orders/ui/pages/panier/PanierCtrl.dart';
import 'package:eblood_bank_mak_app/orders/ui/pages/panier/PanierPageState.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/services/rbac_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

class PanierPage extends ConsumerStatefulWidget {
  final bool showBack;
  const PanierPage({super.key, this.showBack = false});

  @override
  ConsumerState createState() => _PanierPageState();
}

class _PanierPageState extends ConsumerState<PanierPage> {
  bool _hasFlag(String flag) =>
      ref.read(rbacProvider.notifier).hasMenuFlag(flag);

  @override
  void initState() {
    super.initState();
    // RBAC entry guard on the cart sub_menu.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_hosp_blood_bag_cart',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    var ctrl = ref.read(panierCtrlProvider.notifier);
    await ctrl.listepanier(); // Load cart items
  }

  int _calculateTotalPrice(PanierPageState state) {
    int total = 0;
    if (state.paniers?.data.isNotEmpty == true) {
      for (var cart in state.paniers!.data) {
        for (var item in cart.cartItems) {
          total += (item.quantity * item.price).toInt();
        }
      }
    }
    return total;
  }

  void _showBottomSheet(BuildContext context) {
    var state = ref.watch(panierCtrlProvider);
    int total = _calculateTotalPrice(state);
    final itemCount = state.paniers?.data[0].cartItems.length ?? 0;
    final currency = state.paniers?.data[0].currency ?? 'CDF';

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 20),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'price_details'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Price Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'products_price'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '$currency $total',
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Divider(color: Colors.grey.shade300),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'subtotal'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '$currency $total',
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorPages.COLOR_PRINCIPAL,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Payment Method and Checkout
                Row(
                  children: [
                    // Payment Method
                    Container(
                      width: 60,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/images/pay.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Checkout Button — gated on the cart-checkout flag.
                    if (_hasFlag('flutter_apps_eblood_bank_hosp_cart_checkout'))
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailCommandePage(
                                    paiement: state.paniers!.data[0],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPages.COLOR_PRINCIPAL,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.verify, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'verification_with_count'.trParams({'count': itemCount.toString()}),
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(panierCtrlProvider);
    final itemCount = state.paniers?.data.isNotEmpty == true ? state.paniers!.data[0].cartItems.length : 0;

    // Set status bar style to dark (black icons/text)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
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
                children: [
                  // Modern Header
                  _buildModernHeader(context, itemCount),

                  // Content - transparent background
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: _buildCartContent(context, state),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          AppSpinner.overlay(
            isVisible: state.isLoading,
            message: 'cart_updating'.tr,
            type: SpinnerType.ring,
            backgroundColor: Colors.black.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, int itemCount) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (widget.showBack)
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.arrow_left_2,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 22,
                ),
              ),
            ),
          if (widget.showBack) const SizedBox(width: 8),
          // Cart Icon
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Iconsax.shopping_cart5,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Title and Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'my_cart'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
                Text(
                  'selected_items_count'.trParams({'count': itemCount.toString()}),
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, PanierPageState state) {
    // Consider cart empty when there's no payload or when first cart has zero items
    final hasItems = state.paniers != null &&
        state.paniers!.data.isNotEmpty &&
        state.paniers!.data[0].cartItems.isNotEmpty;

    if (!hasItems) {
      // Show centered empty state and hide bottom verification section
      return _buildEmptyCart();
    }

    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCart,
            color: ColorPages.COLOR_PRINCIPAL,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    children: List.generate(
                      state.paniers!.data[0].cartItems.length,
                      (index) {
                        final paniers = state.paniers!.data[0];
                        return FadeInUp(
                          delay: Duration(milliseconds: 300 + (index * 100)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: PanierWidget(
                              paniers: paniers,
                              index: index,
                              onQuantityChanged: () {
                                // Cart data will be refreshed automatically by the backend sync
                                // No need to manually update state here
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Modern Bottom Bar (only visible when cart has items)
        _buildModernBottomBar(context, state),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: FadeInUp(
        delay: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Iconsax.shopping_cart,
                  size: 60,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'cart_empty_title'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'cart_empty_subtitle'.tr,
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

  Widget _buildModernBottomBar(BuildContext context, PanierPageState state) {
    final total = _calculateTotalPrice(state);
    final itemCount = state.paniers!.data[0].cartItems.length;
    final currency = state.paniers?.data[0].currency ?? 'CDF';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price Summary Row
            GestureDetector(
              onTap: () => _showBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Payment Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Iconsax.wallet_3,
                        color: ColorPages.COLOR_PRINCIPAL,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Total Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'total_to_pay'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '$currency $total',
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorPages.COLOR_PRINCIPAL,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dropdown Icon
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Checkout Button — gated on the cart-checkout flag.
            if (_hasFlag('flutter_apps_eblood_bank_hosp_cart_checkout'))
              SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailCommandePage(
                        paiement: state.paniers!.data[0],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.verify,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'verification_with_count'.trParams({'count': itemCount.toString()}),
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
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


}
