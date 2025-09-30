import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/system_country.dart';
import '../services/location_service.dart';

class CascadingLocationDropdown extends StatefulWidget {
  final Function(SystemCountry?) onCountryChanged;
  final Function(SystemProvince?) onProvinceChanged;
  final Function(SystemTown?) onTownChanged;
  final String? initialCountryId;
  final String? initialProvinceId;
  final String? initialTownId;
  final String countryLabel;
  final String provinceLabel;
  final String townLabel;
  final bool isRequired;

  const CascadingLocationDropdown({
    Key? key,
    required this.onCountryChanged,
    required this.onProvinceChanged,
    required this.onTownChanged,
    this.initialCountryId,
    this.initialProvinceId,
    this.initialTownId,
    this.countryLabel = 'Country',
    this.provinceLabel = 'Province',
    this.townLabel = 'Town',
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<CascadingLocationDropdown> createState() => _CascadingLocationDropdownState();
}

class _CascadingLocationDropdownState extends State<CascadingLocationDropdown> {
  final LocationService _locationService = LocationService();
  
  // Controllers for the reactive state
  final _countriesController = RxList<SystemCountry>([]);
  final _provincesController = RxList<SystemProvince>([]);
  final _townsController = RxList<SystemTown>([]);
  
  // Selected values
  final Rx<SystemCountry?> _selectedCountry = Rx<SystemCountry?>(null);
  final Rx<SystemProvince?> _selectedProvince = Rx<SystemProvince?>(null);
  final Rx<SystemTown?> _selectedTown = Rx<SystemTown?>(null);
  
  // Loading states
  final _isLoadingCountries = false.obs;
  final _isLoadingProvinces = false.obs;
  final _isLoadingTowns = false.obs;
  
  // Error states
  final _countryError = Rx<String?>(null);
  final _provinceError = Rx<String?>(null);
  final _townError = Rx<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  // Load countries from the API
  Future<void> _loadCountries() async {
    try {
      _isLoadingCountries.value = true;
      _countryError.value = null;
      
      final countries = await _locationService.getCountries();
      
      if (countries.isEmpty) {
        _countryError.value = 'Failed to load countries. Please try again.';
      } else {
        _countriesController.value = countries;
        
        // Set initial country if provided
        if (widget.initialCountryId != null) {
          _selectedCountry.value = countries.firstWhere(
            (country) => country.id == widget.initialCountryId,
            orElse: () => countries.first,
          );
          _loadProvinces(_selectedCountry.value!.id);
        }
      }
    } catch (e) {
      _countryError.value = 'Error loading countries: ${e.toString()}';
    } finally {
      _isLoadingCountries.value = false;
    }
  }

  // Load provinces for a specific country
  Future<void> _loadProvinces(String countryId) async {
    try {
      _isLoadingProvinces.value = true;
      _provinceError.value = null;
      _selectedProvince.value = null;
      _selectedTown.value = null;
      _townsController.value = [];
      
      final provinces = await _locationService.getProvincesByCountry(countryId);
      
      if (provinces.isEmpty) {
        _provinceError.value = 'No provinces available for the selected country.';
      } else {
        _provincesController.value = provinces;
        
        // Set initial province if provided
        if (widget.initialProvinceId != null) {
          _selectedProvince.value = provinces.firstWhere(
            (province) => province.id == widget.initialProvinceId,
            orElse: () => provinces.first,
          );
          _loadTowns(_selectedProvince.value!.id);
        }
      }
    } catch (e) {
      _provinceError.value = 'Error loading provinces: ${e.toString()}';
    } finally {
      _isLoadingProvinces.value = false;
    }
  }

  // Load towns for a specific province
  Future<void> _loadTowns(String provinceId) async {
    try {
      _isLoadingTowns.value = true;
      _townError.value = null;
      _selectedTown.value = null;
      
      final towns = await _locationService.getTownsByProvince(provinceId);
      
      if (towns.isEmpty) {
        _townError.value = 'No towns available for the selected province.';
      } else {
        _townsController.value = towns;
        
        // Set initial town if provided
        if (widget.initialTownId != null) {
          _selectedTown.value = towns.firstWhere(
            (town) => town.id == widget.initialTownId,
            orElse: () => towns.first,
          );
          widget.onTownChanged(_selectedTown.value);
        }
      }
    } catch (e) {
      _townError.value = 'Error loading towns: ${e.toString()}';
    } finally {
      _isLoadingTowns.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country Dropdown
        _buildCountryDropdown(),
        const SizedBox(height: 16),
        
        // Province Dropdown (visible only when country is selected)
        Obx(() => _selectedCountry.value != null
            ? _buildProvinceDropdown()
            : const SizedBox.shrink()),
        Obx(() => _selectedCountry.value != null
            ? const SizedBox(height: 16)
            : const SizedBox.shrink()),
        
        // Town Dropdown (visible only when province is selected)
        Obx(() => _selectedProvince.value != null
            ? _buildTownDropdown()
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.countryLabel + (widget.isRequired ? ' *' : ''),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _isLoadingCountries.value
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<SystemCountry>(
                      isExpanded: true,
                      value: _selectedCountry.value,
                      hint: const Text('Select Country'),
                      items: _countriesController.map((SystemCountry country) {
                        return DropdownMenuItem<SystemCountry>(
                          value: country,
                          child: Text(country.name),
                        );
                      }).toList(),
                      onChanged: (SystemCountry? newValue) {
                        _selectedCountry.value = newValue;
                        widget.onCountryChanged(newValue);
                        if (newValue != null) {
                          _loadProvinces(newValue.id);
                        } else {
                          _provincesController.value = [];
                          _townsController.value = [];
                          _selectedProvince.value = null;
                          _selectedTown.value = null;
                          widget.onProvinceChanged(null);
                          widget.onTownChanged(null);
                        }
                      },
                    ),
                  ),
          ),
          if (_countryError.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _countryError.value!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildProvinceDropdown() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.provinceLabel + (widget.isRequired ? ' *' : ''),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _isLoadingProvinces.value
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<SystemProvince>(
                      isExpanded: true,
                      value: _selectedProvince.value,
                      hint: const Text('Select Province'),
                      items: _provincesController.map((SystemProvince province) {
                        return DropdownMenuItem<SystemProvince>(
                          value: province,
                          child: Text(province.name),
                        );
                      }).toList(),
                      onChanged: (SystemProvince? newValue) {
                        _selectedProvince.value = newValue;
                        widget.onProvinceChanged(newValue);
                        if (newValue != null) {
                          _loadTowns(newValue.id);
                        } else {
                          _townsController.value = [];
                          _selectedTown.value = null;
                          widget.onTownChanged(null);
                        }
                      },
                    ),
                  ),
          ),
          if (_provinceError.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _provinceError.value!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildTownDropdown() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.townLabel + (widget.isRequired ? ' *' : ''),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _isLoadingTowns.value
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<SystemTown>(
                      isExpanded: true,
                      value: _selectedTown.value,
                      hint: const Text('Select Town'),
                      items: _townsController.map((SystemTown town) {
                        return DropdownMenuItem<SystemTown>(
                          value: town,
                          child: Text(town.name),
                        );
                      }).toList(),
                      onChanged: (SystemTown? newValue) {
                        _selectedTown.value = newValue;
                        widget.onTownChanged(newValue);
                      },
                    ),
                  ),
          ),
          if (_townError.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _townError.value!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      );
    });
  }
}