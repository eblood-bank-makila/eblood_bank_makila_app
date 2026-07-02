import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../core/rbac/providers/rbac_provider.dart';
import '../../../delivery/ui/widgets/IncomingDeliveryWidget.dart';
import '../../../delivery/ui/widgets/OutgoingDeliveryWidget.dart';
import '../../business/interactors/BloodBankController.dart';
import 'AnnouncementsManagementPage.dart';
import 'BloodBankInventoryPage.dart';
import 'HealthStructureNetworkPage.dart';
import 'WalletManagementPage.dart';
import 'BloodDonorsManagementPage.dart';

class BloodBankHomePage extends ConsumerStatefulWidget {
  const BloodBankHomePage({super.key});

  @override
  ConsumerState<BloodBankHomePage> createState() => _BloodBankHomePageState();
}

class _BloodBankHomePageState extends ConsumerState<BloodBankHomePage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.wait([
        ref.read(bloodStockControllerProvider.notifier).loadBloodStock(),
        ref.read(bloodRequestsControllerProvider.notifier).loadBloodRequests(),
        ref.read(bloodBankStatsControllerProvider.notifier).loadStats(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Method for pull-to-refresh
  Future<void> _refreshData() async {
    return _loadData();
  }

  /// Check if a sub_menu flag exists in the loaded RBAC applications.
  /// Delegates to the shared helper on `RbacNotifier` so every blood bank
  /// page uses the same search logic.
  bool _hasSubMenu(String flag) =>
      ref.read(rbacProvider.notifier).hasMenuFlag(flag);

  /// Same as `_hasSubMenu` but accepts a pool of flags — used for shared
  /// pages reachable from multiple profiles (blood_bank + cnts). Returns
  /// true when ANY of the supplied flags is granted.
  bool _hasAnySubMenu(List<String> flags) =>
      ref.read(rbacProvider.notifier).hasAnyMenuFlag(flags);

  String _relativeTimeFrom(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) {
      return 'minutes_ago'.trParams({'minutes': diff.inMinutes.toString()});
    } else if (diff.inHours < 24) {
      return 'hours_ago'.trParams({'hoursh': '${diff.inHours}h'});
    } else {
      return 'days_ago'.trParams({'days': diff.inDays.toString()});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _isRefreshing ? PreferredSize(
        preferredSize: const Size.fromHeight(2.0),
        child: LinearProgressIndicator(
          color: ColorPages.COLOR_PRINCIPAL,
          backgroundColor: Colors.grey.shade200,
        ),
      ) : null,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refreshData,
              color: ColorPages.COLOR_PRINCIPAL,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Stats Cards (visible only if user has inventory access).
                    // Pool with the CNTS inventory app flag so CNTS users — who
                    // reuse this same screen — also see the dashboard stats.
                    if (_hasAnySubMenu([
                      'flutter_apps_eblood_bank_bb_home_inventory',
                      'flutter_apps_eblood_bank_cnts_inventory_app',
                    ])) ...[
                      _buildStatsSection(),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions
                    _buildQuickActionsSection(),
                    const SizedBox(height: 24),

                    // Recent Activity
                    _buildRecentActivitySection(),

                    // Bottom padding so the floating delivery cards never
                    // cover the last content rows.
                    const SizedBox(height: 180),
                  ],
                ),
              ),
            ),
            // Floating delivery cards (both self-hide when empty):
            // — OutgoingDeliveryWidget: SELLER handover confirmation
            //   (blood bank → hospital, or CNTS → blood bank).
            // — IncomingDeliveryWidget: BUYER reception confirmation
            //   (blood bank buying from CNTS).
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutgoingDeliveryWidget(),
                  IncomingDeliveryWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'blood_bank'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'dashboard_title'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Iconsax.hospital,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    // Get state for the stats controller to check for errors
    final statsState = ref.watch(bloodBankStatsControllerProvider);
    final totalStock = ref.watch(totalStockProvider);
    final pendingRequests = ref.watch(pendingRequestsCountProvider);
    final criticalStock = ref.watch(criticalStockCountProvider);
    final expiringStock = ref.watch(expiringStockCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'statistics'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            if (statsState.error != null)
              GestureDetector(
                onTap: () {
                  // Retry loading stats
                  _loadData();
                },
                child: Tooltip(
                  message: statsState.error!.contains('Permission denied')
                    ? 'limited_permission_warning'.tr
                    : 'loading_error_retry'.tr,
                  child: Icon(
                    Iconsax.warning_2,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _buildStatCard(
                  title: 'total_stock'.tr,
                  value: totalStock.value.toString(),
                  icon: Iconsax.box,
                  color: ColorPages.COLOR_PRINCIPAL,
                  trend: totalStock.trend,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: _buildStatCard(
                  title: 'requests'.tr,
                  value: pendingRequests.value.toString(),
                  icon: Iconsax.document_text,
                  color: Colors.blue,
                  trend: pendingRequests.trend,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: _buildStatCard(
                  title: 'expiring_soon'.tr,
                  value: expiringStock.value.toString(),
                  icon: Iconsax.calendar,
                  color: Colors.orange,
                  trend: expiringStock.trend,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: _buildStatCard(
                  title: 'critical_stock'.tr,
                  value: criticalStock.value.toString(),
                  icon: Iconsax.warning_2,
                  color: Colors.red,
                  trend: criticalStock.trend,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    final bool hasTrend = trend.isNotEmpty && trend != "0%";
    final bool isPositiveTrend = trend.contains('+');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (hasTrend)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositiveTrend ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositiveTrend ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    // Check RBAC sub_menu access for each quick action. CNTS reuses this
    // page (RbacScreenRegistry maps cnts.bloodBankHome → BloodBankHomePage),
    // so each card pools the bb_* flag with its CNTS equivalent. Cards
    // without a CNTS counterpart (requests, wallet) stay locked for CNTS
    // users — that matches the backend seed (CNTS has no requests/wallet).
    final inventoryUnlocked = _hasAnySubMenu([
      'flutter_apps_eblood_bank_bb_home_inventory',
      'flutter_apps_eblood_bank_cnts_inventory_app',
    ]);
    final requestsUnlocked = _hasSubMenu('flutter_apps_eblood_bank_bb_home_requests');
    final walletUnlocked = _hasSubMenu('flutter_apps_eblood_bank_bb_home_wallet');
    final donorsUnlocked = _hasAnySubMenu([
      'flutter_apps_eblood_bank_bb_home_donors',
      'flutter_apps_eblood_bank_cnts_donors_app',
    ]);
    final announcementsUnlocked = _hasAnySubMenu([
      'flutter_apps_eblood_bank_bb_home_announcements',
      'flutter_apps_eblood_bank_cnts_home_announcements',
    ]);
    final networkUnlocked = _hasAnySubMenu([
      'flutter_apps_eblood_bank_bb_home_network',
      'flutter_apps_eblood_bank_cnts_home_network',
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: const Duration(milliseconds: 900),
          child: Text(
            'quick_actions'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1000),
                child: _buildActionCard(
                  title: 'manage_stock'.tr,
                  subtitle: 'inventory'.tr,
                  icon: Iconsax.box,
                  color: ColorPages.COLOR_PRINCIPAL,
                  locked: !inventoryUnlocked,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodBankInventoryPage(initialTabIndex: 1, showBackButton: true),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1100),
                child: _buildActionCard(
                  title: 'requests'.tr,
                  subtitle: 'view_all'.tr,
                  icon: Iconsax.document_text,
                  color: Colors.blue,
                  locked: !requestsUnlocked,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodBankInventoryPage(initialTabIndex: 2, showBackButton: true),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1200),
                child: _buildActionCard(
                  title: 'wallet'.tr,
                  subtitle: 'financial_management'.tr,
                  icon: Iconsax.wallet,
                  color: Colors.green,
                  locked: !walletUnlocked,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletManagementPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1300),
                child: _buildActionCard(
                  title: 'donors'.tr,
                  subtitle: 'database'.tr,
                  icon: Iconsax.people,
                  color: Colors.purple,
                  locked: !donorsUnlocked,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodDonorsManagementPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1400),
                child: _buildActionCard(
                  title: 'communications'.tr,
                  subtitle: 'announcements_events'.tr,
                  icon: Iconsax.notification,
                  color: Colors.amber.shade700,
                  locked: !announcementsUnlocked,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnnouncementsManagementPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1500),
                child: _buildActionCard(
                  title: 'network'.tr,
                  subtitle: 'health_structures'.tr,
                  icon: Iconsax.hospital,
                  color: Colors.teal,
                  locked: !networkUnlocked,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthStructureNetworkPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool locked = false,
  }) {
    final cardColor = locked ? Colors.grey.shade400 : color;

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Opacity(
        opacity: locked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: cardColor,
                      size: 24,
                    ),
                  ),
                  if (locked)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.lock,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: locked ? Colors.grey.shade500 : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: const Duration(milliseconds: 1200),
          child: Text(
            'recent_activity'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          delay: const Duration(milliseconds: 1300),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                _buildActivityItem(
                  title: 'new_request_received'.tr,
                  subtitle: 'request_from_facility_blood_units'.trParams({'facility': 'Hôpital Central', 'blood': 'O+', 'count': '2'}),
                  time: _relativeTimeFrom(DateTime.now().subtract(const Duration(minutes: 5))),
                  icon: Iconsax.document_text,
                  color: Colors.blue,
                ),
                const Divider(height: 1),
                _buildActivityItem(
                  title: 'stock_added'.tr,
                  subtitle: 'blood_units_count'.trParams({'blood': 'A+', 'count': '10'}),
                  time: _relativeTimeFrom(DateTime.now().subtract(const Duration(hours: 1))),
                  icon: Iconsax.add_circle,
                  color: Colors.green,
                ),
                const Divider(height: 1),
                _buildActivityItem(
                  title: 'delivery_confirmed'.tr,
                  subtitle: 'request_from_facility_blood_units'.trParams({'facility': 'Clinique Saint-Joseph', 'blood': 'B+', 'count': '1'}),
                  time: _relativeTimeFrom(DateTime.now().subtract(const Duration(hours: 2))),
                  icon: Iconsax.tick_circle,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
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
          Text(
            time,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
