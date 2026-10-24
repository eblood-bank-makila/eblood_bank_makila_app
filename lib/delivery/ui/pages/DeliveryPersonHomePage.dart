import 'package:animate_do/animate_do.dart';
import '../../business/interactors/courier_dashboard_provider.dart';
import '../../business/model/courier_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../core/rbac/services/rbac_guard.dart';
import '../../business/interactors/DeliveryController.dart';
import '../widgets/ActiveDeliveryWidget.dart';
import '../widgets/duty_switch.dart';
import '../widgets/PendingDeliveryRequestWidget.dart';
import 'DeliveryManagementPage.dart';

class DeliveryPersonHomePage extends ConsumerStatefulWidget {
  const DeliveryPersonHomePage({super.key});

  @override
  ConsumerState<DeliveryPersonHomePage> createState() => _DeliveryPersonHomePageState();
}

class _DeliveryPersonHomePageState extends ConsumerState<DeliveryPersonHomePage> {
  @override
  void initState() {
    super.initState();
    // RBAC entry guard — only users with the MOBILE_APP_DELIVERY_PERSON_PROFILE
    // extra profile (granted via SysUserLinkedProfil + ExtraProfileService)
    // receive this sub_menu in their app tree.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_home_delivery_dashboard',
    );
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load pending delivery requests
      ref.read(pendingDeliveryRequestProvider.notifier).loadPendingRequests();
      ref.read(pendingDeliveryRequestProvider.notifier).loadActiveDelivery();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPendingRequests = ref.watch(hasPendingRequestsProvider);
    final hasActiveDelivery = ref.watch(hasActiveDeliveryProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Main content
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Performance Stats
                    _buildPerformanceSection(),
                    const SizedBox(height: 24),

                    // Today's Deliveries
                    _buildTodayDeliveriesSection(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActionsSection(),

                    // Add bottom padding for floating widget
                    if (hasPendingRequests || hasActiveDelivery) const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ),
          // Floating active delivery widget (when delivery is in progress)
          if (hasActiveDelivery && !hasPendingRequests)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ActiveDeliveryWidget(),
            ),
          // Floating pending delivery request widget (Yango-style)
          if (hasPendingRequests)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PendingDeliveryRequestWidget(
                onAccepted: () => ref.invalidate(courierDashboardProvider),
                onRejected: () {
                  // Optional: show feedback
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: ColorPages.COLOR_PRINCIPAL),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'delivery_person'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'dashboard'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          DutySwitch(),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final dash = ref.watch(courierDashboardProvider).valueOrNull;
    String n(int Function(CourierDashboard) pick) => dash == null ? '–' : pick(dash).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          delay: const Duration(milliseconds: 400),
          child: Text(
            'performance'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _buildStatCard(
                  title: 'total_deliveries'.tr,
                  value: n((d) => d.total),
                  icon: Iconsax.box_tick,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: _buildStatCard(
                  title: 'in_progress'.tr,
                  value: n((d) => d.inProgress),
                  icon: Iconsax.truck_time,
                  color: Colors.blue,
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
                  title: 'completed'.tr,
                  value: n((d) => d.delivered),
                  icon: Iconsax.medal_star,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: _buildStatCard(
                  title: 'urgent_deliveries'.tr,
                  value: n((d) => d.urgent),
                  icon: Iconsax.timer_1,
                  color: Colors.purple,
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
  }) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayDeliveriesSection() {
    final dash = ref.watch(courierDashboardProvider).valueOrNull;
    final today = dash?.today ?? const <CourierDeliveryRow>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          delay: const Duration(milliseconds: 900),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'todays_deliveries'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'in_progress_count'.tr.replaceAll('@count', '${dash?.inProgress ?? 0}'),
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          delay: const Duration(milliseconds: 1000),
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
            child: today.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'courier_no_deliveries_today'.tr,
                        style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final (i, d) in today.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        _buildDeliveryItem(d),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Phase chip: label and colour for a delivery's phase.
  (String, Color) _phaseChip(String phase) => switch (phase) {
        'delivered_and_confirmed' => ('delivered'.tr, Colors.green),
        'cancelled' => ('courier_phase_cancelled'.tr, Colors.red),
        'at_hospital' => ('at_hospital'.tr, Colors.teal),
        'picked_up_from_blood_bank' => ('collected'.tr, Colors.orange),
        'en_route_to_hospital' => ('en_route'.tr, Colors.blue),
        _ => ('pill_to_bank'.tr, Colors.deepOrange),
      };

  Widget _buildDeliveryItem(CourierDeliveryRow d) {
    final (status, statusColor) = _phaseChip(d.phase);
    final at = (d.confirmedAt ?? d.acceptedAt ?? d.updatedAt)?.toLocal();
    final time = at == null ? '' : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (d.isUrgent ? Colors.red : ColorPages.COLOR_PRINCIPAL).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(d.isUrgent ? Iconsax.danger : Iconsax.truck_fast,
                size: 20, color: d.isUrgent ? Colors.red : ColorPages.COLOR_PRINCIPAL),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.hospitalName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [if (d.bloodBankName != null) d.bloodBankName!, if (time.isNotEmpty) time].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.ubuntu(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          delay: const Duration(milliseconds: 1100),
          child: Text(
            'quick_actions'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 1200),
                child: _buildActionCard(
                  title: 'my_deliveries'.tr,
                  subtitle: 'manage_deliveries'.tr,
                  icon: Iconsax.truck,
                  color: ColorPages.COLOR_PRINCIPAL,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeliveryManagementPage(),
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
                  title: 'scan_qr'.tr,
                  subtitle: 'confirm_delivery'.tr,
                  icon: Iconsax.scan_barcode,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to QR scanner
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('qr_feature_coming_soon'.tr),
                        behavior: SnackBarBehavior.floating,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
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
    );
  }
}
