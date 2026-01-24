/// Search Results Page
/// Displays blood search results with option choice bottom sheet

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
import '../widgets/search_flow_progress_indicator.dart';
import '../widgets/option_choice_bottom_sheet.dart';

class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchFlowProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: 'search_results'.tr.isEmpty
            ? 'Search Results'
            : 'search_results'.tr,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          // Progress indicator
          SearchFlowProgressIndicator(
            currentStep: 3,
            totalSteps: 4,
            stepLabels: [
              'step_city'.tr,
              'step_blood_type'.tr,
              'step_results'.tr,
              'step_confirm'.tr,
            ],
          ),

          // Search info header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                  Colors.red.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      state.searchedBloodType ?? '--',
                      style: GoogleFonts.ubuntu(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'blood_type_search'.tr.isEmpty
                            ? 'Blood Type Search'
                            : 'blood_type_search'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.selectedCity?.name ?? '--',
                            style: GoogleFonts.ubuntu(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${state.searchResults.length}',
                  style: GoogleFonts.ubuntu(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
              ],
            ),
          ),

          // Results list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.searchResults.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final result = state.searchResults[index];
                      return _ResultCard(
                        result: result,
                        onTap: () =>
                            _showOptionBottomSheet(context, ref, result),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.search_status,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_results_found'.tr.isEmpty
                  ? 'No Results Found'
                  : 'no_results_found'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'no_blood_available'.tr.isEmpty
                  ? 'No blood products matching your criteria are currently available in this area.'
                  : 'no_blood_available'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Iconsax.arrow_left_2, size: 18),
              label: Text(
                'modify_search'.tr.isEmpty
                    ? 'Modify Search'
                    : 'modify_search'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPages.COLOR_PRINCIPAL,
                side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionBottomSheet(
    BuildContext context,
    WidgetRef ref,
    BloodSearchResult result,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OptionChoiceBottomSheet(
        result: result,
        onViewAddress: () {
          Navigator.pop(context);
          ref.read(searchFlowProvider.notifier).selectResult(result);
          ref
              .read(searchFlowProvider.notifier)
              .selectPaymentOption(PaymentOption.viewAddress);
          context.push(
            '/blood-search/hospital-identify',
            extra: {'option': 'view_address'},
          );
        },
        onOrderDelivery: () {
          Navigator.pop(context);
          ref.read(searchFlowProvider.notifier).selectResult(result);
          ref
              .read(searchFlowProvider.notifier)
              .selectPaymentOption(PaymentOption.delivery);
          context.push(
            '/blood-search/hospital-identify',
            extra: {'option': 'delivery'},
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatefulWidget {
  final BloodSearchResult result;
  final VoidCallback onTap;

  const _ResultCard({required this.result, required this.onTap});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Delay the animation start by 3 seconds so user can read the text first
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _animationStarted = true);
        _shimmerController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ 
                const SizedBox(height: 12),
                // Distance (prominent display)
                Row(
                  children: [
                    Icon(
                      Iconsax.routing_2,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.result.formattedDistance,
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'from_you'.tr.isEmpty ? 'from you' : 'from_you'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // Product type and expiry info row
                if (widget.result.bloodProductType != null ||
                    widget.result.daysUntilExpiry != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.result.bloodProductType != null) ...[
                        Icon(
                          Iconsax.drop,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.result.bloodProductType!
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (widget.result.bloodProductType != null &&
                          widget.result.daysUntilExpiry != null)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (widget.result.daysUntilExpiry != null) ...[
                        Icon(
                          Iconsax.timer_1,
                          size: 14,
                          color: widget.result.daysUntilExpiry! <= 14
                              ? Colors.orange
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.result.daysUntilExpiry} days',
                          style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            color: widget.result.daysUntilExpiry! <= 14
                                ? Colors.orange
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Divider
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                // Options section title
                Text(
                  'see_options'.tr.isEmpty ? 'See Options' : 'see_options'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                // View Address Option
                _buildOptionRow(
                  icon: Iconsax.location,
                  iconColor: Colors.blue,
                  title: 'view_full_address'.tr.isEmpty
                      ? 'View Full Address'
                      : 'view_full_address'.tr,
                  price: '500 CDF',
                ),
                const SizedBox(height: 8),
                // Delivery Option
                _buildOptionRow(
                  icon: Iconsax.truck_fast,
                  iconColor: Colors.orange,
                  title: 'order_delivery'.tr.isEmpty
                      ? 'Order Delivery'
                      : 'order_delivery'.tr,
                  price: widget.result.formattedPrice,
                ),
                const SizedBox(height: 12),
                // Tap to choose - with pulsing animation
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    // When background is deep (high value), text is light
                    // When background is light (low value), text is deep
                    final textColor = Color.lerp(
                      ColorPages.COLOR_PRINCIPAL,
                      Colors.white,
                      _shimmerAnimation.value * 0.9,
                    )!;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            // ColorPages.COLOR_PRINCIPAL.withOpacity(0.8),
                            // Colors.red.shade600.withOpacity(0.8),
                            // ColorPages.COLOR_PRINCIPAL.withOpacity(0.8),
                            ColorPages.COLOR_PRINCIPAL.withOpacity(
                              0.1 + (_shimmerAnimation.value * 0.6),
                            ),
                            Colors.red.shade600.withOpacity(
                              0.1 + (_shimmerAnimation.value * 0.5),
                            ),
                            ColorPages.COLOR_PRINCIPAL.withOpacity(
                              0.1 + (_shimmerAnimation.value * 0.6),
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ColorPages.COLOR_PRINCIPAL.withOpacity(
                            0.5 + (_shimmerAnimation.value * 0.5),
                          ),
                          width: 1.5,
                        ),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: ColorPages.COLOR_PRINCIPAL.withOpacity(_shimmerAnimation.value * 0.4),
                        //     blurRadius: 12,
                        //     spreadRadius: 1,
                        //   ),
                        // ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.finger_cricle,
                            size: 22,
                            color: textColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'tap_to_choose'.tr.isEmpty
                                ? 'Tap to choose an option'
                                : 'tap_to_choose'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Iconsax.arrow_right_3,
                            size: 16,
                            color: textColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String price,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          price,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }
}
