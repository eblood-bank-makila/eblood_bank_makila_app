import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/ColorPages.dart';
import '../../gestionStocks/ui/pages/banque/BanquePage.dart';
import '../../gestionStocks/ui/pages/recherchePoche/RecherchePochePage.dart';
import '../../commande/ui/pages/blood_request/BloodRequestPage.dart';
import '../../commande/ui/pages/panier/PanierPage.dart';
import '../connect/network/network_screen.dart';
import '../../utilisateurs/ui/pages/notification/NotificationPage.dart';

/// Hospital/Blood Bank Home Page - Main dashboard with stats and quick actions
class HospitalHomePage extends ConsumerStatefulWidget {
  const HospitalHomePage({super.key});

  @override
  ConsumerState<HospitalHomePage> createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends ConsumerState<HospitalHomePage> {
  bool _loading = true;
  
  // Mock stats - TODO: Replace with real API calls
  int _totalRequests = 0;
  int _activeRequests = 0;
  int _totalBloodBags = 0;
  int _lowStockAlerts = 0;
  int _totalPatients = 0;
  int _networkPartners = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      // TODO: Replace with real API calls
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _totalRequests = 24;
          _activeRequests = 8;
          _totalBloodBags = 156;
          _lowStockAlerts = 3;
          _totalPatients = 42;
          _networkPartners = 12;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dashboard'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'welcome_back'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Iconsax.notification, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(notification: []),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: ColorPages.COLOR_PRINCIPAL,
      onRefresh: _loadDashboardData,
      child: _loading
          ? _buildShimmerLoading()
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                // Stats Cards
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildStatsSection(),
                ),
                
                const SizedBox(height: 28),
                
                // Quick Actions
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildQuickActionsSection(),
                ),
                
                const SizedBox(height: 28),
                
                // Recent Activity
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildRecentActivitySection(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'overview'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'requests'.tr,
                value: _activeRequests.toString(),
                total: _totalRequests.toString(),
                icon: Iconsax.document_text,
                color: ColorPages.COLOR_PRINCIPAL,
                subtitle: 'active'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'blood_bags'.tr,
                value: _totalBloodBags.toString(),
                total: '',
                icon: Iconsax.health,
                color: Colors.blue,
                subtitle: 'in_stock'.tr,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'alerts'.tr,
                value: _lowStockAlerts.toString(),
                total: '',
                icon: Iconsax.warning_2,
                color: Colors.orange,
                subtitle: 'low_stock'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'network'.tr,
                value: _networkPartners.toString(),
                total: '',
                icon: Iconsax.hospital,
                color: Colors.green,
                subtitle: 'partners'.tr,
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
    required String total,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
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
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.ubuntu(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (total.isNotEmpty) ...[
                Text(
                  '/$total',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.ubuntu(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

