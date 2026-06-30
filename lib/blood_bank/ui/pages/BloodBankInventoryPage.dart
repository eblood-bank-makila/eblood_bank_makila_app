import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../providers/inventory_settings_provider.dart';
import '../../models/inventory_settings.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/RealDataChartPainter.dart';
import '../widgets/ReportPreviewDialog.dart';
import '../../utils/blood_translations.dart';

import '../../../apps/config/theme/ColorPages.dart';
import '../../../core/rbac/providers/rbac_provider.dart';
import '../../../core/rbac/services/rbac_url_helper.dart';
import '../../../core/rbac/enums/collection_crud_info_flag.dart';
import '../../../core/rbac/models/rbac_models.dart';
import '../../business/interactors/BloodBankController.dart';
import '../../business/interactors/BloodReportsController.dart';
import '../../business/interactors/BloodReportExportController.dart';
import '../../business/model/BloodStock.dart';
import '../../business/model/BloodEnums.dart';
import 'AddBloodStockPage.dart';
import 'BulkImportBloodStockPage.dart';

enum InventoryTab {
  overview,
  bloodStock,
  reports,
  settings,
}

class BloodBankInventoryPage extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final bool showBackButton;

  const BloodBankInventoryPage({
    super.key,
    this.initialTabIndex = 0,
    this.showBackButton = false,
  });

  @override
  ConsumerState<BloodBankInventoryPage> createState() => _BloodBankInventoryPageState();
}

class _BloodBankInventoryPageState extends ConsumerState<BloodBankInventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InventoryTab _currentTab = InventoryTab.overview;
  // Track expanded blood types
  final Set<String> _expandedBloodTypes = {};

  // ── RBAC-driven visible tabs ──
  // Built once in initState from the RBAC state. Tabs the user does not
  // have access to are completely omitted from the TabBar / TabBarView,
  // and the TabController length matches the visible count.
  late final List<InventoryTab> _allowedTabs;
  late final bool _canAddStock;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  // Settings state variables
  // Variables for settings
  // bool _darkModeEnabled = false; // Uncomment if needed later
  bool _criticalStockAlertsEnabled = true;
  bool _expirationAlertsEnabled = true;
  bool _dailySummaryEnabled = false;

  // Export reports state
  String _selectedReportFormat = 'pdf';

  /// Pool of flags helper — true when ANY flag is granted. Used because
  /// CNTS reuses this same page (per RbacScreenRegistry) and brings its
  /// own cnts_inventory_* flag set.
  bool _hasAnyFlag(List<String> flags) =>
      ref.read(rbacProvider.notifier).hasAnyMenuFlag(flags);

  @override
  void initState() {
    super.initState();

    // Build the visible tab list from RBAC flags. Each tab is unlocked when
    // EITHER the blood_bank flag OR the cnts equivalent is granted, so the
    // same page works for both profiles.
    final canOverview = _hasAnyFlag([
      'flutter_apps_eblood_bank_bb_inventory_overview',
      'flutter_apps_eblood_bank_cnts_inventory_overview',
    ]);
    final canStock = _hasAnyFlag([
      'flutter_apps_eblood_bank_bb_inventory_stock',
      'flutter_apps_eblood_bank_cnts_inventory_stock',
    ]);
    final canReports = _hasAnyFlag([
      'flutter_apps_eblood_bank_bb_inventory_reports',
      'flutter_apps_eblood_bank_cnts_inventory_reports',
    ]);
    final canSettings = _hasAnyFlag([
      'flutter_apps_eblood_bank_bb_inventory_settings',
      'flutter_apps_eblood_bank_cnts_inventory_settings',
    ]);
    _canAddStock = _hasAnyFlag([
      'flutter_apps_eblood_bank_bb_inventory_stock_add',
      'flutter_apps_eblood_bank_cnts_inventory_stock_add',
    ]) && (() {
      final rbac = ref.read(rbacProvider.notifier);
      var crudInfo = rbac.getCrudInfoByPath('flutter_apps_eblood_bank_bb_inventory_stock_add');
      if (crudInfo.isEmpty) {
        crudInfo = rbac.getCrudInfoByPath('flutter_apps_eblood_bank_cnts_inventory_stock_add');
      }
      return _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.createProcessingUrl, 'main', crudInfo);
    })();

    _allowedTabs = [
      if (canOverview) InventoryTab.overview,
      if (canStock)    InventoryTab.bloodStock,
      if (canReports)  InventoryTab.reports,
      if (canSettings) InventoryTab.settings,
    ];

    // Entry safety net: if the user has access to zero tabs, pop out.
    if (_allowedTabs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('access_denied'.tr)),
        );
        Navigator.of(context).maybePop();
      });
      // Create a minimal 1-tab controller so the rest of the widget tree
      // doesn't crash before the pop lands.
      _tabController = TabController(length: 1, vsync: this);
      _currentTab = InventoryTab.overview;
      return;
    }

    // Clamp the caller's requested initial tab to what's actually visible.
    // If the requested tab is not in _allowedTabs, fall back to index 0.
    final requestedTab = (widget.initialTabIndex >= 0 &&
            widget.initialTabIndex < InventoryTab.values.length)
        ? InventoryTab.values[widget.initialTabIndex]
        : InventoryTab.overview;
    final initialIndex = _allowedTabs.contains(requestedTab)
        ? _allowedTabs.indexOf(requestedTab)
        : 0;

    _tabController = TabController(
      length: _allowedTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _currentTab = _allowedTabs[initialIndex];
    _tabController.addListener(() {
      setState(() {
        _currentTab = _allowedTabs[_tabController.index];
      });
    });

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bloodStockControllerProvider.notifier).loadBloodStock();
      ref.read(bloodBankStatsControllerProvider.notifier).loadStats();

      // Load saved settings
      _loadSettings();
    });
  }
  
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // _darkModeEnabled = prefs.getBool('darkMode') ?? false;
        _criticalStockAlertsEnabled = prefs.getBool('criticalStockAlerts') ?? true;
        _expirationAlertsEnabled = prefs.getBool('expirationAlerts') ?? true;
        _dailySummaryEnabled = prefs.getBool('dailySummary') ?? false;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
  
  // Save a setting to SharedPreferences
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (e) {
      print('Error saving setting: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Format last updated time
  String _formatLastUpdated(DateTime dateTime) {
    return BloodTranslations.formatTimeAgo(dateTime);
  }

  // Edit price dialog - Uses structured update API
  Future<void> _editPriceDialog(String product, double currentPrice) async {
    final settingsState = ref.read(inventorySettingsProvider);
    final currentSettings = settingsState.settings;
    final currencyCode = currentSettings?.currency ?? 'USD';

    final controller = TextEditingController(text: currentPrice.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_price'.trParams({'product': BloodTranslations.getBloodComponentName(product)})),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'price_currency'.trParams({'currency': currencyCode})),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) Navigator.pop(context, value);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        // Use structured update API - only update the specific price
        final success = await ref.read(inventorySettingsProvider.notifier).updatePrice(product, result);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('price_updated'.trParams({'product': BloodTranslations.getBloodComponentName(product)}))),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('price_update_error'.tr)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${'error'.tr}: $e')),
          );
        }
      }
    }
  }

  // Edit threshold dialog - Uses structured update API
  Future<void> _editThresholdDialog(String bloodType, int currentThreshold) async {
    final controller = TextEditingController(text: currentThreshold.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_threshold'.trParams({'bloodType': BloodTranslations.getBloodTypeName(bloodType)})),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'threshold_units'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) Navigator.pop(context, value);
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        // Use structured update API - only update the specific threshold
        final success = await ref.read(inventorySettingsProvider.notifier).updateCriticalStock(bloodType, result);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('threshold_updated'.trParams({'bloodType': BloodTranslations.getBloodTypeName(bloodType)}))),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('threshold_update_error'.tr)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${'error'.tr}: $e')),
          );
        }
      }
    }
  }

  // Update toggle setting - Uses structured update API
  Future<void> _updateToggleSetting({
    required InventorySettings settings,
    required String key,
    required bool value,
  }) async {
    try {
      bool success = false;

      switch (key) {
        case 'expirationAlertsEnabled':
          // Use expiration params update
          success = await ref.read(inventorySettingsProvider.notifier).updateExpirationParams(
            enabled: value,
          );
          break;
        case 'criticalStockAlertsEnabled':
          // Use notification update
          success = await ref.read(inventorySettingsProvider.notifier).updateNotifications(
            criticalAlerts: value,
          );
          break;
        case 'dailySummaryEnabled':
          // Use notification update
          success = await ref.read(inventorySettingsProvider.notifier).updateNotifications(
            dailySummary: value,
          );
          break;
        default:
          return;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('setting_updated'.tr)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('update_error'.tr)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error'.tr}: $e')),
        );
      }
    }
  }
  
  // Method to trigger report export
  void _exportReport(String reportType) async {
    // Get current date range
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0); // Last day of current month
    
    // Format dates as strings
    final startDate = '${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-${startOfMonth.day.toString().padLeft(2, '0')}';
    final endDate = '${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}';
    
    // Show initial message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('generating_report'.tr),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );
    
    // Call the export method from the controller
    await ref.read(bloodReportExportControllerProvider.notifier).exportReport(
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
      format: _selectedReportFormat,
    );
    
    // Check the result and show appropriate message
    final exportState = ref.read(bloodReportExportControllerProvider);
    
    if (exportState.error != null) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 16),
              Expanded(child: Text(exportState.error!)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } else if (exportState.filePath != null && exportState.fileName != null) {
      // ✅ Show preview dialog instead of just success message
      _showReportPreviewDialog(
        fileName: exportState.fileName!,
        filePath: exportState.filePath!,
        fileSizeBytes: exportState.fileSizeBytes ?? 0,
        reportType: reportType,
      );
    }
  }
  
  // ✅ New method to show preview dialog
  Future<void> _showReportPreviewDialog({
    required String fileName,
    required String filePath,
    required int fileSizeBytes,
    required String reportType,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReportPreviewDialog(
        fileName: fileName,
        filePath: filePath,
        fileSizeBytes: fileSizeBytes,
        reportType: reportType,
        generatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If entry safety net triggered (empty _allowedTabs), render a minimal
    // scaffold so the post-frame pop can land without layout errors.
    if (_allowedTabs.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tab Navigation
            _buildTabNavigation(),

            // Tab Content — only render the tabs the user is allowed to see.
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _allowedTabs.map((tab) {
                  switch (tab) {
                    case InventoryTab.overview:
                      return _buildOverviewTab();
                    case InventoryTab.bloodStock:
                      return _buildBloodStockTab();
                    case InventoryTab.reports:
                      return _buildReportsTab();
                    case InventoryTab.settings:
                      return _buildSettingsTab();
                  }
                }).toList(),
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
            if (widget.showBackButton) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.arrow_left,
                    color: Colors.grey.shade700,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'inventory_management'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'blood_bank_makila'.tr,
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
    // Build only the tabs the user is allowed to see, in the same order
    // as _allowedTabs so they align with the TabBarView children.
    Tab tabFor(InventoryTab tab) {
      switch (tab) {
        case InventoryTab.overview:
          return Tab(
            icon: const Icon(Iconsax.chart, size: 20),
            text: 'overview'.tr,
          );
        case InventoryTab.bloodStock:
          return Tab(
            icon: const Icon(Iconsax.box, size: 20),
            text: 'blood_stock'.tr,
          );
        case InventoryTab.reports:
          return Tab(
            icon: const Icon(Iconsax.chart_square, size: 20),
            text: 'reports'.tr,
          );
        case InventoryTab.settings:
          return Tab(
            icon: const Icon(Iconsax.setting_2, size: 20),
            text: 'parameters'.tr,
          );
      }
    }

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
          tabs: _allowedTabs.map(tabFor).toList(),
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
            'quick_statistics'.tr,
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
                  title: 'total_stock'.tr,
                  value: totalStock.value.toString(),
                  subtitle: 'units'.tr,
                  icon: Iconsax.box,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'active_requests'.tr,
                  value: pendingRequests.value.toString(),
                  subtitle: 'pending'.tr,
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
                  title: 'critical_stock'.tr,
                  value: criticalStock.value.toString(),
                  subtitle: 'blood_types'.tr,
                  icon: Iconsax.warning_2,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'expiring_soon'.tr,
                  value: expiringStock.value.toString(),
                  subtitle: 'in_7_days'.tr,
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
    final totalStock = ref.watch(totalStockProvider).value;

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
              'blood_type_distribution'.tr,
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
                  'no_stock_available'.tr,
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
                      "$quantity ${'units'.tr}",
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
              'recent_activity'.tr,
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

  // Wraps a centered message so it stays pull-to-refresh-able even when there
  // is nothing scrollable to show (empty or error state). LayoutBuilder +
  // AlwaysScrollableScrollPhysics give the RefreshIndicator a scrollable child
  // that fills the viewport so the swipe-down gesture is always available.
  Widget _buildRefreshableMessage({
    required Future<void> Function() onRefresh,
    required Widget child,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildBloodStockTab() {
    final stockState = ref.watch(bloodStockControllerProvider);

    // Shared pull-to-refresh handler so every state (loading, error, empty,
    // or populated) can be swiped down to re-fetch the stock.
    Future<void> refreshStock() async {
      await ref.read(bloodStockControllerProvider.notifier).loadBloodStock();
    }

    if (stockState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (stockState.error != null) {
      return _buildRefreshableMessage(
        onRefresh: refreshStock,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'loading_error'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stockState.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(bloodStockControllerProvider.notifier).loadBloodStock();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text('retry'.tr),
            ),
          ],
        ),
      );
    }
    
    if (stockState.stocks.isEmpty) {
      return _buildRefreshableMessage(
        onRefresh: refreshStock,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.box,
              color: Colors.grey.shade400,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'no_stock_to_display'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'add_stock_to_start'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Only show the "Add stock" CTA when the user has the sub_menu
            // permission for it.
            if (_canAddStock)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddBloodStockPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text('add_stock'.tr),
              ),
          ],
        ),
      );
    }

    // Group blood stocks by blood type and product type for better display
    final Map<String, List<BloodStock>> groupedStocks = {};
    for (final stock in stockState.stocks) {
      final key = stock.bloodType;
      if (!groupedStocks.containsKey(key)) {
        groupedStocks[key] = [];
      }
      groupedStocks[key]!.add(stock);
    }
    
    return RefreshIndicator(
      onRefresh: refreshStock,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header with search and filter
          _buildStockHeader(),
          const SizedBox(height: 16),
          
          // Blood stock summary cards
          _buildBloodStockSummary(groupedStocks),
          const SizedBox(height: 24),
          
          // Detailed blood stock list by type
          ...groupedStocks.entries.map((entry) => 
            _buildBloodTypeSection(entry.key, entry.value)
          ),
        ],
      ),
    );
  }
  
  Widget _buildStockHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Row(
                children: [
                  Icon(
                    Iconsax.search_normal,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'search_stock'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
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
            child: Icon(
              Iconsax.filter,
              color: Colors.grey.shade700,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBloodStockSummary(Map<String, List<BloodStock>> groupedStocks) {
    // Count stats for summary cards
    int totalUnits = 0;
    int expiringUnits = 0;
    int criticalTypes = 0;
    final DateTime cutoffDate = DateTime.now().add(const Duration(days: 7));
    
    // Calculate total, expiring and critical
    final Map<String, int> typeQuantities = {};
    for (final entry in groupedStocks.entries) {
      int typeTotal = 0;
      int typeExpiring = 0;
      
      for (final stock in entry.value) {
        if (stock.status == BloodBagStatus.available) {
          // Convert volume to units (approx 450ml per unit)
          int units = (stock.volume / 450).ceil();
          typeTotal += units;
          
          if (stock.expirationDate.isBefore(cutoffDate)) {
            typeExpiring += units;
          }
        }
      }
      
      typeQuantities[entry.key] = typeTotal;
      totalUnits += typeTotal;
      expiringUnits += typeExpiring;
      
      // Less than 10 units is considered critical
      if (typeTotal < 10) {
        criticalTypes++;
      }
    }
    
    // Build cards grid
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'stock_summary'.tr,
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
                child: _buildSummaryCard(
                  title: 'total_stock'.tr,
                  value: totalUnits.toString(),
                  subtitle: 'units'.tr,
                  icon: Iconsax.box,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'blood_types'.tr,
                  value: groupedStocks.length.toString(),
                  subtitle: 'available'.tr,
                  icon: Iconsax.document,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'critical_types'.tr,
                  value: criticalTypes.toString(),
                  subtitle: 'less_than_10_units'.tr,
                  icon: Iconsax.warning_2,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'expiring_soon'.tr,
                  value: expiringUnits.toString(),
                  subtitle: 'less_than_7_days'.tr,
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
  
  Widget _buildSummaryCard({
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
  
  Widget _buildBloodTypeSection(String bloodType, List<BloodStock> stocks) {
    // Group stocks by product type
    final Map<String, List<BloodStock>> productGroups = {};
    for (final stock in stocks) {
      final key = stock.productType.value;
      if (!productGroups.containsKey(key)) {
        productGroups[key] = [];
      }
      productGroups[key]!.add(stock);
    }
    
    // Calculate total volume and units for this blood type
    int totalUnits = 0;
    for (final stock in stocks) {
      if (stock.status == BloodBagStatus.available) {
        totalUnits += (stock.volume / 450).ceil();
      }
    }
    
    // Determine stock level color
    Color stockColor = Colors.green;
    if (totalUnits < 10) {
      stockColor = Colors.red;
    } else if (totalUnits < 20) {
      stockColor = Colors.orange;
    }
    
    return FadeInUp(
      delay: Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Blood Type Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        bloodType,
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: stockColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'blood_group'.trParams({'type': BloodTranslations.getBloodTypeName(bloodType)}),
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'units_available'.trParams({'count': totalUnits.toString()}),
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      totalUnits < 10 ? 'critical'.tr : (totalUnits < 20 ? 'low'.tr : 'normal'.tr),
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Product Types List
            ...productGroups.entries.map((entry) {
              // Count available units for this product type
              int productUnits = 0;
              for (final stock in entry.value) {
                if (stock.status == BloodBagStatus.available) {
                  productUnits += (stock.volume / 450).ceil();
                }
              }
              
              // Get display name for this product type
              final productType = entry.value.first.productType;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product type summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.box,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            productType.displayName,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "$productUnits ${'units'.tr}",
                            style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Detailed items list - only shown if expanded
                  AnimatedCrossFade(
                    firstChild: const SizedBox(height: 0),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(left: 40, right: 16, bottom: 8),
                      child: Column(
                        children: entry.value.map((stock) => 
                          _buildBloodStockItemCard(stock)
                        ).toList(),
                      ),
                    ),
                    crossFadeState: _expandedBloodTypes.contains(bloodType)
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              );
            }),
            
            // View Details Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    if (_expandedBloodTypes.contains(bloodType)) {
                      _expandedBloodTypes.remove(bloodType);
                    } else {
                      _expandedBloodTypes.add(bloodType);
                      
                      // Scroll to the expanded section after a short delay to allow animation
                      Future.delayed(const Duration(milliseconds: 100), () {
                        // This would require a ScrollController to implement
                        // For now, we'll just let the user scroll manually
                      });
                    }
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expandedBloodTypes.contains(bloodType) ? 'hide_details'.tr : 'view_details'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expandedBloodTypes.contains(bloodType) ? Iconsax.arrow_down_1 : Iconsax.arrow_right_3,
                      color: ColorPages.COLOR_PRINCIPAL,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Class-level flags to prevent multiple API calls
  bool _reportsDataLoaded = false;
  bool _settingsDataLoaded = false;

  Widget _buildReportsTab() {
    // Get current date
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    
    // Load data for reports on tab initialization only once
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only load data if not already loaded
      if (!_reportsDataLoaded) {
        _reportsDataLoaded = true;
        
        // Load key metrics
        ref.read(bloodReportsMetricsControllerProvider.notifier).loadMetrics();
        
        // Load trends data with default period 'month'
        ref.read(bloodReportsTrendsControllerProvider.notifier).loadTrends(period: 'month');
        
        // Load monthly comparison data
        ref.read(bloodReportsMonthlyComparisonControllerProvider.notifier).loadMonthlyComparison(
          compareMonth: lastMonth.month, 
          compareYear: lastMonth.year
        );
        
        // Initialize the export provider
        ref.read(bloodReportExportControllerProvider);
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        // Reset the flag to allow reloading data
        setState(() {
          _reportsDataLoaded = false;
        });
        
        // Load key metrics
        await ref.read(bloodReportsMetricsControllerProvider.notifier).loadMetrics();
        
        // Load trends data with default period 'month'
        await ref.read(bloodReportsTrendsControllerProvider.notifier).loadTrends(period: 'month');
        
        // Get current date for monthly comparison
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        
        // Load monthly comparison data
        await ref.read(bloodReportsMonthlyComparisonControllerProvider.notifier).loadMonthlyComparison(
          compareMonth: lastMonth.month, 
          compareYear: lastMonth.year
        );
        
        // Set flag back to true as data is loaded
        setState(() {
          _reportsDataLoaded = true;
        });
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reports header with filters
            _buildReportsHeader(),
            const SizedBox(height: 24),

            // Key metrics cards
            _buildKeyMetricsSection(),
            const SizedBox(height: 24),
            
            // Inventory trend chart
            _buildInventoryTrendSection(),
            const SizedBox(height: 24),
            
            // Monthly comparison
            _buildMonthlyComparisonSection(lastMonth, thisMonth),
            const SizedBox(height: 24),
            
            // Export reports section
            _buildExportReportsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    final settingsState = ref.watch(inventorySettingsProvider);
    final settings = settingsState.settings;

    // Load settings data on tab initialization only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only load data if not already loaded
      if (!_settingsDataLoaded) {
        _settingsDataLoaded = true;

        // Load settings from backend
        ref.read(inventorySettingsProvider.notifier).loadSettings();
      }
    });

    // Show loading indicator
    if (settingsState.isLoading && settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error message
    if (settingsState.error != null && settings == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'loading_error'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                settingsState.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Reset the flag to allow reloading data
                setState(() {
                  _settingsDataLoaded = false;
                });

                // Retry loading settings
                ref.read(inventorySettingsProvider.notifier).refreshSettings();
              },
              icon: const Icon(Iconsax.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Show message if no settings available
    if (settings == null) {
      return Center(
        child: Text(
          'unable_to_load_settings'.tr,
          style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    // Build settings UI with pull-to-refresh
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: RefreshIndicator(
        onRefresh: () async {
          // Reset the flag to allow reloading data
          setState(() {
            _settingsDataLoaded = false;
          });

          // Refresh settings from backend
          await ref.read(inventorySettingsProvider.notifier).refreshSettings();

          // Set flag back to true as data is loaded
          setState(() {
            _settingsDataLoaded = true;
          });
        },
        color: ColorPages.COLOR_PRINCIPAL,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings header with last updated info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'inventory_settings'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      if (settingsState.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'configure_stock_management'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (settingsState.lastUpdated != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'last_updated'.trParams({'time': _formatLastUpdated(settingsState.lastUpdated!)}),
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

                // Pricing settings
                _buildSettingsSection(
                  title: 'blood_product_pricing'.tr,
                  icon: Iconsax.money,
                  color: Colors.green,
                  children: settings.productPrices.entries.map((entry) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      BloodTranslations.getBloodComponentName(entry.key),
                      style: GoogleFonts.ubuntu(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${entry.value} ${settings.currency} / ${'unit'.tr}',
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Iconsax.edit,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    onTap: () {
                      _editPriceDialog(entry.key, entry.value);
                    },
                  )).toList(),
                ),
            // ),
            const SizedBox(height: 20),

                // Stock threshold settings
                _buildSettingsSection(
                  title: 'critical_stock_thresholds'.tr,
                  icon: Iconsax.warning_2,
                  color: Colors.orange,
                  children: [
                    ...settings.criticalThresholds.entries.map((entry) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              BloodTranslations.getBloodTypeName(entry.key),
                              style: GoogleFonts.ubuntu(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'critical_threshold'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${entry.value} ${'units'.tr}',
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Iconsax.edit,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      onTap: () {
                        _editThresholdDialog(entry.key, entry.value);
                      },
                    )),
                    Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to detailed threshold configuration
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('detailed_threshold_config_coming'.tr)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.shade300),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Text(
                      'configure_all_blood_types'.tr,
                      style: GoogleFonts.ubuntu(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Expiration settings
            _buildSettingsSection(
              title: 'expiration_settings'.tr,
              icon: Iconsax.calendar,
              color: Colors.red,
              children: [
                _buildToggleSetting(
                  title: 'expiration_alerts'.tr,
                  subtitle: 'expiration_alerts_description'.tr,
                  value: _expirationAlertsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _expirationAlertsEnabled = value;
                    });
                    // Save setting
                    _saveSetting('expirationAlerts', value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(value ? 'expiration_alerts_enabled'.tr : 'expiration_alerts_disabled'.tr)),
                    );
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.timer,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  title: Text(
                    'Alerte anticipée',
                    style: GoogleFonts.ubuntu(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  subtitle: Text(
                    'Jours avant expiration pour déclencher l\'alerte',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'seven_days'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Iconsax.edit,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Modification de l\'alerte anticipée à venir')),
                    );
                  },
                ),
                _buildSettingsItemWithValue(
                  title: 'validity_period'.tr,
                  subtitle: 'configure_validity_by_product'.tr,
                  value: 'configuration'.tr,
                  icon: Iconsax.setting,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('validity_duration_config_coming'.tr)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Alert settings
            _buildSettingsSection(
              title: 'notification_settings'.tr,
              icon: Iconsax.notification,
              color: Colors.blue,
              children: [
                _buildToggleSetting(
                  title: 'critical_stock_alerts'.tr,
                  subtitle: 'critical_stock_alerts_description'.tr,
                  value: _criticalStockAlertsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _criticalStockAlertsEnabled = value;
                    });
                    // Save setting
                    _saveSetting('criticalStockAlerts', value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(value ? 'critical_stock_alerts_enabled'.tr : 'critical_stock_alerts_disabled'.tr)),
                    );
                  },
                ),
                _buildToggleSetting(
                  title: 'daily_notifications'.tr,
                  subtitle: 'daily_summary_description'.tr,
                  value: _dailySummaryEnabled,
                  onChanged: (value) {
                    setState(() {
                      _dailySummaryEnabled = value;
                    });
                    // Save setting
                    _saveSetting('dailySummary', value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(value ? 'daily_notifications_enabled'.tr : 'daily_notifications_disabled'.tr)),
                    );
                  },
                ),
                _buildSettingsItem(
                  title: 'notification_channels'.tr,
                  subtitle: 'configure_notification_channels'.tr,
                  icon: Iconsax.sms,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('notification_channels_config_coming'.tr)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Notes on settings location
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.info_circle, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'note'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'general_settings_note'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ], // End Column children
        ), // End Column
      ), // End SingleChildScrollView
      ), // End RefreshIndicator
    ); // End FadeInUp return
  } // End _buildSettingsTab

  Widget? _buildFloatingActionButton() {
    switch (_currentTab) {
      case InventoryTab.bloodStock:
        // Hide the FAB entirely when the user does not have access
        // to the Add Stock sub_menu.
        if (!_canAddStock) return null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Bulk Excel import (download template + upload). Same permission
            // gate as adding a single bag.
            FloatingActionButton.small(
              heroTag: 'inventory_bulk_import_fab',
              tooltip: 'bulk_import_title'.tr,
              backgroundColor: Colors.white,
              foregroundColor: ColorPages.COLOR_PRINCIPAL,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BulkImportBloodStockPage(),
                  ),
                );
              },
              child: const Icon(Iconsax.document_upload),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'inventory_add_stock_fab',
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
                'add_stock'.tr,
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      default:
        return null;
    }
  }



  // Build a card for an individual blood stock item
  Widget _buildBloodStockItemCard(BloodStock stock) {
    // Convert volume to units (approx 450ml per unit)
    final int units = (stock.volume / 450).ceil();
    
    // Get color based on status
    Color statusColor = Colors.green;
    if (stock.status == BloodBagStatus.expired) {
      statusColor = Colors.red;
    } else if (stock.status != BloodBagStatus.available) {
      statusColor = Colors.orange;
    }
    
    // Calculate days until expiration
    final int daysUntilExpiration = stock.expirationDate.difference(DateTime.now()).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "${units} ${'units'.tr} - ${stock.productType.displayName}",
                style: GoogleFonts.ubuntu(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: daysUntilExpiration <= 7 ? Colors.red.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${'exp'.tr}: ${daysUntilExpiration <= 0 ? 'expired'.tr : 'J-$daysUntilExpiration'}",
                style: GoogleFonts.ubuntu(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: daysUntilExpiration <= 7 ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'quality_volume'.trParams({'quality': stock.bagCondition.displayName, 'volume': stock.volume.toStringAsFixed(1)}),
          style: GoogleFonts.ubuntu(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        children: [
          // Additional details
          _buildDetailRow('id'.tr, stock.id.substring(0, min(8, stock.id.length)) + '...'),
          _buildDetailRow('collection_date'.tr, _formatDate(stock.collectionDate)),
          _buildDetailRow('expiration_date'.tr, _formatDate(stock.expirationDate)),
          if (stock.batchNumber.isNotEmpty) _buildDetailRow('batch_number'.tr, stock.batchNumber),
          if (stock.description != null && stock.description!.isNotEmpty) 
            _buildDetailRow('description'.tr, stock.description!),
        ],
      ),
    );
  }
  
  // Helper for building detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to format dates
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Reports Tab UI Components
  Widget _buildReportsHeader() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'inventory_reports'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'inventory_analysis'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Time period selector
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.calendar,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'last_30_days'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Iconsax.arrow_down_1,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
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
                child: Icon(
                  Iconsax.filter,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    // Get metrics from provider state
    final metricsState = ref.watch(bloodReportsMetricsControllerProvider);
    
    // Extract values or use defaults, handling the nested structure
    final totalCollected = metricsState.metrics['total_collected'] is Map 
        ? ((metricsState.metrics['total_collected'] as Map)['value'] as num?)?.toInt() ?? 0 
        : (metricsState.metrics['total_collected'] as num?)?.toInt() ?? 0;
    
    final totalDistributed = metricsState.metrics['total_distributed'] is Map 
        ? ((metricsState.metrics['total_distributed'] as Map)['value'] as num?)?.toInt() ?? 0 
        : (metricsState.metrics['total_distributed'] as num?)?.toInt() ?? 0;
    
    final averageDailyCollection = metricsState.metrics['avg_daily_collection'] is Map 
        ? (metricsState.metrics['avg_daily_collection'] as Map)['value'] as num? ?? 0 
        : metricsState.metrics['avg_daily_collection'] as num? ?? 0;
    
    final donationsIncreasePercent = metricsState.metrics['donations_increase'] is Map 
        ? ((metricsState.metrics['donations_increase'] as Map)['value'] as num?)?.toInt() ?? 0 
        : (metricsState.metrics['donation_trend'] as num?)?.toInt() ?? 0;
    
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with loading indicator
          Row(
            children: [
              Text(
                'key_metrics'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              if (metricsState.isLoading)
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (metricsState.error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'data_loading_error'.trParams({'error': metricsState.error ?? ''}),
                style: TextStyle(color: Colors.red.shade700),
              ),
            )
          else
            Column(
              children: [
                // Metrics cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'blood_collected'.tr,
                        value: '$totalCollected',
                        subtitle: 'units_this_month'.tr,
                        icon: Iconsax.add_circle,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'blood_distributed'.tr,
                        value: '$totalDistributed',
                        subtitle: 'units_this_month'.tr,
                        icon: Iconsax.export_1,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'daily_average'.tr,
                        value: '${averageDailyCollection.toStringAsFixed(1)}',
                        subtitle: 'units_per_day'.tr,
                        icon: Iconsax.calendar_1,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'evolution'.tr,
                        value: donationsIncreasePercent >= 0 ? '+$donationsIncreasePercent%' : '$donationsIncreasePercent%',
                        subtitle: 'vs_last_month'.tr,
                        icon: donationsIncreasePercent >= 0 ? Iconsax.trend_up : Iconsax.trend_down,
                        color: donationsIncreasePercent >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
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

  Widget _buildInventoryTrendSection() {
    final trendsState = ref.watch(bloodReportsTrendsControllerProvider);
    
    // Log the response for debugging
    print('📊 Inventory trend data: ${trendsState.trends}');
    
    // Check for the new API data structure first
    List<Map<String, dynamic>> dataPoints = [];
    
    // Extract trend data points from state (new API structure)
    if (trendsState.trends.containsKey('data_points')) {
      dataPoints = List<Map<String, dynamic>>.from(trendsState.trends['data_points'] ?? []);
      print('📈 Found ${dataPoints.length} data points in the trend data');
    }
    
    // Legacy structure handling
    List<Map<String, dynamic>> collectionData = [];
    List<Map<String, dynamic>> distributionData = [];
    
    if (trendsState.trends.containsKey('collection_trend')) {
      collectionData = List<Map<String, dynamic>>.from(trendsState.trends['collection_trend'] ?? []);
    }
    
    if (trendsState.trends.containsKey('distribution_trend')) {
      distributionData = List<Map<String, dynamic>>.from(trendsState.trends['distribution_trend'] ?? []);
    }
    
    // Determine if we have data from either structure
    bool hasDataPoints = dataPoints.isNotEmpty;
    bool hasLegacyData = collectionData.isNotEmpty || distributionData.isNotEmpty;
    bool hasData = hasDataPoints || hasLegacyData;
    
    // Extract collection and distribution values from the new data structure for the chart painter
    List<num> collectedValues = [];
    List<num> distributedValues = [];
    List<String> dateLabels = [];
    
    if (hasDataPoints) {
      for (var point in dataPoints) {
        collectedValues.add(point['collected'] as num);
        distributedValues.add(point['distributed'] as num);
        dateLabels.add(point['date'] as String);
      }
    }
    
    // List of available period options for filter
    final List<String> periodOptions = ['week', 'month', 'quarter', 'year'];
    // Currently selected period (default to month)
    final selectedPeriod = trendsState.trends['period'] ?? 'month';
    
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
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
            // Chart header with period filter
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'inventory_trend'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Loading indicator
                          if (trendsState.isLoading)
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorPages.COLOR_PRINCIPAL,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'blood_units_per_period'.trParams({'period': BloodTranslations.getPeriodLabel(selectedPeriod)}),
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Period filter dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedPeriod,
                    underline: const SizedBox(),
                    isDense: true,
                    items: periodOptions.map((period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(BloodTranslations.getPeriodLabel(period)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(bloodReportsTrendsControllerProvider.notifier)
                          .loadTrends(period: value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('collected'.tr, ColorPages.COLOR_PRINCIPAL),
                const SizedBox(width: 12),
                _buildLegendItem('distributed'.tr, Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            
            if (trendsState.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'data_loading_error'.trParams({'error': trendsState.error ?? ''}),
                  style: TextStyle(color: Colors.red.shade700),
                ),
              )
            else if (!hasData && trendsState.isLoading == false)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'no_trend_data_period'.tr,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              // Chart with real data when available
              SizedBox(
                height: 200,
                child: hasData ? _buildRealDataChart(collectedValues, distributedValues, dateLabels) : _buildMockChart(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMockChart() {
    // This is a placeholder for a real chart
    // In a real app, use fl_chart, syncfusion_flutter_charts or another chart library
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 200),
        painter: _ChartPainter(),
      ),
    );
  }
  
  Widget _buildRealDataChart(List<num> collectedValues, List<num> distributedValues, List<String> dateLabels) {
    // Import and use our new chart painter
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 200),
        painter: RealDataChartPainter(
          collectedValues: collectedValues,
          distributedValues: distributedValues,
          dateLabels: dateLabels,
        ),
      ),
    );
  }
  
  Widget _buildMonthlyComparisonSection(DateTime lastMonth, DateTime thisMonth) {
    // Get comparison data from provider state
    final comparisonState = ref.watch(bloodReportsMonthlyComparisonControllerProvider);
    
    // Log the response for debugging
    print('📊 Monthly comparison data: ${comparisonState.comparison}');

    // Format month names as fallback
    final lastMonthName = BloodTranslations.getMonthName(lastMonth.month);
    final thisMonthName = BloodTranslations.getMonthName(thisMonth.month);
    
    // Extract month names from API data with the new structure if available
    String apiLastMonthName;
    String apiThisMonthName;
    
    if (comparisonState.comparison.containsKey('compare_month') && 
        comparisonState.comparison['compare_month'] is Map &&
        comparisonState.comparison['compare_month'].containsKey('name')) {
      // New API structure
      apiLastMonthName = comparisonState.comparison['compare_month']['name'] as String? ?? lastMonthName;
      apiThisMonthName = comparisonState.comparison['current_month']['name'] as String? ?? thisMonthName;
    } else {
      // Legacy structure
      apiLastMonthName = comparisonState.comparison['prev_month_name'] as String? ?? lastMonthName;
      apiThisMonthName = comparisonState.comparison['current_month_name'] as String? ?? thisMonthName;
    }
    
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
            Row(
              children: [
                Text(
                  'monthly_comparison'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                if (comparisonState.isLoading)
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (comparisonState.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'data_loading_error'.trParams({'error': comparisonState.error ?? ''}),
                  style: TextStyle(color: Colors.red.shade700),
                ),
              )
            else
              // Blood type comparison
              ..._buildBloodTypeComparisonRows(apiLastMonthName, apiThisMonthName, comparisonState.comparison),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBloodTypeComparisonRows(String lastMonth, String thisMonth, Map<String, dynamic> comparisonData) {
    // Get blood type comparisons from API data or use default empty list
    List<Map<String, dynamic>> comparisons = [];
    
    // Check the new API structure first (from the backend response)
    if (comparisonData.containsKey('comparison_data') && comparisonData['comparison_data'] != null) {
      // Map the backend structure to our expected format
      comparisons = List<Map<String, dynamic>>.from(
        (comparisonData['comparison_data'] as List).map((item) => {
          'type': item['blood_type'],
          'lastMonth': item['previous_month'],
          'thisMonth': item['current_month'],
          'change': item['percent_change'],
        })
      );
    } 
    // Fallback to legacy structure if available
    else if (comparisonData.containsKey('blood_types') && comparisonData['blood_types'] != null) {
      comparisons = List<Map<String, dynamic>>.from(comparisonData['blood_types'] ?? []);
    }
    
    // If no comparison data available, use sample data for UI preview
    if (comparisons.isEmpty) {
      comparisons = [
        {
          'type': 'A+',
          'lastMonth': 48,
          'thisMonth': 62,
          'change': 29.2,
        },
        {
          'type': 'O+',
          'lastMonth': 76,
          'thisMonth': 83,
          'change': 9.2,
        },
        {
          'type': 'B+',
          'lastMonth': 35,
          'thisMonth': 31,
          'change': -11.4,
        },
        {
          'type': 'AB+',
          'lastMonth': 12,
          'thisMonth': 18,
          'change': 50.0,
        },
      ];
    }
    
    final List<Widget> rows = [
      // Header row
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                'type'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                lastMonth,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                thisMonth,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                'evolution'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Divider
      Divider(color: Colors.grey.shade200),
    ];
    
    // Add data rows
    for (final item in comparisons) {
      // Handle all the possible cases for 'change' value
      final dynamic rawChange = item['change'];
      final double change;
      
      if (rawChange is Map && rawChange.containsKey('value')) {
        // Case 1: It's a Map with 'value' property
        change = (rawChange['value'] as num?)?.toDouble() ?? 0.0;
      } else if (rawChange is num) {
        // Case 2: It's already a number
        change = rawChange.toDouble();
      } else if (rawChange is String) {
        // Case 3: It's a string that needs to be parsed
        change = double.tryParse(rawChange) ?? 0.0;
      } else {
        // Default case: assume it's 0
        change = 0.0;
      }
      
      final isPositive = change >= 0;
      
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Blood type
              SizedBox(
                width: 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (item['type'] as String).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ),
              ),
              
              // Last month value
              Expanded(
                child: Text(
                  _formatComparisonValue(item['lastMonth']),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              
              // This month value
              Expanded(
                child: Text(
                  _formatComparisonValue(item['thisMonth']),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              // Change percentage
              SizedBox(
                width: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPositive ? Iconsax.arrow_up : Iconsax.arrow_down,
                        size: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${change.abs().toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return rows;
  }

  // This method has been moved to its proper location and is defined elsewhere in the file

  Widget _buildExportReportsSection() {
    // Get export state from provider
    final exportState = ref.watch(bloodReportExportControllerProvider);
    
    final exportOptions = [
      {
        'title': 'inventory_report'.tr,
        'subtitle': 'current_stock_status'.tr,
        'icon': Iconsax.document_1,
        'color': Colors.blue,
        'reportType': 'inventory_summary',
      },
      {
        'title': 'transaction_report'.tr,
        'subtitle': 'stock_entries_exits'.tr,
        'icon': Iconsax.repeat,
        'color': ColorPages.COLOR_PRINCIPAL,
        'reportType': 'distribution_stats',
      },
      {
        'title': 'expiration_report'.tr,
        'subtitle': 'expiring_stock'.tr,
        'icon': Iconsax.calendar,
        'color': Colors.amber,
        'reportType': 'expiration_analysis',
      },
    ];
    
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'export_reports'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                
                // Format selector - PDF or Excel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${'format'.tr}:",
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<String>(
                        value: _selectedReportFormat,
                        underline: const SizedBox(),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                          DropdownMenuItem(value: 'excel', child: Text('Excel')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedReportFormat = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Description
            Text(
              'Générez et téléchargez des rapports détaillés sur votre inventaire de banque de sang',
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Show error if exists
            if (exportState.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      color: Colors.red.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exportState.error!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
             
            // Export options list
            ...exportOptions.map((option) => _buildExportOption(
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              icon: option['icon'] as IconData,
              color: option['color'] as Color,
              reportType: option['reportType'] as String,
              isLoading: exportState.isExporting && 
                         exportState.currentReportType == option['reportType'],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String reportType,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
          isLoading
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            )
          : TextButton(
              onPressed: () => _exportReport(reportType),
              style: TextButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.export_1,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'export'.tr,
                    style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format comparison values that might be in different formats
  String _formatComparisonValue(dynamic value) {
    if (value == null) {
      return '0';
    } else if (value is Map && value.containsKey('value')) {
      return '${value['value']}';
    } else if (value is num) {
      return '$value';
    } else if (value is String && value.isNotEmpty) {
      return value;
    } else {
      return '0';
    }
  }

  Map<String, dynamic> _getStockLevel(int quantity) {
    if (quantity >= 30) {
      return {'level': 'normal'.tr, 'color': Colors.green};
    } else if (quantity >= 15) {
      return {'level': 'low'.tr, 'color': Colors.orange};
    } else {
      return {'level': 'critical'.tr, 'color': Colors.red};
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

// Chart painter for mock inventory trend chart
class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Mock data for the chart
    final collectionData = [42, 38, 45, 40, 43, 48, 52, 55, 50, 47, 53, 58, 60, 55];
    final distributionData = [35, 30, 32, 36, 39, 42, 38, 44, 48, 45, 42, 40, 44, 46];
    
    // Calculate scaling factors
    final maxValue = 70.0; // Max value for the chart
    final xStep = width / (collectionData.length - 1);
    final yScale = height / maxValue;
    
    // Draw axes
    final axesPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    
    // Draw X axis
    canvas.drawLine(
      Offset(0, height),
      Offset(width, height),
      axesPaint,
    );
    
    // Draw dashed horizontal lines for Y-axis reference
    final dashPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 4; i++) {
      final y = height - (i * height / 4);
      drawDashedLine(canvas, Offset(0, y), Offset(width, y), dashPaint);
    }
    
    // Draw collection line (primary color)
    final collectionPaint = Paint()
      ..color = ColorPages.COLOR_PRINCIPAL
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final collectionPath = Path();
    for (int i = 0; i < collectionData.length; i++) {
      final x = i * xStep;
      final y = height - (collectionData[i] * yScale);
      
      if (i == 0) {
        collectionPath.moveTo(x, y);
      } else {
        collectionPath.lineTo(x, y);
      }
    }
    canvas.drawPath(collectionPath, collectionPaint);
    
    // Draw distribution line (orange)
    final distributionPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final distributionPath = Path();
    for (int i = 0; i < distributionData.length; i++) {
      final x = i * xStep;
      final y = height - (distributionData[i] * yScale);
      
      if (i == 0) {
        distributionPath.moveTo(x, y);
      } else {
        distributionPath.lineTo(x, y);
      }
    }
    canvas.drawPath(distributionPath, distributionPaint);
    
    // Draw data points on collection line
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final pointStrokePaint = Paint()
      ..color = ColorPages.COLOR_PRINCIPAL
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (int i = 0; i < collectionData.length; i++) {
      final x = i * xStep;
      final y = height - (collectionData[i] * yScale);
      
      // Only draw points for every second data point to avoid clutter
      if (i % 2 == 0) {
        canvas.drawCircle(Offset(x, y), 4, pointStrokePaint);
        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }
    
    // Draw data points on distribution line
    final distPointStrokePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (int i = 0; i < distributionData.length; i++) {
      final x = i * xStep;
      final y = height - (distributionData[i] * yScale);
      
      // Only draw points for every second data point to avoid clutter
      if (i % 2 == 0) {
        canvas.drawCircle(Offset(x, y), 4, distPointStrokePaint);
        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }
  }

  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dashWidth = 5;
    final dashSpace = 5;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final count = sqrt(dx * dx + dy * dy) / (dashWidth + dashSpace);
    final x = dx / count;
    final y = dy / count;
    
    Offset p = start;
    for (int i = 0; i < count; i++) {
      canvas.drawLine(p, Offset(p.dx + x * dashWidth / (dashWidth + dashSpace), p.dy + y * dashWidth / (dashWidth + dashSpace)), paint);
      p = Offset(p.dx + x, p.dy + y);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper methods for settings tab

// Removed unused threshold setting method

// Build a settings item with value display
Widget _buildSettingsItemWithValue({
  required String title,
  required String subtitle,
  required String value,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: Colors.grey.shade700,
        size: 20,
      ),
    ),
    title: Text(
      title,
      style: GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: GoogleFonts.ubuntu(
        fontSize: 13,
        color: Colors.grey.shade600,
      ),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Iconsax.arrow_right_3,
          size: 16,
          color: Colors.grey.shade400,
        ),
      ],
    ),
    onTap: onTap,
  );
}

Widget _buildSettingsSection({
  required String title,
  required IconData icon,
  required Color color,
  required List<Widget> children,
}) {
  return Container(
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
        // Section header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        
        // Divider
        Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
        
        // Section children
        ...children,
      ],
    ),
  );
}

Widget _buildSettingsItem({
  required String title,
  required String subtitle,
  required IconData icon,
  Color? iconColor,
  Widget? trailing,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (iconColor ?? Colors.grey.shade700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: iconColor ?? Colors.grey.shade700,
        size: 20,
      ),
    ),
    title: Text(
      title,
      style: GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: GoogleFonts.ubuntu(
        fontSize: 13,
        color: Colors.grey.shade600,
      ),
    ),
    trailing: trailing ?? Icon(
      Iconsax.arrow_right_3,
      color: Colors.grey.shade400,
      size: 16,
    ),
    onTap: onTap,
  );
}

Widget _buildToggleSetting({
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    title: Text(
      title,
      style: GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: GoogleFonts.ubuntu(
        fontSize: 13,
        color: Colors.grey.shade600,
      ),
    ),
    value: value,
    activeColor: ColorPages.COLOR_PRINCIPAL,
    onChanged: onChanged,
  );
}


