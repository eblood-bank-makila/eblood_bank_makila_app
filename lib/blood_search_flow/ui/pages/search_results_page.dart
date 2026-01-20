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
        title: 'search_results'.tr.isEmpty ? 'Search Results' : 'search_results'.tr,
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
                          Icon(Iconsax.location, size: 14, color: Colors.grey.shade600),
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
                            onTap: () => _showOptionBottomSheet(context, ref, result),
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
              'no_results_found'.tr.isEmpty ? 'No Results Found' : 'no_results_found'.tr,
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
                'modify_search'.tr.isEmpty ? 'Modify Search' : 'modify_search'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPages.COLOR_PRINCIPAL,
                side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  void _showOptionBottomSheet(BuildContext context, WidgetRef ref, BloodSearchResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OptionChoiceBottomSheet(
        result: result,
        onViewAddress: () {
          Navigator.pop(context);
          ref.read(searchFlowProvider.notifier).selectResult(result);
          context.push('/blood-search/hospital-identify', extra: {'option': 'view_address'});
        },
        onOrderDelivery: () {
          Navigator.pop(context);
          ref.read(searchFlowProvider.notifier).selectResult(result);
          context.push('/blood-search/hospital-identify', extra: {'option': 'delivery'});
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final BloodSearchResult result;
  final VoidCallback onTap;

  const _ResultCard({
    required this.result,
    required this.onTap,
  });

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Blood type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ColorPages.COLOR_PRINCIPAL,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.fullBloodType.isNotEmpty ? result.fullBloodType : result.bloodType,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Hospital name
                    Expanded(
                      child: Text(
                        result.hospitalName ?? result.bloodBankName,
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Price badge
                    if (result.price > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          result.formattedPrice,
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Location
                Row(
                  children: [
                    Icon(Iconsax.location, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        result.address ?? 'Address not available',
                        style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (result.distanceKm != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${result.distanceKm!.toStringAsFixed(1)} km',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Product type and expiry info row
                if (result.bloodProductType != null || result.daysUntilExpiry != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (result.bloodProductType != null) ...[
                        Icon(Iconsax.drop, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          result.bloodProductType!.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (result.bloodProductType != null && result.daysUntilExpiry != null)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (result.daysUntilExpiry != null) ...[
                        Icon(
                          Iconsax.timer_1,
                          size: 14,
                          color: result.daysUntilExpiry! <= 14 ? Colors.orange : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${result.daysUntilExpiry} days',
                          style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            color: result.daysUntilExpiry! <= 14 ? Colors.orange : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Availability and quantity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: result.isAvailable ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          result.isAvailable
                              ? ('available'.tr.isEmpty ? 'Available' : 'available'.tr)
                              : ('limited_stock'.tr.isEmpty ? 'Limited Stock' : 'limited_stock'.tr),
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            color: result.isAvailable ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'view_options'.tr.isEmpty ? 'View Options' : 'view_options'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            color: ColorPages.COLOR_PRINCIPAL,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Iconsax.arrow_right_3,
                          size: 16,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
