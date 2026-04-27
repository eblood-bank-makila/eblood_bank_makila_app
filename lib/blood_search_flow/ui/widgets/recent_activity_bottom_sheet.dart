/// Recent Activity Bottom Sheet
/// Shows pending deliveries and today's succeeded address requests in 2 tabs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/recent_activity_provider.dart';
import '../../../apps/config/theme/ColorPages.dart';

/// Show the recent activity bottom sheet
/// [initialTab] - 0 for pending deliveries, 1 for today address requests
Future<void> showRecentActivityBottomSheet(
  BuildContext context, {
  int initialTab = 0,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => RecentActivityBottomSheet(initialTab: initialTab),
  );
}

class RecentActivityBottomSheet extends ConsumerStatefulWidget {
  final int initialTab;

  const RecentActivityBottomSheet({super.key, this.initialTab = 0});

  @override
  ConsumerState<RecentActivityBottomSheet> createState() =>
      _RecentActivityBottomSheetState();
}

class _RecentActivityBottomSheetState
    extends ConsumerState<RecentActivityBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(recentActivityProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.activity,
                    color: ColorPages.COLOR_PRINCIPAL,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'my_activity'.tr.isEmpty ? 'My Activity' : 'my_activity'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                // Refresh button
                IconButton(
                  onPressed: activityState.isLoading
                      ? null
                      : () => ref
                            .read(recentActivityProvider.notifier)
                            .fetchRecentActivity(),
                  icon: activityState.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorPages.COLOR_PRINCIPAL,
                          ),
                        )
                      : Icon(
                          Iconsax.refresh,
                          color: ColorPages.COLOR_PRINCIPAL,
                          size: 22,
                        ),
                ),
                // Close button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Iconsax.close_circle,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.truck_fast, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'pending_deliveries'.tr.isEmpty
                              ? 'Deliveries'
                              : 'pending_deliveries'.tr,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activityState.pendingDeliveries.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _CountBadge(count: activityState.pendingDeliveries.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.location, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'address_requests'.tr.isEmpty
                              ? 'Addresses'
                              : 'address_requests'.tr,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activityState.todayAddressRequests.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _CountBadge(count: activityState.todayAddressRequests.length),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Pending deliveries
                _PendingDeliveriesTab(
                  items: activityState.pendingDeliveries,
                  isLoading: activityState.isLoading,
                ),
                // Tab 2: Today's address requests
                _TodayAddressRequestsTab(
                  items: activityState.todayAddressRequests,
                  isLoading: activityState.isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Count Badge
// ============================================
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.ubuntu(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================
// Tab 1: Pending Deliveries
// ============================================
class _PendingDeliveriesTab extends StatelessWidget {
  final List<PendingDeliveryItem> items;
  final bool isLoading;

  const _PendingDeliveriesTab({
    required this.items,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return _EmptyState(
        icon: Iconsax.truck_fast,
        title: 'no_pending_deliveries'.tr.isEmpty
            ? 'No Pending Deliveries'
            : 'no_pending_deliveries'.tr,
        subtitle: 'no_pending_deliveries_desc'.tr.isEmpty
            ? 'Your delivery orders will appear here'
            : 'no_pending_deliveries_desc'.tr,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _DeliveryCard(item: item);
      },
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final PendingDeliveryItem item;
  const _DeliveryCard({required this.item});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_delivery':
      case 'processing':
        return Colors.orange;
      case 'in_progress_delivery':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Iconsax.truck_fast, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.identifier,
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.statusDisplay,
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    if (item.createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(item.createdAt!),
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '\$${item.totalAmountMerged.toStringAsFixed(2)}',
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Tab 2: Today Address Requests
// ============================================
class _TodayAddressRequestsTab extends StatelessWidget {
  final List<TodayAddressRequestItem> items;
  final bool isLoading;

  const _TodayAddressRequestsTab({
    required this.items,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return _EmptyState(
        icon: Iconsax.location,
        title: 'no_address_requests'.tr.isEmpty
            ? 'No Address Requests Today'
            : 'no_address_requests'.tr,
        subtitle: 'no_address_requests_desc'.tr.isEmpty
            ? 'Your address view requests from today will appear here'
            : 'no_address_requests_desc'.tr,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _AddressRequestCard(item: item);
      },
    );
  }
}

class _AddressRequestCard extends StatelessWidget {
  final TodayAddressRequestItem item;
  const _AddressRequestCard({required this.item});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Iconsax.location, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.bloodBankName ?? item.identifier,
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.statusDisplay,
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    if (item.createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(item.createdAt!),
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '\$${item.totalAmountMerged.toStringAsFixed(2)}',
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Empty State
// ============================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.ubuntu(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Helpers
// ============================================
String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just_now'.tr.isEmpty ? 'Just now' : 'just_now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  } catch (_) {
    return '';
  }
}
