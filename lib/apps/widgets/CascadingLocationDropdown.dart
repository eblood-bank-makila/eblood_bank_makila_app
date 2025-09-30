import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/SystemCountry.dart';

class CascadingLocationDropdown extends StatefulWidget {
  final String label;
  final String? hint;
  final Function(Map<String, String>) onLocationSelected;
  final String? Function(String?)? validator;
  final List<SystemCountry> locations;
  final bool isLoading;
  final String? errorMessage;
  final IconData? prefixIcon;

  const CascadingLocationDropdown({
    super.key,
    required this.label,
    this.hint,
    required this.onLocationSelected,
    this.validator,
    required this.locations,
    this.isLoading = false,
    this.errorMessage,
    this.prefixIcon,
  });

  @override
  State<CascadingLocationDropdown> createState() => _CascadingLocationDropdownState();
}

class _CascadingLocationDropdownState extends State<CascadingLocationDropdown> {
  // Selected values at each level
  String? _selectedCountryId;
  String? _selectedProvinceId;
  String? _selectedTownId;

  // Options at each level
  List<SystemCountry> _countries = [];
  List<SystemCountry> _provinces = [];
  List<SystemCountry> _towns = [];

  // Names of selected items
  String? _selectedCountryName;
  String? _selectedProvinceName;
  String? _selectedTownName; // Used in _onTownChanged to notify parent

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _countries = widget.locations;
  }

  @override
  void didUpdateWidget(CascadingLocationDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      setState(() {
        _countries = widget.locations;
      });
    }
  }

  void _onCountryChanged(String? countryId) {
    if (countryId == null) return;
    
    final selectedCountry = _countries.firstWhere((country) => country.id == countryId);
    
    setState(() {
      _selectedCountryId = countryId;
      _selectedCountryName = selectedCountry.name;
      _selectedProvinceId = null;
      _selectedTownId = null;
      _selectedProvinceName = null;
      _selectedTownName = null;
      _provinces = selectedCountry.children;
      _towns = [];
    });

    // Notify parent
    widget.onLocationSelected({
      'country_id': countryId,
      'country_name': selectedCountry.name,
    });
  }

  void _onProvinceChanged(String? provinceId) {
    if (provinceId == null) return;
    
    final selectedProvince = _provinces.firstWhere((province) => province.id == provinceId);
    
    setState(() {
      _selectedProvinceId = provinceId;
      _selectedProvinceName = selectedProvince.name;
      _selectedTownId = null;
      _selectedTownName = null;
      _towns = selectedProvince.children;
    });

    // Notify parent
    widget.onLocationSelected({
      'country_id': _selectedCountryId!,
      'country_name': _selectedCountryName!,
      'province_id': provinceId,
      'province_name': selectedProvince.name,
    });
  }

  void _onTownChanged(String? townId) {
    if (townId == null) return;
    
    final selectedTown = _towns.firstWhere((town) => town.id == townId);
    
    setState(() {
      _selectedTownId = townId;
      _selectedTownName = selectedTown.name;
    });

    // Notify parent with complete location data
    widget.onLocationSelected({
      'country_id': _selectedCountryId!,
      'country_name': _selectedCountryName!,
      'province_id': _selectedProvinceId!,
      'province_name': _selectedProvinceName!,
      'town_id': townId,
      'town_name': selectedTown.name,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        
        if (widget.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (widget.errorMessage != null)
          Text(
            widget.errorMessage!,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.red,
            ),
          )
        else
          Column(
            children: [
              // Country dropdown
              _buildDropdown(
                value: _selectedCountryId,
                items: _countries
                    .map((country) => DropdownMenuItem(
                          value: country.id,
                          child: Text(country.name),
                        ))
                    .toList(),
                hint: 'Select Country',
                onChanged: _onCountryChanged,
              ),
              
              if (_provinces.isNotEmpty) 
                Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedProvinceId,
                      items: _provinces
                          .map((province) => DropdownMenuItem(
                                value: province.id,
                                child: Text(province.name),
                              ))
                          .toList(),
                      hint: 'Select Province',
                      onChanged: _onProvinceChanged,
                    ),
                  ],
                ),
              
              if (_towns.isNotEmpty) 
                Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedTownId,
                      items: _towns
                          .map((town) => DropdownMenuItem(
                                value: town.id,
                                child: Text(town.name),
                              ))
                          .toList(),
                      hint: 'Select Town',
                      onChanged: _onTownChanged,
                      validator: widget.validator,
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        style: GoogleFonts.ubuntu(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.ubuntu(
            fontSize: 16,
            color: Colors.grey[400],
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? Theme.of(context).primaryColor : Colors.grey[400],
                  size: 20,
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorStyle: GoogleFonts.ubuntu(
            fontSize: 12,
            color: Colors.red,
          ),
        ),
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey[400],
        ),
        isExpanded: true,
      ),
    );
  }
}