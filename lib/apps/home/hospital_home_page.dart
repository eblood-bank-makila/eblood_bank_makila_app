import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../utilisateurs/ui/pages/patient/PatientManagementPage.dart';
import '../services/HospitalDashboardService.dart';
import '../../gestionStocks/ui/pages/hospital/HospitalInventoryPage.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/ColorPages.dart';
import '../../gestionStocks/ui/pages/recherchePoche/RecherchePochePage.dart';
import '../../commande/ui/pages/blood_request/BloodRequestPage.dart';
import '../../commande/ui/pages/panier/PanierPage.dart';
import '../../blood_bank/ui/pages/HealthStructureNetworkPage.dart';
import '../../utilisateurs/ui/pages/notification/NotificationPage.dart';
import '../../utilisateurs/ui/pages/users/UserManagementPage.dart';

import '../widgets/advertisement/AdvertisementCarousel.dart';

/// Hospital/Blood Bank Home Page - Main dashboard with stats and quick actions
class HospitalHomePage extends ConsumerStatefulWidget {
  const HospitalHomePage({super.key});

  @override
  ConsumerState<HospitalHomePage> createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends ConsumerState<HospitalHomePage> {
  bool _loading = true;

  // Stats (now loaded from API)
  int _totalRequests = 0;
  int _activeRequests = 0;
  int _totalBloodBags = 0;
  int _totalUsers = 0;
  int _totalPatients = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      final data = await HospitalDashboardService().fetchDashboard();
      if (!mounted) return;
      setState(() {
        _totalRequests = data.totalRequests;
        _activeRequests = data.activeRequests;
        _totalBloodBags = data.totalBloodBags;
        _totalUsers = data.totalUsers;
        _totalPatients = data.totalPatients;
      });
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
              Colors.red.shade100,
              Colors.red.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo and Title/Sub-title (match BanquePage)
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'E-Blood Bank',
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorPages.COLOR_PRINCIPAL,
                          ),
                        ),
                        Text(
                          'Sauvez des vies en un clique',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Notification Button (match BanquePage)
                Container(
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_BLANCHE.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationPage(notification: []),
                            ),
                          );
                        },
                        icon: Icon(
                          Iconsax.notification,
                          color: ColorPages.COLOR_PRINCIPAL,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: ColorPages.COLOR_PRINCIPAL,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
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
                // Advertisement Carousel
                const AdvertisementCarousel(
                  targetAudience: 'hospital',
                  height: 180,
                  autoPlay: true,
                  showIndicators: true,
                  useMockData: false, // Using real API now!
                ),

                const SizedBox(height: 24),

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
                subtitle: 'ordered'.tr,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'users'.tr,
                value: _totalUsers.toString(),
                total: '',
                icon: Iconsax.profile_2user,
                color: Colors.orange,
                subtitle: 'active'.tr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'patients'.tr,
                value: _totalPatients.toString(),
                total: '',
                icon: Iconsax.user,
                color: Colors.green,
                subtitle: 'active'.tr,
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

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildActionCard(
              title: 'requests'.tr,
              subtitle: 'manage_requests'.tr,
              icon: Iconsax.document_text,
              color: ColorPages.COLOR_PRINCIPAL,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BloodRequestPage()),
                );
              },
            ),
            _buildActionCard(
              title: 'users'.tr,
              subtitle: 'manage_users'.tr,
              icon: Iconsax.profile_2user,
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserManagementPage()),
                );
              },
            ),
            _buildActionCard(
              title: 'search'.tr,
              subtitle: 'search_blood_bags'.tr,
              icon: Iconsax.search_normal,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Recherchepage(query: '', isModal: false, showBack: true),
                  ),
                );
              },
            ),
            _buildActionCard(
              title: 'network'.tr,
              subtitle: 'medical_network'.tr,
              icon: Iconsax.people,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HealthStructureNetworkPage()),
                );
              },
            ),
            _buildActionCard(
              title: 'cart'.tr,
              subtitle: 'view_cart'.tr,
              icon: Iconsax.shopping_cart,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PanierPage(showBack: true)),
                );
              },
            ),
            _buildActionCard(
              title: 'patients'.tr,
              subtitle: 'manage_patients'.tr,
              icon: Iconsax.user,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientManagementPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              title: 'storage'.tr,
              subtitle: 'manage_storage'.tr,
              icon: Iconsax.security_safe,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HospitalInventoryPage(),
                  ),
                );
              },
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
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'recent_activity'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BloodRequestPage()),
                );
              },
              child: Text(
                'view_all'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: ColorPages.COLOR_PRINCIPAL,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          icon: Iconsax.document_text,
          title: 'new_blood_request'.tr,
          subtitle: '2_hours_ago'.tr,
          color: ColorPages.COLOR_PRINCIPAL,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: Iconsax.tick_circle,
          title: 'request_completed'.tr,
          subtitle: '5_hours_ago'.tr,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: Iconsax.warning_2,
          title: 'low_stock_alert'.tr,
          subtitle: '1_day_ago'.tr,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          Icon(
            Iconsax.arrow_right_3,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
