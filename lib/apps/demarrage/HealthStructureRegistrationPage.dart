import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ionicons/ionicons.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/network/network_manager.dart';
import '../../core/widgets/network_status_widget.dart';
import '../config/theme/ColorPages.dart';
// api_constants no longer used directly here (submission deferred until verification)
import 'HealthStructureEmailVerificationPage.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/CustomDropdown.dart';
import '../widgets/CustomButton.dart';
import '../../core/widgets/location_tree_select.dart';
import '../models/SystemCountry.dart';
import '../services/LocationService.dart';
import '../widgets/LanguageAwareText.dart';
import '../services/AuthService.dart';

// Health Structure Type Enum
enum HealthStructureType {
  BLOOD_BANK("blood_bank", "blood_bank", Icons.bloodtype_outlined),
  GENERAL_HOSPITAL("general_hospital", "general_hospital", Icons.local_hospital_outlined),
  CLINIC("clinic", "clinic", Icons.medical_services_outlined),
  PHARMACY("pharmacy", "pharmacy", Icons.local_pharmacy_outlined),
  HEALTH_CENTER("health_center", "health_center", Icons.health_and_safety_outlined),
  MATERNITY("maternity", "maternity", Icons.pregnant_woman_outlined),
  MEDICAL_LAB("medical_lab", "medical_lab", Icons.science_outlined),
  REHABILITATION_CENTER("rehabilitation_center", "rehabilitation_center", Icons.accessible_outlined),
  HEALTH_CARE_CENTER("health_care_center", "health_care_center", Icons.healing_outlined),
  MENTAL_HEALTH_CENTER("mental_health_center", "mental_health_center", Icons.psychology_outlined),
  RETIREMENT_HOME("retirement_home", "retirement_home", Icons.elderly_outlined),
  EMERGENCY_CENTER("emergency_center", "emergency_center", Icons.emergency_outlined),
  UNIVERSITY_HOSPITAL("university_hospital", "university_hospital", Icons.school_outlined),
  PRIVATE_PRACTICE("private_practice", "private_practice", Icons.person_outlined);
  
  final String value;
  final String label;
  final IconData icon;
  
  const HealthStructureType(this.value, this.label, this.icon);
  
  // Helper method to get translated label
  String getTranslatedLabel() {
    // Ensure consistent lowercase format for translation keys
    return label.toLowerCase().tr;
  }
}

class HealthStructureRegistrationPage extends StatefulWidget {
  const HealthStructureRegistrationPage({super.key, this.extra});

  // Expecting same pattern as Hospital/Personal pages: GoRouter extra map
  final Map<String, dynamic>? extra;

  @override
  State<HealthStructureRegistrationPage> createState() => _HealthStructureRegistrationPageState();
}

class _HealthStructureRegistrationPageState extends State<HealthStructureRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Structure Information Controllers
  final _structureNameController = TextEditingController();
  final _structureEmailController = TextEditingController();
  final _structurePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();
  
  // Contact Person Controllers
  final _contactFirstNameController = TextEditingController();
  final _contactLastNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  
  // Admin Account Controllers
  final _adminFirstNameController = TextEditingController();
  final _adminLastNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();
  
  // Location data
  Map<String, dynamic> _selectedLocation = {};
  List<SystemCountry> _locationData = [];
  bool _isLoadingLocations = false;
  String? _locationError;
  final LocationService _locationService = LocationService();
  
  // Phone formatting info for each phone number field
  String? _countryCode;
  List<String> _validPrefixes = [];
  String? _structurePhoneError;
  String? _contactPhoneError;
  String? _adminPhoneError;
  
  // Selected values
  String? _contactGender;
  String? _adminGender;
  
  // Health Structure Type
  HealthStructureType? _selectedHealthStructureType;
  
  // Loading state
  bool _isLoading = false;
  bool _acceptTerms = false;
  bool get _isGoogleMode => widget.extra?['registration_mode'] == 'google';

  // Cached google data from extra (if any)
  Map<String, dynamic>? get _googleData => widget.extra?['google_user'];
  
  // Mock data - in real app, this would come from API
  final List<String> _genders = ['male', 'female'];//other

  @override
  void initState() {
    super.initState();
    _fetchLocationData();
    
    // Debug translations
    print('🌐 Current locale: ${Get.locale}');
    print('🌐 Available translations: ${Get.translations.keys}');
    if (Get.locale != null) {
      final String localeKey = Get.locale!.toString();
      print('🌐 Translations for $localeKey: ${Get.translations[localeKey]?.keys.length} keys');
      // Print all health structure type translations
      for (var type in HealthStructureType.values) {
        final key = type.label.toLowerCase();
        final translation = key.tr;
        print('🌐 $key -> $translation');
      }
    }
    
    // Initialize NetworkManager without initial check since we're already fetching data
    NetworkManager().initialize(skipInitialCheck: true);
    
    // Set up listeners for phone controllers to rebuild validation on changes
    _structurePhoneController.addListener(() {
      if (_structurePhoneController.text.isNotEmpty && _validPrefixes.isNotEmpty) {
        setState(() {
          _structurePhoneError = _validatePhone(_structurePhoneController.text);
        });
      }
    });
    
    _contactPhoneController.addListener(() {
      if (_contactPhoneController.text.isNotEmpty && _validPrefixes.isNotEmpty) {
        setState(() {
          _contactPhoneError = _validatePhone(_contactPhoneController.text);
        });
      }
    });
    
    _adminPhoneController.addListener(() {
      if (_adminPhoneController.text.isNotEmpty && _validPrefixes.isNotEmpty) {
        setState(() {
          _adminPhoneError = _validatePhone(_adminPhoneController.text);
        });
      }
    });

    // Prefill for Google mode
    if (_isGoogleMode) {
      final g = _googleData ?? {};
      final email = g['email']?.toString() ?? '';
      final displayName = g['displayName']?.toString() ?? '';
      // Attempt to split displayName
      String firstName = '';
      String lastName = '';
      if (displayName.isNotEmpty) {
        final parts = displayName.split(' ');
        if (parts.length == 1) {
          firstName = parts.first;
        } else if (parts.isNotEmpty) {
          firstName = parts.first;
          lastName = parts.sublist(1).join(' ');
        }
      }
      _structureEmailController.text = email;
      _contactEmailController.text = email; // default; user can change later if needed
      _adminEmailController.text = email;
      _contactFirstNameController.text = firstName;
      _contactLastNameController.text = lastName;
      _adminFirstNameController.text = firstName;
      _adminLastNameController.text = lastName;
      // Auto generate read-only username placeholder
      _adminUsernameController.text = (email.isNotEmpty ? email.split('@').first : (firstName + lastName).toLowerCase().replaceAll(' ', ''));
    }
  }
  
  Future<void> _fetchLocationData() async {
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });

    try {
      final response = await _locationService.fetchLocationData();
      
      print("=================== LOCATION DATA RECEIVED ===================");
      print("StatusCode: ${response.statusCode}");
      print("Message: ${response.message}");
      print("Countries count: ${response.data.length}");
      
      setState(() {
        _locationData = response.data;
        _isLoadingLocations = false;
      });
      
      // Mark backend as available since we successfully fetched data
      NetworkManager().markBackendAsAvailable();
    } catch (e) {
      setState(() {
        _locationError = 'Failed to load location data: $e';
        _isLoadingLocations = false;
      });
      print("ERROR loading location data: $e");
    }
  }
  
  void _onLocationSelected(Map<String, dynamic> location) {
    // Debug the incoming location data
    print('📍 LOCATION SELECTED:');
    print('📍 Raw data: ${location.toString()}');
    
    // Clear phone-related data first to avoid showing outdated info
    String? newCountryCode;
    List<String> newPrefixes = [];
    String? countryFlag;
    
    // Process location selection
    if (location.isNotEmpty) {
      // Clear location error if location is selected
      _locationError = null;
      
      // Find the selected location's country to extract country code and prefixes
      String? selectedType = location['type'];
      String? selectedCountryId;
      
      print('📱 Selected location type: $selectedType');
      
      if (selectedType == 'country') {
        // If it's a country, we already have what we need
        selectedCountryId = location['id'];
        print('📱 Direct country selection, ID: $selectedCountryId');
      } else if (selectedType == 'province') {
        // For province, get the country_id if available or search for parent
        selectedCountryId = location['country_id'] ?? location['system_country_id'];
        print('📱 Province selection, country ID: $selectedCountryId');
      } else if (selectedType == 'town') {
        // For town, we need to find the parent country - check multiple fields
        selectedCountryId = location['country_id'] ?? location['system_country_id'];
        
        // If country_id not directly available in town data, check for province data
        if (selectedCountryId == null) {
          // Try to get province parent first, then find its country
          String? provinceId = location['province_id'] ?? location['parent_id'];
          
          if (provinceId != null) {
            print('📱 Town with province parent ID: $provinceId');
            // Find province in location data to get its country
            for (var country in _locationData) {
              for (var province in country.children) {
                if (province.id == provinceId) {
                  selectedCountryId = country.id;
                  print('📱 Found parent country via province: $selectedCountryId');
                  break;
                }
              }
              if (selectedCountryId != null) break;
            }
          }
        }
        
        // If we still don't have the country ID, search directly for the town in all countries
        if (selectedCountryId == null) {
          String townId = location['id'];
          print('📱 Searching for town ID: $townId in all location data');
          
          for (var country in _locationData) {
            bool found = false;
            for (var province in country.children) {
              for (var town in province.children) {
                if (town.id == townId) {
                  selectedCountryId = country.id;
                  print('📱 Found parent country by searching town: $selectedCountryId');
                  found = true;
                  break;
                }
              }
              if (found) break;
            }
            if (found) break;
          }
        }
      }
      
      // Final fallback - use the first country in the data if available
      if (selectedCountryId == null && _locationData.isNotEmpty) {
        selectedCountryId = _locationData.first.id;
        print('📱 Fallback to first country in data: $selectedCountryId');
      }
      
      // Find the country in our location data
      if (selectedCountryId != null) {
        print('🔍 Searching for country with ID: $selectedCountryId');
        bool countryFound = false;
        
        for (var country in _locationData) {
          if (country.id == selectedCountryId) {
            countryFound = true;
            print('✅ Found matching country: ${country.name}');
            
            // Found matching country, extract codes and prefixes
            if (country.countryCodes != null && country.countryCodes!.isNotEmpty) {
              // Make sure country code has + prefix
              String code = country.countryCodes![0].countryCode;
              newCountryCode = code.startsWith('+') ? code : '+$code';
              print('📱 Found country code: $newCountryCode');
            }
            
            if (country.telephonePrefixes != null && country.telephonePrefixes!.isNotEmpty) {
              try {
                // Debug the telephone prefixes in detail
                print('📱 Telephone prefixes count: ${country.telephonePrefixes!.length}');
                print('📱 Telephone prefixes data: ${country.telephonePrefixes!.map((p) => "${p.id}:${p.prefix}").join(", ")}');
                
                // Direct extraction
                newPrefixes = country.telephonePrefixes!
                  .map((prefix) => prefix.prefix)
                  .toList();
                
                if (newPrefixes.isNotEmpty) {
                  print('✅ Successfully extracted prefixes: $newPrefixes');
                } else {
                  print('⚠️ Extracted prefixes list is empty');
                  newPrefixes = ['81', '82', '89', '99']; // Default fallback
                  print('📱 Using default prefixes as fallback');
                }
              } catch (e) {
                print('❌ Error extracting prefixes: $e');
                newPrefixes = ['81', '82', '89', '99'];
                print('📱 Using fallback prefixes due to error');
              }
            } else {
              print('⚠️ No telephone prefixes found in the API data for this country');
              newPrefixes = ['81', '82', '89', '99']; // Default fallback
              print('📱 Using default prefixes due to no prefixes in data');
            }
            
            // Get the country flag
            countryFlag = country.countryFlag;
            break;
          }
        }
        
        if (!countryFound) {
          print('❌ Could not find country with ID: $selectedCountryId in location data');
          // Use default values since we couldn't find the country
          newCountryCode = '+243'; // Default Congo code
          newPrefixes = ['81', '82', '89', '99']; // Default Congo prefixes
          countryFlag = '🇨🇩'; // Default Congo flag
        }
      }
    }
    
    // Update state after all data processing to ensure UI updates properly
    setState(() {
      bool locationChanged = _selectedLocation.isEmpty || 
                             _selectedLocation['id'] != location['id'];
      
      _selectedLocation = Map<String, dynamic>.from(location); // Create a copy to safely modify
      
      // Use default values only if nothing was found
      if (_selectedLocation.isNotEmpty) {
        // Use fetched values or fallback to defaults if empty
        _countryCode = newCountryCode ?? '+243'; // Default to Congo if not found
        
        // Make sure we're setting the prefixes from the API data
        if (newPrefixes.isNotEmpty) {
          _validPrefixes = List<String>.from(newPrefixes);
          print('📱 Using API prefixes: $_validPrefixes');
        } else {
          _validPrefixes = ['81', '82', '89', '99'];
          print('📱 Using default prefixes: $_validPrefixes');
        }
        
        // Add country code and prefixes to the selected location data
        _selectedLocation['country_code'] = _countryCode;
        _selectedLocation['telephone_prefixes_string'] = _validPrefixes.join(',');
        _selectedLocation['country_flag'] = countryFlag ?? '🇨🇩'; // Default Congo flag
        
        // Clear phone fields if country code changed to avoid invalid numbers
        if (locationChanged) {
          _structurePhoneController.clear();
          _contactPhoneController.clear();
          _adminPhoneController.clear();
          print('📱 Phone fields cleared due to location change');
        }
      } else {
        // Clear data when location is not selected
        _countryCode = null;
        _validPrefixes = [];
        _structurePhoneController.clear();
        _contactPhoneController.clear();
        _adminPhoneController.clear();
        print('📱 All phone-related data cleared (no location)');
      }
      
      // Clear any existing phone errors
      _structurePhoneError = null;
      _contactPhoneError = null;
      _adminPhoneError = null;
    });
    
    // Debug log selected location
    if (_selectedLocation.isNotEmpty) {
      print('Selected location: ${_selectedLocation['type']} - ${_selectedLocation['name']}');
      print('Selected location id: ${_selectedLocation['id']}');
      print('Country code: $_countryCode');
      print('Valid prefixes: ${_validPrefixes.join(", ")}');
    } else {
      print('Location selection cleared');
    }
  }
  
  // Helper method to check if a phone number starts with any valid prefix
  bool _hasValidPrefix(String phoneNumber) {
    if (_validPrefixes.isEmpty || phoneNumber.length < 2) {
      return false;
    }
    
    for (String prefix in _validPrefixes) {
      if (phoneNumber.startsWith(prefix)) {
        return true;
      }
    }
    
    return false;
  }

  @override
  void dispose() {
    _structureNameController.dispose();
    _addressController.dispose();
    _structurePhoneController.dispose();
    _structureEmailController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    _contactFirstNameController.dispose();
    _contactLastNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: _isGoogleMode
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'health_structure_registration'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildGoogleBadge(),
                ],
              )
            : Text(
                'health_structure_registration'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: NetworkStatusWidget(
          preserveSpace: true,
          absorbPointerWhenOffline: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location selection (first to affect other fields)
                        _buildSectionHeader('location'.tr),
                        const SizedBox(height: 20),
                      
                      // Location tree selector
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: LocationTreeSelect(
                          label: 'structure_location'.tr,
                          hint: 'select_location'.tr,
                          locations: _locationData,
                          onLocationSelected: _onLocationSelected,
                          isLoading: _isLoadingLocations,
                          errorText: _locationError,
                          isRequired: true,
                          prefixIcon: Icon(Ionicons.location_outline),
                          showPath: true,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Health Structure Type Selector
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: LanguageAwareText(
                                'health_structure_type',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: ButtonTheme(
                                  alignedDropdown: true,
                                  child: DropdownButton<HealthStructureType>(
                                    value: _selectedHealthStructureType,
                                    hint: LanguageAwareText(
                                      'select_health_structure_type',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    borderRadius: BorderRadius.circular(8),
                                    onChanged: (HealthStructureType? value) {
                                      setState(() {
                                        _selectedHealthStructureType = value;
                                      });
                                    },
                                    items: HealthStructureType.values.map((HealthStructureType type) {
                                      return DropdownMenuItem<HealthStructureType>(
                                        value: type,
                                        child: Row(
                                          children: [
                                            Icon(type.icon, color: ColorPages.COLOR_PRINCIPAL),
                                            const SizedBox(width: 10),
                                            LanguageAwareText(
                                              type.label.toLowerCase(), // Ensure consistent key format for translation
                                              style: GoogleFonts.ubuntu(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedHealthStructureType != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_selectedHealthStructureType!.icon, 
                                      color: ColorPages.COLOR_PRINCIPAL, 
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          LanguageAwareText(
                                            'you_selected',
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: ColorPages.COLOR_PRINCIPAL,
                                            ),
                                          ),
                                          Text(' '),
                                          LanguageAwareText(
                                            _selectedHealthStructureType!.label.toLowerCase(), // Ensure consistent key format
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: ColorPages.COLOR_PRINCIPAL,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Structure Information Section
                      _buildSectionHeader('structure_information'.tr),
                      const SizedBox(height: 20),
                      
                      // Structure name
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: CustomTextField(
                          controller: _structureNameController,
                          label: 'structure_name'.tr,
                          hint: 'hint_structure_name'.tr,
                          prefixIcon: Ionicons.medical_outline,
                          validator: _validateRequired,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const SizedBox(height: 20),
                      
                      // Structure email
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: CustomTextField(
                          controller: _structureEmailController,
                          label: 'email'.tr,
                          hint: 'hint_structure_email'.tr,
                          prefixIcon: Ionicons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isGoogleMode,
                          validator: _isGoogleMode ? null : _validateEmail,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Phone field - Only shown when location is selected
                      if (_selectedLocation.isNotEmpty && _countryCode != null)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom phone field with country flag and code
                            Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                'structure_phone'.tr,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  // Country flag and code
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      border: Border(
                                        right: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Country flag if available
                                        if (_selectedLocation['country_flag'] != null)
                                          Text(
                                            _selectedLocation['country_flag'],
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        const SizedBox(width: 5),
                                        // Country code
                                        Text(
                                          _countryCode ?? '',
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Phone number input
                                  Expanded(
                                    child: TextField(
                                      controller: _structurePhoneController,
                                      decoration: InputDecoration(
                                        hintText: _validPrefixes.isNotEmpty 
                                          ? '${_validPrefixes.first} XXXXXXX'
                                          : "XXXXXXXX",
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        prefixIcon: Icon(Ionicons.call_outline, color: Colors.grey[600], size: 20),
                                        errorText: _structurePhoneError,
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Display prefixes
                            if (_validPrefixes.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.only(top: 8, left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'valid_prefixes'.tr,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  // Use a more flexible layout for multiple prefixes
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _validPrefixes.map((prefix) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        prefix,
                                        style: GoogleFonts.ubuntu(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold,
                                          color: ColorPages.COLOR_PRINCIPAL,
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Address
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: CustomTextField(
                          controller: _addressController,
                          label: 'address'.tr,
                          hint: 'hint_structure_address'.tr,
                          prefixIcon: Ionicons.location_outline,
                          validator: _validateRequired,
                          maxLines: 2,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const SizedBox(height: 20),
                      
                      // Location coordinates
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _longitudeController,
                                label: 'longitude'.tr,
                                hint: 'hint_longitude'.tr,
                                prefixIcon: Ionicons.navigate_outline,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: _validateRequired,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _latitudeController,
                                label: 'latitude'.tr,
                                hint: 'hint_latitude'.tr,
                                prefixIcon: Ionicons.navigate_outline,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: _validateRequired,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Get current location button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: OutlinedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Ionicons.location_outline),
                          label: Text('use_current_location'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorPages.COLOR_PRINCIPAL,
                            side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Contact Person Section
                      _buildSectionHeader('contact_person'.tr),
                      const SizedBox(height: 20),
                      
                      // Contact person name
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _contactFirstNameController,
                                label: 'first_name'.tr,
                                hint: 'hint_first_name'.tr,
                                prefixIcon: Ionicons.person_outline,
                                validator: _validateRequired,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _contactLastNameController,
                                label: 'last_name'.tr,
                                hint: 'hint_last_name'.tr,
                                prefixIcon: Ionicons.person_outline,
                                validator: _validateRequired,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Contact gender
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                        child: CustomDropdown<String>(
                          label: 'gender'.tr,
                          hint: 'hint_select_gender'.tr,
                          value: _contactGender,
                          items: _genders.map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender.tr),
                          )).toList(),
                          onChanged: (value) => setState(() => _contactGender = value),
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Contact email
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 800),
                        child: CustomTextField(
                          controller: _contactEmailController,
                          label: 'email'.tr,
                          hint: 'hint_contact_email'.tr,
                          prefixIcon: Ionicons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isGoogleMode,
                          validator: _isGoogleMode ? null : _validateEmail,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Contact phone - Only shown when location is selected
                      if (_selectedLocation.isNotEmpty && _countryCode != null)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 850),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom phone field with country flag and code
                            Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                'contact_phone'.tr,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  // Country flag and code
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      border: Border(
                                        right: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Country flag if available
                                        if (_selectedLocation['country_flag'] != null)
                                          Text(
                                            _selectedLocation['country_flag'],
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        const SizedBox(width: 5),
                                        // Country code
                                        Text(
                                          _countryCode ?? '',
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Phone number input
                                  Expanded(
                                    child: TextField(
                                      controller: _contactPhoneController,
                                      decoration: InputDecoration(
                                        hintText: _validPrefixes.isNotEmpty 
                                          ? '${_validPrefixes.first} XXXXXXX'
                                          : "XXXXXXXX",
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        prefixIcon: Icon(Ionicons.call_outline, color: Colors.grey[600], size: 20),
                                        errorText: _contactPhoneError,
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Admin Account Section
                      _buildSectionHeader('admin_account_information'.tr),
                      const SizedBox(height: 20),
                      
                      // Admin name
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 900),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _adminFirstNameController,
                                label: 'first_name'.tr,
                                hint: 'hint_first_name'.tr,
                                prefixIcon: Ionicons.person_outline,
                                validator: _validateRequired,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _adminLastNameController,
                                label: 'last_name'.tr,
                                hint: 'hint_last_name'.tr,
                                prefixIcon: Ionicons.person_outline,
                                validator: _validateRequired,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Admin gender
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1000),
                        child: CustomDropdown<String>(
                          label: 'gender'.tr,
                          hint: 'hint_select_gender'.tr,
                          value: _adminGender,
                          items: _genders.map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender.tr),
                          )).toList(),
                          onChanged: (value) => setState(() => _adminGender = value),
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Admin email
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1100),
                        child: CustomTextField(
                          controller: _adminEmailController,
                          label: 'email'.tr,
                          hint: 'hint_admin_email'.tr,
                          prefixIcon: Ionicons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isGoogleMode,
                          validator: _isGoogleMode ? null : _validateEmail,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Admin phone - Only shown when location is selected
                      if (_selectedLocation.isNotEmpty && _countryCode != null)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom phone field with country flag and code
                            Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                'admin_phone'.tr,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  // Country flag and code
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      border: Border(
                                        right: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Country flag if available
                                        if (_selectedLocation['country_flag'] != null)
                                          Text(
                                            _selectedLocation['country_flag'],
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        const SizedBox(width: 5),
                                        // Country code
                                        Text(
                                          _countryCode ?? '',
                                          style: GoogleFonts.ubuntu(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Phone number input
                                  Expanded(
                                    child: TextField(
                                      controller: _adminPhoneController,
                                      decoration: InputDecoration(
                                        hintText: _validPrefixes.isNotEmpty 
                                          ? '${_validPrefixes.first} XXXXXXX'
                                          : "XXXXXXXX",
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        prefixIcon: Icon(Ionicons.call_outline, color: Colors.grey[600], size: 20),
                                        errorText: _adminPhoneError,
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Admin username
                      if (!_isGoogleMode)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1200),
                        child: CustomTextField(
                          controller: _adminUsernameController,
                          label: 'username'.tr,
                          hint: 'hint_admin_username'.tr,
                          prefixIcon: Ionicons.at_outline,
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Admin password
                      if (!_isGoogleMode)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1300),
                        child: CustomTextField(
                          controller: _adminPasswordController,
                          label: 'password'.tr,
                          hint: 'hint_password'.tr,
                          prefixIcon: Ionicons.lock_closed_outline,
                          obscureText: true,
                          validator: _validatePassword,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Confirm password
                      if (!_isGoogleMode)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1350),
                        child: CustomTextField(
                          controller: _adminConfirmPasswordController,
                          label: 'confirm_password'.tr,
                          hint: 'hint_confirm_password'.tr,
                          prefixIcon: Ionicons.lock_closed_outline,
                          obscureText: true,
                          validator: _validateConfirmPassword,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Terms and conditions
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1400),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                              activeColor: ColorPages.COLOR_PRINCIPAL,
                            ),
                            Expanded(
                              child: Text(
                                'I accept the terms and conditions',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              // Register button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 1500),
                  child: CustomButton(
                    text: _isGoogleMode ? 'continue'.tr : 'register'.tr,
                    onPressed: _isLoading ? null : _handleRegistration,
                    isLoading: _isLoading,
                    backgroundColor: Colors.blue[600]!,
                  ),
                ),
              ),
            ],
          ),
        ),
        ), // end NetworkStatusWidget
      ), // end SafeArea
    ); // end Scaffold
  }

  Widget _buildSectionHeader(String title) {
    return LanguageAwareText(
      title,
      style: GoogleFonts.ubuntu(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.tr;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_required'.tr;
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'email_invalid'.tr;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    if (value.length < 8) {
      return 'password_min_length'.tr;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'confirm_password_required'.tr;
    }
    if (value != _adminPasswordController.text) {
      return 'passwords_not_match'.tr;
    }
    return null;
  }
  
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'phone_required'.tr;
    }
    
    // Check if phone number contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'phone_only_digits'.tr;
    }
    
    // Check if phone number starts with a valid prefix if prefixes are defined
    if (_validPrefixes.isNotEmpty && value.length >= 2) {
      // Use our helper method to check prefixes
      if (!_hasValidPrefix(value) && value.length >= 3) {
        // Only show prefix error if the user has entered enough digits
        return 'invalid_phone_prefix'.tr;
      }
    }
    
    // Only check length if the prefix is valid and the user has entered a substantial part of the number
    if (_hasValidPrefix(value) && value.length > 5 && value.length < 9) {
      // Show a warning only if they've entered most of the number but it's still too short
      return 'invalid_phone_length'.tr;
    } else if (value.length > 15) {
      // Phone numbers are rarely longer than 15 digits including prefix
      return 'invalid_phone_length'.tr;
    }
    
    return null;
  }
  
  // Helper method to safely show a snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    // Prevent multiple simultaneous requests
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled. Please enable them.', isError: true);
        await Geolocator.openLocationSettings();
        return;
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied', isError: true);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions permanently denied. Please enable in settings.', isError: true);
        await Geolocator.openAppSettings();
        return;
      }

      // 3. Get current position with timeout & high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 12));

      setState(() {
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _latitudeController.text = position.latitude.toStringAsFixed(6);
      });

      _showSnackBar('Location obtained successfully');
    } on TimeoutException {
      _showSnackBar('Timed out while obtaining location. Try again.', isError: true);
    } catch (e) {
      print('📍 Error getting location: $e');
      _showSnackBar('Error obtaining location', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  

  void _handleRegistration() async {
    print('🔍 Starting health structure registration validation...');
    
    try {
      // Check form validation
      if (_formKey.currentState == null) {
        print('❌ Form key state is null');
        _showSnackBar('form_validation_error'.tr, isError: true);
        return;
      }
      
      final isValid = _formKey.currentState!.validate();
      print('📝 Form validation result: $isValid');
      
      if (!isValid) {
        return;
      }

      // In Google mode we do not require username/password fields (already hidden)
      if (_isGoogleMode) {
        // Skip multi-email verification & directly hit google-register endpoint via AuthService
        setState(() => _isLoading = true);
        try {
          if (_selectedLocation.isEmpty || !_selectedLocation.containsKey('id')) {
            _showSnackBar('select_valid_location'.tr, isError: true);
            return;
          }
          if (_selectedHealthStructureType == null) {
            _showSnackBar('select_health_structure_type_error'.tr, isError: true);
            return;
          }
          if (!_acceptTerms) {
            _showSnackBar('accept_terms_conditions'.tr, isError: true);
            return;
          }
          // We still need valid phones in google mode
          if (_countryCode == null) {
            _showSnackBar('select_valid_location_for_phone'.tr, isError: true);
            return;
          }
          final String? structurePhoneError = _validatePhone(_structurePhoneController.text);
          final String? contactPhoneError = _validatePhone(_contactPhoneController.text);
          final String? adminPhoneError = _validatePhone(_adminPhoneController.text);
          if (structurePhoneError != null || contactPhoneError != null || adminPhoneError != null) {
            setState(() {
              _structurePhoneError = structurePhoneError;
              _contactPhoneError = contactPhoneError;
              _adminPhoneError = adminPhoneError;
            });
            return;
          }
          final Map<String, dynamic> googlePayload = {
            'registration_mode': 'google',
            'account_type': 'health_structure',
            'health_structure': {
              'health_structure_name': _structureNameController.text,
              'email': _structureEmailController.text,
              'phone_number': _countryCode! + _structurePhoneController.text,
              'address': _addressController.text,
              'location_id': _selectedLocation['id'],
              'health_structure_type_flag': _selectedHealthStructureType!.value,
              'latitude': _latitudeController.text.isNotEmpty ? double.tryParse(_latitudeController.text) : null,
              'longitude': _longitudeController.text.isNotEmpty ? double.tryParse(_longitudeController.text) : null,
            },
            'contact_person': {
              'first_name': _contactFirstNameController.text,
              'last_name': _contactLastNameController.text,
              'email': _contactEmailController.text,
              'phone': _countryCode! + _contactPhoneController.text,
              'gender': _contactGender,
            },
            'admin_account': {
              'first_name': _adminFirstNameController.text,
              'last_name': _adminLastNameController.text,
              'email': _adminEmailController.text,
              'phone': _countryCode! + _adminPhoneController.text,
              // username/password omitted in google mode (handled server-side)
              'gender': _adminGender,
              'google_user': _googleData,
            }
          };
          print('📦 Google health structure payload: $googlePayload');
          // Lazy import to avoid circular imports at top-level
          // ignore: unused_local_variable
          final authServiceImport = true;
          // Use AuthService
          // We add the import at file top separately
          final auth = AuthService();
          final result = await auth.googleRegister(googlePayload);
          if (!mounted) return;
          if (result['success'] == true) {
            _showSnackBar('registration_success'.tr, isError: false);
            context.go('/login');
          } else {
            _showSnackBar(result['message']?.toString() ?? 'registration_failed'.tr, isError: true);
          }
        } catch (e) {
          print('❌ Google registration error: $e');
          _showSnackBar('registration_failed'.tr, isError: true);
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
        return; // stop normal flow
      }

      // Check if location is selected
      print('🌍 Selected location: $_selectedLocation');
      
      // Ensure we have a location selected
      final bool hasValidLocation = _selectedLocation.isNotEmpty && _selectedLocation.containsKey('id');
      
      if (!hasValidLocation) {
        print('❌ Location not selected');
        _showSnackBar('select_valid_location'.tr, isError: true);
        return;
      }
      
      // Check if health structure type is selected
      if (_selectedHealthStructureType == null) {
        print('❌ Health structure type not selected');
        _showSnackBar('select_health_structure_type_error'.tr, isError: true);
        return;
      }
      
      // Manually validate phone numbers since they're not part of the form
      if (_countryCode != null) {
        // Structure phone validation
        final String? structurePhoneError = _validatePhone(_structurePhoneController.text);
        if (structurePhoneError != null) {
          print('❌ Structure phone validation failed: $structurePhoneError');
          setState(() => _structurePhoneError = structurePhoneError);
          return;
        }
        
        // Contact phone validation
        final String? contactPhoneError = _validatePhone(_contactPhoneController.text);
        if (contactPhoneError != null) {
          print('❌ Contact phone validation failed: $contactPhoneError');
          setState(() => _contactPhoneError = contactPhoneError);
          return;
        }
        
        // Admin phone validation
        final String? adminPhoneError = _validatePhone(_adminPhoneController.text);
        if (adminPhoneError != null) {
          print('❌ Admin phone validation failed: $adminPhoneError');
          setState(() => _adminPhoneError = adminPhoneError);
          return;
        }
      } else {
        print('❌ Country code not set');
        _showSnackBar('select_valid_location_for_phone'.tr, isError: true);
        return;
      }
      
      // Check terms acceptance
      if (!_acceptTerms) {
        print('❌ Terms not accepted');
        _showSnackBar('accept_terms_conditions'.tr, isError: true);
        return;
      }
      
      print('✅ All validation passed');
      
      // Set loading state
      setState(() => _isLoading = true);
      
      // Prepare registration payload
      final Map<String, dynamic> payload = {
        // Structure information
        'health_structure_name': _structureNameController.text,
        'email': _structureEmailController.text,
        'phone_number': _countryCode! + _structurePhoneController.text,
        'address': _addressController.text,
        'location_id': _selectedLocation['id'],
        'health_structure_type_flag': _selectedHealthStructureType!.value,
        'latitude': _latitudeController.text.isNotEmpty ? double.parse(_latitudeController.text) : null,
        'longitude': _longitudeController.text.isNotEmpty ? double.parse(_longitudeController.text) : null,
        
        // Contact person information
        'contact_person': {
          'first_name': _contactFirstNameController.text,
          'last_name': _contactLastNameController.text,
          'email': _contactEmailController.text,
          'phone': _countryCode! + _contactPhoneController.text,
          'gender': _contactGender,
        },
        
        // Admin account information
        'admin_account': {
          'first_name': _adminFirstNameController.text,
          'last_name': _adminLastNameController.text,
          'email': _adminEmailController.text,
          'phone': _countryCode! + _adminPhoneController.text,
          'username': _adminUsernameController.text,
          'password': _adminPasswordController.text,
          'gender': _adminGender,
        },
      };
      
      print('📦 Registration payload prepared: $payload');
      
      // Collect unique emails to verify (order: structure, contact, admin)
      final Set<String> emailSet = {};
      if (_structureEmailController.text.trim().isNotEmpty) emailSet.add(_structureEmailController.text.trim());
      if (_contactEmailController.text.trim().isNotEmpty) emailSet.add(_contactEmailController.text.trim());
      if (_adminEmailController.text.trim().isNotEmpty) emailSet.add(_adminEmailController.text.trim());
      final emails = emailSet.toList();

      if (emails.isEmpty) {
        _showSnackBar('email_required'.tr, isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Navigate to multi-email verification flow BEFORE actual submission
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HealthStructureEmailVerificationPage(
              emails: emails,
              registrationPayload: payload,
            ),
          ),
        );
      }
    } catch (e) {
      print('⚠️ Registration error: $e');
      _showSnackBar('registration_failed'.tr, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// === Helper Widgets / Badges ===
extension _GoogleBadgeExtension on _HealthStructureRegistrationPageState {
  Widget _buildGoogleBadge() {
    return Semantics(
      label: 'Google authenticated'.trParams({}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.logo_google, size: 16, color: Colors.redAccent),
            const SizedBox(width: 6),
            Text(
              'Google',
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}