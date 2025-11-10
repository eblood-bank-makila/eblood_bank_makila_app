import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../apps/config/theme/ColorPages.dart';
import '../../business/providers/HealthStructureProvider.dart';
import '../../data/models/HealthStructureModel.dart';
import 'HealthStructureDetailPage.dart';

class HealthStructureNetworkPage extends ConsumerStatefulWidget {
  final bool showBackButton;

  const HealthStructureNetworkPage({
    super.key,
    this.showBackButton = true,
  });

  @override
  ConsumerState<HealthStructureNetworkPage> createState() => _HealthStructureNetworkPageState();
}

class _HealthStructureNetworkPageState extends ConsumerState<HealthStructureNetworkPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Define tab structure based on health structure types
  final List<Map<String, dynamic>> _tabs = [
    {
      'label': 'all',
      'icon': Iconsax.buildings,
      'type': null, // null means all types
    },
    {
      'label': 'general_hospital',
      'icon': Iconsax.hospital,
      'type': EHealthStructureType.generalHospital,
    },
    {
      'label': 'clinic',
      'icon': Iconsax.building_3,
      'type': EHealthStructureType.clinic,
    },
    {
      'label': 'blood_bank',
      'icon': Iconsax.health,
      'type': EHealthStructureType.bloodBank,
    },
    {
      'label': 'health_center',
      'icon': Iconsax.building,
      'type': EHealthStructureType.healthCenter,
    },
  ];

  // Mock data for health structures (kept for fallback)
  final List<Map<String, dynamic>> _healthStructures = [];

  List<Map<String, dynamic>> _filteredStructures = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _filteredStructures = List.from(_healthStructures);

    // Add listener to tab controller to fetch data when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged();
      }
    });

    // Fetch initial data (all structures)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _onTabChanged() {
    final selectedTab = _tabs[_tabController.index];
    final EHealthStructureType? typeFilter = selectedTab['type'];
    _fetchData(typeFilter: typeFilter);
  }

  void _fetchData({EHealthStructureType? typeFilter}) {
    if (typeFilter == null) {
      // Fetch all health structures
      ref.read(healthStructureProvider.notifier).fetchAllHealthStructures(
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
    } else {
      // Fetch by specific type
      ref.read(healthStructureProvider.notifier).fetchHealthStructuresByType(
        typeFilter: typeFilter,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterStructures(String query) {
    // Trigger API search with the current tab filter
    final selectedTab = _tabs[_tabController.index];
    final EHealthStructureType? typeFilter = selectedTab['type'];
    _fetchData(typeFilter: typeFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              // Custom AppBar with transparent background
              AppBar(
                automaticallyImplyLeading: widget.showBackButton,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      style: GoogleFonts.ubuntu(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'search_structure_hint'.tr,
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.ubuntu(color: Colors.grey),
                      ),
                      onChanged: _filterStructures,
                      autofocus: true,
                    )
                  : Text(
                      'health_structures_network'.tr,
                      style: GoogleFonts.ubuntu(
                        fontWeight: FontWeight.w600,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                actions: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search, color: ColorPages.COLOR_PRINCIPAL),
                    onPressed: () {
                      setState(() {
                        if (_isSearching) {
                          _searchController.clear();
                          _filterStructures('');
                        }
                        _isSearching = !_isSearching;
                      });
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      // Handle filter or sort options
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'sortByName',
                        child: Text('sort_by_name'.tr),
                      ),
                      PopupMenuItem(
                        value: 'sortByDate',
                        child: Text('sort_by_date'.tr),
                      ),
                      PopupMenuItem(
                        value: 'filterActive',
                        child: Text('filter_active'.tr),
                      ),
                    ],
                  ),
                ],
              ),
              // TabBar with transparent background
              Container(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: _tabs.map((tab) => Tab(
                    icon: Icon(tab['icon'] as IconData),
                    text: (tab['label'] as String).tr,
                  )).toList(),
                  labelStyle: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.ubuntu(
                    fontSize: 12,
                  ),
                  indicatorColor: ColorPages.COLOR_PRINCIPAL,
                  labelColor: ColorPages.COLOR_PRINCIPAL,
                  unselectedLabelColor: Colors.black,
                ),
              ),
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    // All tabs use the same builder with real data from provider
                    return _buildHealthStructuresTab(tab['type'] as EHealthStructureType?);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Unified tab builder that fetches real data from provider
  Widget _buildHealthStructuresTab(EHealthStructureType? typeFilter) {
    final healthStructureState = ref.watch(healthStructureProvider);

    // Show loading state
    if (healthStructureState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ColorPages.COLOR_PRINCIPAL),
            const SizedBox(height: 16),
            Text(
              'loading_structures'.tr,
              style: GoogleFonts.ubuntu(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (healthStructureState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(
              'error'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                healthStructureState.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.ubuntu(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchData(typeFilter: typeFilter),
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (healthStructureState.healthStructures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.building, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'no_structures_found'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              typeFilter != null
                ? 'no_structures_of_type'.trParams({'type': typeFilter.label})
                : 'no_health_structures_available'.tr,
              style: GoogleFonts.ubuntu(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchData(typeFilter: typeFilter),
              icon: const Icon(Icons.refresh),
              label: Text('refresh'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Show list of health structures
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData(typeFilter: typeFilter);
      },
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: healthStructureState.healthStructures.length,
        itemBuilder: (context, index) {
          final structure = healthStructureState.healthStructures[index];
          return _buildStructureCardFromModel(structure);
        },
      ),
    );
  }

  Widget _buildAllStructuresTab() {
    if (_filteredStructures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.building,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune structure trouvée',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'autres termes de recherche',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Simulate data refresh
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          // Refresh filtered structures with the current filter
          _filterStructures(_searchController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('data_updated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      color: Colors.red,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStructures.length,
        itemBuilder: (context, index) {
          final structure = _filteredStructures[index];
          return _buildStructureCard(structure);
        },
      ),
    );
  }

  Widget _buildHospitalsTab() {
    final hospitals = _filteredStructures.where((s) => s['type'] == 'hospital').toList();

    if (hospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.hospital,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun hôpital trouvé',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'autres termes de recherche',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Simulate data refresh
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          // Refresh filtered structures with the current filter
          _filterStructures(_searchController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('data_updated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      color: Colors.red,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hospitals.length,
        itemBuilder: (context, index) {
          final structure = hospitals[index];
          return _buildStructureCard(structure);
        },
      ),
    );
  }

  Widget _buildMapTab() {
    // For the map view, we wrap the content in a SingleChildScrollView with RefreshIndicator
    // since the map view doesn't have a ListView
    return RefreshIndicator(
      onRefresh: () async {
        // Simulate data refresh
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          // Update map data if needed
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('data_updated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      color: Colors.red,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.map_1,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'structures_map'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'feature_coming_soon'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPages.COLOR_PRINCIPAL,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('feature_coming_soon'.tr),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: Text(
                      'view_on_map'.tr,
                      style: GoogleFonts.ubuntu(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build card from HealthStructureModel (real data) - Enhanced Modern Design
  Widget _buildStructureCardFromModel(HealthStructureModel structure) {
    IconData typeIcon;
    String typeText;
    Color statusColor;
    String statusText;
    Color typeColor;

    // Set icon, text, and color based on structure type
    switch (structure.healthStructureTypeFlag) {
      case EHealthStructureType.generalHospital:
      case EHealthStructureType.universityHospital:
        typeIcon = Iconsax.hospital;
        typeText = 'general_hospital'.tr;
        typeColor = const Color(0xFF2196F3);
        break;
      case EHealthStructureType.clinic:
        typeIcon = Iconsax.building_3;
        typeText = 'clinic'.tr;
        typeColor = const Color(0xFF9C27B0);
        break;
      case EHealthStructureType.bloodBank:
        typeIcon = Iconsax.health;
        typeText = 'blood_bank'.tr;
        typeColor = ColorPages.COLOR_PRINCIPAL;
        break;
      case EHealthStructureType.healthCenter:
      case EHealthStructureType.healthCareCenter:
        typeIcon = Iconsax.building;
        typeText = 'health_center'.tr;
        typeColor = const Color(0xFF4CAF50);
        break;
      case EHealthStructureType.pharmacy:
        typeIcon = Iconsax.health;
        typeText = 'pharmacy'.tr;
        typeColor = const Color(0xFFFF9800);
        break;
      case EHealthStructureType.emergencyCenter:
        typeIcon = Iconsax.warning_2;
        typeText = 'emergency_center'.tr;
        typeColor = const Color(0xFFF44336);
        break;
      default:
        typeIcon = Iconsax.building_4;
        typeText = structure.healthStructureTypeFlag.label;
        typeColor = Colors.grey;
    }

    // Set status color and text
    if (structure.isActivated) {
      statusColor = const Color(0xFF4CAF50);
      statusText = 'active'.tr;
    } else {
      statusColor = Colors.grey.shade400;
      statusText = 'inactive'.tr;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.4),
          width: 0.4,
        ),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HealthStructureDetailPage(structure: structure),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon, name, and status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type icon with gradient background
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            typeColor.withValues(alpha: 0.2),
                            typeColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            structure.name,
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeText,
                              style: GoogleFonts.ubuntu(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: GoogleFonts.ubuntu(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Contact information section
                if (structure.address != null ||
                    structure.phoneNumber != null ||
                    structure.email != null)
                  Column(
                    children: [
                      if (structure.address != null) ...[
                        _buildContactRow(
                          icon: Iconsax.location,
                          label: structure.address!,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (structure.phoneNumber != null) ...[
                        _buildContactRow(
                          icon: Iconsax.call,
                          label: structure.phoneNumber!,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (structure.email != null)
                        _buildContactRow(
                          icon: Iconsax.sms,
                          label: structure.email!,
                          color: Colors.grey.shade600,
                        ),
                    ],
                  ),
                // Badges section
                if (structure.isVerified || structure.hasEmergencyServices)
                  Column(
                    children: [
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (structure.isVerified)
                            _buildBadge(
                              icon: Iconsax.verify,
                              label: 'verified'.tr,
                              backgroundColor: Colors.blue.shade50,
                              textColor: Colors.blue.shade700,
                              iconColor: Colors.blue.shade700,
                            ),
                          if (structure.hasEmergencyServices)
                            _buildBadge(
                              icon: Iconsax.warning_2,
                              label: 'emergency_24_7'.tr,
                              backgroundColor: Colors.orange.shade50,
                              textColor: Colors.orange.shade700,
                              iconColor: Colors.orange.shade700,
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

  // Helper widget for contact rows
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper widget for badges
  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureCard(Map<String, dynamic> structure) {
    IconData typeIcon;
    String typeText;
    Color statusColor;
    String statusText;

    // Set icon and text based on structure type
    switch (structure['type']) {
      case 'hospital':
        typeIcon = Iconsax.hospital;
        typeText = 'general_hospital'.tr;
        break;
      case 'clinic':
        typeIcon = Iconsax.building_3;
        typeText = 'clinic'.tr;
        break;
      case 'medicalCenter':
        typeIcon = Iconsax.building;
        typeText = 'health_center'.tr;
        break;
      case 'healthCenter':
        typeIcon = Iconsax.house;
        typeText = 'health_center'.tr;
        break;
      default:
        typeIcon = Iconsax.building_4;
        typeText = 'other'.tr;
    }

    // Set status color and text
    switch (structure['status']) {
      case 'active':
        statusColor = Colors.green;
        statusText = 'active'.tr;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'pending'.tr;
        break;
      case 'inactive':
        statusColor = Colors.grey;
        statusText = 'inactive'.tr;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'undefined'.tr;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showStructureDetailsDialog(structure);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      typeIcon,
                      color: ColorPages.COLOR_PRINCIPAL,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          structure['name'],
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          typeText,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Iconsax.location,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      structure['location'],
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (structure['bloodNeeds'] != null && (structure['bloodNeeds'] as List).isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (structure['bloodNeeds'] as List).map<Widget>((bloodType) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bloodType,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${'partnership_date'.tr}: ${structure['partnershipDate']}",
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Iconsax.box,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'deliveries_count'.trParams({'count': "${structure['totalDeliveries']}"}),
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStructureDetailsDialogFromModel(HealthStructureModel structure) {
    String typeText = structure.healthStructureTypeFlag.label;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          structure.name,
                          style: GoogleFonts.ubuntu(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    typeText,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: ColorPages.COLOR_PRINCIPAL,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailItem(
                    icon: Iconsax.code_circle,
                    label: 'identifier'.tr,
                    value: structure.identifier,
                  ),
                  if (structure.address != null)
                    _buildDetailItem(
                      icon: Iconsax.location,
                      label: 'address'.tr,
                      value: structure.address!,
                    ),
                  if (structure.phoneNumber != null)
                    _buildDetailItem(
                      icon: Iconsax.call,
                      label: 'phone'.tr,
                      value: structure.phoneNumber!,
                    ),
                  if (structure.email != null)
                    _buildDetailItem(
                      icon: Iconsax.sms,
                      label: 'email'.tr,
                      value: structure.email!,
                    ),
                  _buildDetailItem(
                    icon: Iconsax.status,
                    label: 'status'.tr,
                    value: structure.isActivated ? 'active'.tr : 'inactive'.tr,
                  ),
                  if (structure.isVerified)
                    _buildDetailItem(
                      icon: Iconsax.verify,
                      label: 'verification'.tr,
                      value: "${'verified'.tr} ✓",
                    ),
                  if (structure.hasEmergencyServices)
                    _buildDetailItem(
                      icon: Iconsax.warning_2,
                      label: 'emergency_services'.tr,
                      value: 'available'.tr,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('close'.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStructureDetailsDialog(Map<String, dynamic> structure) {
    String typeText;

    // Get structure type text
    switch (structure['type']) {
      case 'hospital':
        typeText = 'Hôpital';
        break;
      case 'clinic':
        typeText = 'Clinique';
        break;
      case 'medicalCenter':
        typeText = 'Centre Médical';
        break;
      case 'healthCenter':
        typeText = 'Centre de Santé';
        break;
      default:
        typeText = 'Autre';
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.hospital,
                            color: ColorPages.COLOR_PRINCIPAL,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                structure['name'],
                                style: GoogleFonts.ubuntu(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                typeText,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailItem(
                          icon: Iconsax.location,
                          label: 'Adresse',
                          value: structure['address'],
                        ),
                        _buildDetailItem(
                          icon: Iconsax.call,
                          label: 'Téléphone',
                          value: structure['contactNumber'],
                        ),
                        _buildDetailItem(
                          icon: Iconsax.message,
                          label: 'Email',
                          value: structure['email'],
                        ),
                        _buildDetailItem(
                          icon: Iconsax.calendar,
                          label: 'Date de partenariat',
                          value: structure['partnershipDate'],
                        ),
                        _buildDetailItem(
                          icon: Iconsax.box,
                          label: 'Dernière livraison',
                          value: structure['lastDelivery'],
                        ),

                        const SizedBox(height: 16),

                        // Blood needs section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Besoins en sang',
                              style: GoogleFonts.ubuntu(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (structure['bloodNeeds'] != null && (structure['bloodNeeds'] as List).isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (structure['bloodNeeds'] as List).map<Widget>((bloodType) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      bloodType,
                                      style: GoogleFonts.ubuntu(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              Text(
                                'Aucun besoin spécifique enregistré',
                                style: GoogleFonts.ubuntu(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.edit,
                              label: 'Modifier',
                              color: Colors.blue,
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditHealthStructureDialog(structure);
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.send,
                              label: 'Livraison',
                              color: ColorPages.COLOR_PRINCIPAL,
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeliveryDialog(structure);
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.delete,
                              label: 'Supprimer',
                              color: Colors.red,
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteConfirmationDialog(structure);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ColorPages.COLOR_PRINCIPAL,
                        side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'close'.tr,
                        style: GoogleFonts.ubuntu(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
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
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditHealthStructureDialog(Map<String, dynamic> structure) {
    final nameController = TextEditingController(text: structure['name']);
    final addressController = TextEditingController(text: structure['address']);
    final phoneController = TextEditingController(text: structure['contactNumber']);
    final emailController = TextEditingController(text: structure['email']);
    String selectedType = structure['type'];
    String selectedStatus = structure['status'];
    List<String> selectedBloodNeeds = List<String>.from(structure['bloodNeeds'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Modifier la Structure de Santé',
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de la structure',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Type de structure',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedType,
                          items: [
                            DropdownMenuItem(value: 'hospital', child: Text('Hôpital')),
                            DropdownMenuItem(value: 'clinic', child: Text('Clinique')),
                            DropdownMenuItem(value: 'medicalCenter', child: Text('Centre Médical')),
                            DropdownMenuItem(value: 'healthCenter', child: Text('Centre de Santé')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de téléphone',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedStatus,
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Actif')),
                            DropdownMenuItem(value: 'pending', child: Text('En attente')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactif')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedStatus = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Besoins en sang',
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBloodTypeChip('A+', selectedBloodNeeds, setState),
                            _buildBloodTypeChip('A-', selectedBloodNeeds, setState),
                            _buildBloodTypeChip('B+', selectedBloodNeeds, setState),
                            _buildBloodTypeChip('B-', selectedBloodNeeds, setState),
                            _buildBloodTypeChip('AB+', selectedBloodNeeds, setState),
                            _buildBloodTypeChip('AB-', selectedBloodNeeds, setState),
                            _buildBloodTypeChip('O+', selectedBloodNeeds, setState),
                            _buildBloodTypeChip('O-', selectedBloodNeeds, setState),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.ubuntu(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () {
                                if (nameController.text.isNotEmpty &&
                                    addressController.text.isNotEmpty &&
                                    phoneController.text.isNotEmpty) {

                                  // Here we would typically update the structure in a database
                                  // For now, just close the dialog and show success message
                                  Navigator.pop(context);

                                  // Update in the local list
                                  setState(() {
                                    final index = _healthStructures.indexWhere((s) => s['id'] == structure['id']);
                                    if (index >= 0) {
                                      _healthStructures[index] = {
                                        ..._healthStructures[index],
                                        'name': nameController.text,
                                        'type': selectedType,
                                        'address': addressController.text,
                                        'contactNumber': phoneController.text,
                                        'email': emailController.text,
                                        'status': selectedStatus,
                                        'bloodNeeds': selectedBloodNeeds,
                                      };

                                      _filteredStructures = List.from(_healthStructures);
                                    }
                                  });

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Structure de santé mise à jour avec succès'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  // Show error for missing fields
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Veuillez remplir tous les champs obligatoires'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'Mettre à jour',
                                style: GoogleFonts.ubuntu(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> structure) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Supprimer la structure',
            style: GoogleFonts.ubuntu(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${structure['name']}" ? Cette action est irréversible.',
            style: GoogleFonts.ubuntu(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Annuler',
                style: GoogleFonts.ubuntu(),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Here we would typically delete the structure from a database
                // For now, just close the dialog and show success message
                Navigator.pop(context);

                // Update the list
                setState(() {
                  _healthStructures.removeWhere((s) => s['id'] == structure['id']);
                  _filteredStructures = List.from(_healthStructures);
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Structure supprimée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                'Supprimer',
                style: GoogleFonts.ubuntu(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeliveryDialog(Map<String, dynamic> structure) {
    final quantityController = TextEditingController(text: '1');
    String selectedBloodType = 'A+';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Nouvelle Livraison',
            style: GoogleFonts.ubuntu(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enregistrer une livraison pour ${structure['name']}',
                style: GoogleFonts.ubuntu(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Groupe Sanguin',
                  border: OutlineInputBorder(),
                ),
                value: selectedBloodType,
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedBloodType = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité (unités)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Annuler',
                style: GoogleFonts.ubuntu(),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Here we would typically record the delivery in a database
                // For now, just close the dialog and show success message
                Navigator.pop(context);

                // Update structure data
                setState(() {
                  final index = _healthStructures.indexWhere((s) => s['id'] == structure['id']);
                  if (index >= 0) {
                    final quantity = int.tryParse(quantityController.text) ?? 1;
                    final deliveries = (_healthStructures[index]['totalDeliveries'] as int) + quantity;

                    _healthStructures[index] = {
                      ..._healthStructures[index],
                      'lastDelivery': '10/10/2025',
                      'totalDeliveries': deliveries,
                    };

                    _filteredStructures = List.from(_healthStructures);
                  }
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Livraison de ${quantityController.text} unités de sang $selectedBloodType enregistrée',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                'Enregistrer',
                style: GoogleFonts.ubuntu(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBloodTypeChip(String bloodType, List<String> selected, StateSetter setState) {
    final isSelected = selected.contains(bloodType);

    return FilterChip(
      selected: isSelected,
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.red.shade100,
      checkmarkColor: Colors.red,
      label: Text(bloodType),
      onSelected: (value) {
        setState(() {
          if (value) {
            if (!selected.contains(bloodType)) {
              selected.add(bloodType);
            }
          } else {
            selected.remove(bloodType);
          }
        });
      },
    );
  }
}