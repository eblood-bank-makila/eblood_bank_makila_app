import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../business/interactors/BloodBankController.dart';
import 'AddBloodStockPage.dart';

enum InventoryTab {
  overview,
  bloodStock,
  requests,
  reports,
  settings,
}

class BloodBankInventoryPage extends ConsumerStatefulWidget {
  const BloodBankInventoryPage({super.key});

  @override
  ConsumerState<BloodBankInventoryPage> createState() => _BloodBankInventoryPageState();
}

class _BloodBankInventoryPageState extends ConsumerState<BloodBankInventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InventoryTab _currentTab = InventoryTab.overview;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = InventoryTab.values[_tabController.index];
      });
    });

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bloodStockControllerProvider.notifier).loadBloodStock();
      ref.read(bloodRequestsControllerProvider.notifier).loadBloodRequests();
      ref.read(bloodBankStatsControllerProvider.notifier).loadStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab Navigation
            _buildTabNavigation(),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildBloodStockTab(),
                  _buildRequestsTab(),
                  _buildReportsTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion d\'Inventaire',
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Banque de Sang Makila',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
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
                Iconsax.box,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: ColorPages.COLOR_PRINCIPAL,
          labelColor: ColorPages.COLOR_PRINCIPAL,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(Iconsax.chart, size: 20),
              text: 'Vue d\'ensemble',
            ),
            Tab(
              icon: Icon(Iconsax.box, size: 20),
              text: 'Stock de Sang',
            ),
            Tab(
              icon: Icon(Iconsax.document_text, size: 20),
              text: 'Demandes',
            ),
            Tab(
              icon: Icon(Iconsax.chart_square, size: 20),
              text: 'Rapports',
            ),
            Tab(
              icon: Icon(Iconsax.setting_2, size: 20),
              text: 'Paramètres',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 24),
          
          // Blood Type Distribution
          _buildBloodTypeDistribution(),
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalStock = ref.watch(totalStockProvider);
    final pendingRequests = ref.watch(pendingRequestsCountProvider);
    final criticalStock = ref.watch(criticalStockCountProvider);
    final expiringStock = ref.watch(expiringStockCountProvider);

    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques Rapides',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Stock Total',
                  value: totalStock.toString(),
                  subtitle: 'unités',
                  icon: Iconsax.box,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Demandes Actives',
                  value: pendingRequests.toString(),
                  subtitle: 'en attente',
                  icon: Iconsax.clock,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Stock Critique',
                  value: criticalStock.toString(),
                  subtitle: 'types de sang',
                  icon: Iconsax.warning_2,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Expiration Proche',
                  value: expiringStock.toString(),
                  subtitle: 'dans 7 jours',
                  icon: Iconsax.calendar,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
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
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeDistribution() {
    final stockState = ref.watch(bloodStockControllerProvider);
    final stockByType = stockState.stocks.isNotEmpty
        ? ref.read(bloodStockControllerProvider.notifier).getStockByTypeMap()
        : <String, int>{};
    final totalStock = ref.watch(totalStockProvider);

    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Text(
              'Distribution par Type de Sang',
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            if (stockState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (stockByType.isEmpty)
              Center(
                child: Text(
                  'Aucun stock disponible',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              ...stockByType.entries.map((entry) =>
                _buildBloodTypeItem({
                  'type': entry.key,
                  'quantity': entry.value,
                }, totalStock)
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTypeItem(Map<String, dynamic> bloodType, [int? totalStock]) {
    final total = totalStock ?? 245;
    final quantity = bloodType['quantity'] as int;
    final percentage = total > 0 ? (quantity / total * 100).round() : 0;
    final stockLevel = _getStockLevel(quantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stockLevel['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                bloodType['type'],
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: stockLevel['color'],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$quantity unités',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(stockLevel['color']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Text(
              'Activité Récente',
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ..._getRecentActivities().map((activity) =>
              _buildActivityItem(activity)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['subtitle'],
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity['time'],
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodStockTab() {
    return const Center(
      child: Text('Blood Stock Management - Coming Soon'),
    );
  }

  Widget _buildRequestsTab() {
    return const Center(
      child: Text('Requests Management - Coming Soon'),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Text('Reports - Coming Soon'),
    );
  }

  Widget _buildSettingsTab() {
    return const Center(
      child: Text('Settings - Coming Soon'),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentTab) {
      case InventoryTab.bloodStock:
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddBloodStockPage(),
              ),
            );
          },
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
          icon: const Icon(Iconsax.add, color: Colors.white),
          label: Text(
            'Ajouter Stock',
            style: GoogleFonts.ubuntu(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      default:
        return null;
    }
  }



  Map<String, dynamic> _getStockLevel(int quantity) {
    if (quantity >= 30) {
      return {'level': 'Normal', 'color': Colors.green};
    } else if (quantity >= 15) {
      return {'level': 'Faible', 'color': Colors.orange};
    } else {
      return {'level': 'Critique', 'color': Colors.red};
    }
  }

  List<Map<String, dynamic>> _getRecentActivities() {
    return [
      {
        'title': 'Stock ajouté',
        'subtitle': 'O+ - 10 unités ajoutées',
        'time': 'Il y a 2h',
        'icon': Iconsax.add_circle,
        'color': Colors.green,
      },
      {
        'title': 'Demande approuvée',
        'subtitle': 'Hôpital Central - A+ (3 unités)',
        'time': 'Il y a 4h',
        'icon': Iconsax.tick_circle,
        'color': Colors.blue,
      },
      {
        'title': 'Stock critique',
        'subtitle': 'AB- - Seulement 4 unités restantes',
        'time': 'Il y a 6h',
        'icon': Iconsax.warning_2,
        'color': Colors.red,
      },
    ];
  }
}
