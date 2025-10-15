import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../apps/config/theme/ColorPages.dart';
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
        child: RefreshIndicator(
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
                
                // Stats Cards
                _buildStatsSection(),
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActionsSection(),
                const SizedBox(height: 24),
                
                // Recent Activity
                _buildRecentActivitySection(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banque de Sang',
                  style: GoogleFonts.ubuntu(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tableau de bord',
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
                  'Statistiques',
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
                    ? "Permission limitée. Certaines données peuvent être incomplètes."
                    : "Erreur de chargement. Appuyez pour réessayer.",
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
                  title: 'Stock Total',
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
                  title: 'Demandes',
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
                  title: 'Expiration Proche',
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
                  title: 'Stock Critique',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: const Duration(milliseconds: 900),
          child: Text(
            'Actions Rapides',
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
                  title: 'Gérer Stock',
                  subtitle: 'Inventaire',
                  icon: Iconsax.box,
                  color: ColorPages.COLOR_PRINCIPAL,
                  onTap: () {
                    // Navigate to inventory page - stock tab (index 1)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodBankInventoryPage(initialTabIndex: 1),
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
                  title: 'Demandes',
                  subtitle: 'Voir tout',
                  icon: Iconsax.document_text,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to the inventory page and select the reports tab (index 2)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodBankInventoryPage(initialTabIndex: 2),
                      ),
                    ).then((_) {
                      // Optional: Show a snackbar after returning to this page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retour de la gestion des demandes'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    });
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
                  title: 'Wallet',
                  subtitle: 'Gestion financière',
                  icon: Iconsax.wallet,
                  color: Colors.green,
                  onTap: () {
                    // Navigate to wallet/financial management
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
                  title: 'Donneurs',
                  subtitle: 'Base de données',
                  icon: Iconsax.people,
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to donor management
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
                  title: 'Communications',
                  subtitle: 'Annonces & Événements',
                  icon: Iconsax.notification,
                  color: Colors.amber.shade700,
                  onTap: () {
                    // Navigate to announcements management
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
                  title: 'Réseau',
                  subtitle: 'Structures de santé',
                  icon: Iconsax.hospital,
                  color: Colors.teal,
                  onTap: () {
                    // Navigate to health structure network
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
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
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
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          delay: const Duration(milliseconds: 1200),
          child: Text(
            'Activité Récente',
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
                  title: 'Nouvelle demande reçue',
                  subtitle: 'Hôpital Central - O+ (2 unités)',
                  time: 'Il y a 5 min',
                  icon: Iconsax.document_text,
                  color: Colors.blue,
                ),
                const Divider(height: 1),
                _buildActivityItem(
                  title: 'Stock ajouté',
                  subtitle: 'A+ (10 unités)',
                  time: 'Il y a 1h',
                  icon: Iconsax.add_circle,
                  color: Colors.green,
                ),
                const Divider(height: 1),
                _buildActivityItem(
                  title: 'Livraison confirmée',
                  subtitle: 'Clinique Saint-Joseph - B+ (1 unité)',
                  time: 'Il y a 2h',
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
