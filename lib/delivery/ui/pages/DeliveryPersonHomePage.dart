import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../business/interactors/DeliveryController.dart';
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
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryControllerProvider.notifier).loadDeliveries();
      ref.read(deliveryStatsControllerProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              ],
            ),
          ),
        ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.truck,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final totalDeliveries = ref.watch(totalDeliveriesCountProvider);
    final inProgressDeliveries = ref.watch(inProgressDeliveriesCountProvider);
    final deliveredDeliveries = ref.watch(deliveredDeliveriesCountProvider);
    final urgentDeliveries = ref.watch(urgentDeliveriesCountProvider);

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
                  value: totalDeliveries.toString(),
                  icon: Iconsax.box_tick,
                  color: Colors.green,
                  trend: '+15%',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: _buildStatCard(
                  title: 'in_progress'.tr,
                  value: inProgressDeliveries.toString(),
                  icon: Iconsax.truck_time,
                  color: Colors.blue,
                  trend: '0%',
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
                  value: deliveredDeliveries.toString(),
                  icon: Iconsax.medal_star,
                  color: Colors.orange,
                  trend: '+2%',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: _buildStatCard(
                  title: 'urgent_deliveries'.tr,
                  value: urgentDeliveries.toString(),
                  icon: Iconsax.timer_1,
                  color: Colors.purple,
                  trend: '-5min',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                trend,
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: trend.startsWith('+') || trend.contains('-5min') 
                      ? Colors.green 
                      : trend == '0%' 
                          ? Colors.grey 
                          : Colors.red,
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
                  'in_progress_count'.tr.replaceAll('@count', '3'),
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
            child: Column(
              children: [
                _buildDeliveryItem(
                  destination: 'Hôpital Central',
                  bloodType: 'O+',
                  quantity: '2 ${'units'.tr}',
                  status: 'en_route'.tr,
                  statusColor: Colors.blue,
                  distance: '2.5 km',
                  estimatedTime: '15 min',
                ),
                const Divider(height: 1),
                _buildDeliveryItem(
                  destination: 'Clinique Saint-Joseph',
                  bloodType: 'A-',
                  quantity: '1 ${'unit'.tr}',
                  status: 'collected'.tr,
                  statusColor: Colors.orange,
                  distance: '4.2 km',
                  estimatedTime: '25 min',
                ),
                const Divider(height: 1),
                _buildDeliveryItem(
                  destination: 'Hôpital Universitaire',
                  bloodType: 'B+',
                  quantity: '3 ${'units'.tr}',
                  status: 'delivered'.tr,
                  statusColor: Colors.green,
                  distance: '1.8 km',
                  estimatedTime: 'finished'.tr,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryItem({
    required String destination,
    required String bloodType,
    required String quantity,
    required String status,
    required Color statusColor,
    required String distance,
    required String estimatedTime,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                bloodType,
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      quantity,
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      ' • $distance • $estimatedTime',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
