/// City Selection Page
/// Allows users to select their city for blood search using tree structure (Country → Province → City)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/search_flow_provider.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../apps/models/SystemCountry.dart';
import '../../../apps/services/LocationService.dart';
import '../widgets/search_flow_app_bar.dart';
import '../widgets/search_flow_progress_indicator.dart';

/// Tree level enum
enum LocationLevel { country, province, city }

class CitySelectionPage extends ConsumerStatefulWidget {
  const CitySelectionPage({super.key});

  @override
  ConsumerState<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends ConsumerState<CitySelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  // Location data
  List<SystemCountry> _countries = [];
  List<SystemCountry> _currentItems = [];
  List<SystemCountry> _filteredItems = [];
  
  // Selection state
  LocationLevel _currentLevel = LocationLevel.country;
  SystemCountry? _selectedCountry;
  SystemCountry? _selectedProvince;
  
  // Previous city state
  bool _showPreviousCity = false;
  SelectedCity? _previousCity;
  
  // UI state
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkForPreviousCity();
    _loadLocationData();
  }

  /// Check if there's a previously selected city
  void _checkForPreviousCity() {
    final state = ref.read(searchFlowProvider);
    if (state.selectedCity != null) {
      _previousCity = state.selectedCity;
      _showPreviousCity = true;
      print('🏙️ Found previous city: ${_previousCity?.name}');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _locationService.fetchLocationData();
      setState(() {
        _countries = response.data;
        _currentItems = _countries;
        _filteredItems = _countries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load locations: $e';
        _isLoading = false;
      });
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _currentItems;
      } else {
        _filteredItems = _currentItems
            .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectItem(SystemCountry item) {
    switch (_currentLevel) {
      case LocationLevel.country:
        setState(() {
          _selectedCountry = item;
          if (item.children.isNotEmpty) {
            _currentLevel = LocationLevel.province;
            _currentItems = item.children;
            _filteredItems = item.children;
            _searchController.clear();
          } else {
            // Country has no children, select it directly as city
            _selectAsCity(item);
          }
        });
        break;
        
      case LocationLevel.province:
        setState(() {
          _selectedProvince = item;
          if (item.children.isNotEmpty) {
            _currentLevel = LocationLevel.city;
            _currentItems = item.children;
            _filteredItems = item.children;
            _searchController.clear();
          } else {
            // Province has no children, select it directly as city
            _selectAsCity(item);
          }
        });
        break;
        
      case LocationLevel.city:
        _selectAsCity(item);
        break;
    }
  }

  void _selectAsCity(SystemCountry item) async {
    final city = SelectedCity(
      id: item.id,
      name: item.name,
      regionId: _selectedProvince?.id,
      regionName: _selectedProvince?.name,
      countryId: _selectedCountry?.id,
      countryName: _selectedCountry?.name,
      path: _buildPath(item.name),
    );
    
    await ref.read(searchFlowProvider.notifier).selectCity(city);
    context.push('/blood-search/blood-type');
  }

  String _buildPath(String cityName) {
    final parts = <String>[];
    if (_selectedCountry != null) parts.add(_selectedCountry!.name);
    if (_selectedProvince != null) parts.add(_selectedProvince!.name);
    parts.add(cityName);
    return parts.join(' > ');
  }

  void _goBack() {
    switch (_currentLevel) {
      case LocationLevel.country:
        context.pop();
        break;
        
      case LocationLevel.province:
        setState(() {
          _currentLevel = LocationLevel.country;
          _selectedCountry = null;
          _currentItems = _countries;
          _filteredItems = _countries;
          _searchController.clear();
        });
        break;
        
      case LocationLevel.city:
        setState(() {
          _currentLevel = LocationLevel.province;
          _selectedProvince = null;
          _currentItems = _selectedCountry?.children ?? [];
          _filteredItems = _selectedCountry?.children ?? [];
          _searchController.clear();
        });
        break;
    }
  }

  String get _currentTitle {
    switch (_currentLevel) {
      case LocationLevel.country:
        return 'select_country'.tr.isEmpty ? 'Select Country' : 'select_country'.tr;
      case LocationLevel.province:
        return 'select_province'.tr.isEmpty ? 'Select Province' : 'select_province'.tr;
      case LocationLevel.city:
        return 'select_city'.tr.isEmpty ? 'Select City' : 'select_city'.tr;
    }
  }

  String get _searchHint {
    switch (_currentLevel) {
      case LocationLevel.country:
        return 'search_country'.tr.isEmpty ? 'Search country...' : 'search_country'.tr;
      case LocationLevel.province:
        return 'search_province'.tr.isEmpty ? 'Search province...' : 'search_province'.tr;
      case LocationLevel.city:
        return 'search_city'.tr.isEmpty ? 'Search city...' : 'search_city'.tr;
    }
  }

  IconData get _currentIcon {
    switch (_currentLevel) {
      case LocationLevel.country:
        return Iconsax.global;
      case LocationLevel.province:
        return Iconsax.map;
      case LocationLevel.city:
        return Iconsax.building;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchFlowProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: _showPreviousCity 
            ? ('your_previous_city'.tr.isEmpty ? 'Your Previous City' : 'your_previous_city'.tr)
            : _currentTitle,
        onBack: () {
          if (_showPreviousCity) {
            context.pop();
          } else {
            _goBack();
          }
        },
      ),
      body: _showPreviousCity ? _buildPreviousCityView() : _buildLocationSelectionView(state),
    );
  }

  Widget _buildPreviousCityView() {
    return Column(
      children: [
        // Progress indicator
        SearchFlowProgressIndicator(
          currentStep: 1,
          totalSteps: 4,
          stepLabels: [
            'step_city'.tr,
            'step_blood_type'.tr,
            'step_results'.tr,
            'step_confirm'.tr,
          ],
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.location,
                      size: 48,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Center(
                  child: Text(
                    'your_previous_city'.tr.isEmpty 
                        ? 'Your Previous City' 
                        : 'your_previous_city'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'continue_with_previous'.tr.isEmpty
                        ? 'Continue with your previously selected city'
                        : 'continue_with_previous'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Previous city card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.building,
                          color: ColorPages.COLOR_PRINCIPAL,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _previousCity?.name ?? '',
                              style: GoogleFonts.ubuntu(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            if (_previousCity?.path != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _previousCity!.path!,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.tick_circle5,
                        color: Colors.green.shade600,
                        size: 32,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Select other cities button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showPreviousCity = false;
                      });
                    },
                    icon: Icon(Iconsax.location, size: 20),
                    label: Text(
                      'select_other_cities'.tr.isEmpty
                          ? 'Select Other Cities'
                          : 'select_other_cities'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPages.COLOR_PRINCIPAL,
                      side: BorderSide(
                        color: ColorPages.COLOR_PRINCIPAL,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom navigation
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Use the previous city and navigate to blood type
                      context.push('/blood-search/blood-type');
                    },
                    icon: Icon(Iconsax.arrow_right_3, size: 20),
                    label: Text(
                      'next'.tr.isEmpty ? 'Next' : 'next'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPages.COLOR_PRINCIPAL,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelectionView(SearchFlowState state) {
    return Column(
      children: [
        // Progress indicator
        SearchFlowProgressIndicator(
          currentStep: 1,
          totalSteps: 4,
          stepLabels: [
            'step_city'.tr,
            'step_blood_type'.tr,
            'step_results'.tr,
            'step_confirm'.tr,
          ],
        ),

        // Breadcrumb navigation
        if (_selectedCountry != null || _selectedProvince != null)
          _buildBreadcrumb(),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: _searchHint,
                hintStyle: GoogleFonts.ubuntu(color: Colors.grey.shade500),
                prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey.shade500),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.ubuntu(fontSize: 16),
            ),
          ),
        ),

        // Items list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorState()
                  : _filteredItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = state.selectedCity?.id == item.id;
                            return _LocationListItem(
                              item: item,
                              icon: _currentIcon,
                              isSelected: isSelected,
                              hasChildren: item.children.isNotEmpty,
                              onTap: () => _selectItem(item),
                            );
                          },
                        ),
        ),

        // Quick access - Use Current Location
        if (_currentLevel == LocationLevel.country)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Iconsax.location, size: 20),
                  label: Text(
                    'use_current_location'.tr.isEmpty 
                        ? 'Use Current Location' 
                        : 'use_current_location'.tr,
                    style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPages.COLOR_PRINCIPAL,
                    side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.location,
            size: 16,
            color: ColorPages.COLOR_PRINCIPAL,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedCountry != null) ...[
                    _buildBreadcrumbItem(
                      _selectedCountry!.name, 
                      onTap: () {
                        setState(() {
                          _currentLevel = LocationLevel.province;
                          _selectedProvince = null;
                          _currentItems = _selectedCountry!.children;
                          _filteredItems = _selectedCountry!.children;
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                  if (_selectedProvince != null) ...[
                    Icon(Iconsax.arrow_right_3, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    _buildBreadcrumbItem(
                      _selectedProvince!.name,
                      onTap: () {
                        setState(() {
                          _currentLevel = LocationLevel.city;
                          _currentItems = _selectedProvince!.children;
                          _filteredItems = _selectedProvince!.children;
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ColorPages.COLOR_PRINCIPAL,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.location_slash,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'no_locations_found'.tr.isEmpty ? 'No locations found' : 'no_locations_found'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'try_different_search'.tr.isEmpty 
                ? 'Try a different search term' 
                : 'try_different_search'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'error_loading_locations'.tr.isEmpty 
                ? 'Error loading locations' 
                : 'error_loading_locations'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadLocationData,
            icon: const Icon(Iconsax.refresh),
            label: Text('retry'.tr.isEmpty ? 'Retry' : 'retry'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _useCurrentLocation() {
    // TODO: Implement location detection with GPS
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'location_detection_coming_soon'.tr.isEmpty 
              ? 'Location detection coming soon' 
              : 'location_detection_coming_soon'.tr,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LocationListItem extends StatelessWidget {
  final SystemCountry item;
  final IconData icon;
  final bool isSelected;
  final bool hasChildren;
  final VoidCallback onTap;

  const _LocationListItem({
    required this.item,
    required this.icon,
    required this.isSelected,
    required this.hasChildren,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? ColorPages.COLOR_PRINCIPAL.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected 
                ? ColorPages.COLOR_PRINCIPAL 
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade600,
            size: 22,
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade800,
          ),
        ),
        subtitle: hasChildren
            ? Text(
                '${item.children.length} ${'sub_locations'.tr.isEmpty ? 'sub-locations' : 'sub_locations'.tr}',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              )
            : null,
        trailing: isSelected
            ? Icon(
                Iconsax.tick_circle5,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 24,
              )
            : Icon(
                hasChildren ? Iconsax.arrow_right_3 : Iconsax.add_circle,
                color: Colors.grey.shade400,
                size: 20,
              ),
      ),
    );
  }
}
