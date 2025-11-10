import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import '../config/theme/ColorPages.dart';
import '../config/AppConfig.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/CustomDropdown.dart';
import '../widgets/CustomButton.dart';
import '../../core/widgets/location_tree_select.dart';
import '../models/SystemCountry.dart';
import '../services/LocationService.dart';
import '../services/AuthService.dart';
import '../models/UserInfoValidation.dart';
import 'OTPVerificationPage.dart';

class PersonalRegistrationPage extends StatefulWidget {
  final Map<String, dynamic>? extra;
  
  const PersonalRegistrationPage({super.key, this.extra});

  @override
  State<PersonalRegistrationPage> createState() => _PersonalRegistrationPageState();
}

class _PersonalRegistrationPageState extends State<PersonalRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  
  // Selected values
  String? _selectedGender;  
  String? _selectedBloodType;
  String? _selectedReason;
  DateTime? _selectedDate;
  
  // Location data
  Map<String, dynamic> _selectedLocation = {};
  List<SystemCountry> _locationData = [];
  bool _isLoadingLocations = false;
  String? _locationError;
  final LocationService _locationService = LocationService();
  
  // Phone formatting info
  String? _countryCode;
  List<String> _validPrefixes = [];
  String? _phoneError;
  
  // Loading state
  bool _isLoading = false;
  bool _acceptTerms = false;
  
  // Mock data - in real app, this would come from API
  final List<Map<String, String>> _genders = [
    {'value': 'm', 'label': 'male'},
    {'value': 'f', 'label': 'female'},
  ];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _reasons = ['blood_donor', 'blood_recipient', 'explore_app', 'delivery_person'];

  @override
  void initState() {
    super.initState();
    _fetchLocationData();
    _testApiConnectivity(); // Test API connectivity on initialization
    // Google mode prefill
    final mode = widget.extra?['registration_mode'];
    if (mode == 'google') {
      final gEmail = widget.extra?['google_email'];
      final gName = widget.extra?['google_display_name'];
      if (gEmail is String && gEmail.isNotEmpty) {
        _emailController.text = gEmail;
      }
      if (gName is String && gName.isNotEmpty) {
        final parts = gName.split(' ');
        if (parts.isNotEmpty) _firstNameController.text = parts.first;
        if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
      }
    }
    
    // Set up a listener for the phone controller to rebuild validation on changes
    _phoneController.addListener(() {
      // Only rebuild if we have text to avoid unnecessary rebuilds
      if (_phoneController.text.isNotEmpty && _validPrefixes.isNotEmpty) {
        setState(() {
          _phoneError = _validatePhone(_phoneController.text);
        });
      }
    });
  }
  
  // Test API connectivity
  Future<void> _testApiConnectivity() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('${AppConfig.instance.baseApiUrl}/eblood/users/test'),
      );
      
      print('🔄 API Connectivity Test:');
      print('🔄 Status Code: ${response.statusCode}');
      print('🔄 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ API Connection Successful');
      } else {
        print('❌ API Connection Failed');
      }
    } catch (e) {
      print('⚠️ API Connection Error: $e');
    }
  }

  Future<void> _fetchLocationData() async {
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });

    try {
      final response = await _locationService.fetchLocationData();
      
      // Debug location data received from API
      print("=================== LOCATION DATA RECEIVED ===================");
      print("StatusCode: ${response.statusCode}");
      print("Message: ${response.message}");
      print("Countries count: ${response.data.length}");
      
      // Print structure for debugging
      for (var country in response.data) {
        print("COUNTRY: ${country.name} (${country.namedEntityFlag})");
        print("- Country ID: ${country.id}");
        print("- Children count: ${country.children.length}");
        
        // Print country codes and telephone prefixes if available
        if (country.countryCodes != null && country.countryCodes!.isNotEmpty) {
          print("- Country Codes: ${country.countryCodes!.map((c) => c.countryCode).join(', ')}");
        }
        
        if (country.telephonePrefixes != null && country.telephonePrefixes!.isNotEmpty) {
          print("- Telephone Prefixes Count: ${country.telephonePrefixes!.length}");
          print("- Telephone Prefixes: ${country.telephonePrefixes!.map((p) => p.prefix).join(', ')}");
          // Detailed debug of prefixes
          for (var prefix in country.telephonePrefixes!) {
            print("  - Prefix: ${prefix.prefix} (ID: ${prefix.id})");
          }
        }
        
        if (country.countryFlag != null) {
          print("- Country Flag: ${country.countryFlag}");
        }
        
        for (var province in country.children) {
          print("  PROVINCE: ${province.name} (${province.namedEntityFlag})");
          print("  - Province ID: ${province.id}");
          print("  - Children count: ${province.children.length}");
          
          for (var town in province.children) {
            print("    TOWN: ${town.name} (${town.namedEntityFlag})");
            print("    - Town ID: ${town.id}");
          }
        }
      }
      print("============================================================");
      
      setState(() {
        _locationData = response.data;
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to load location data: $e';
        _isLoadingLocations = false;
      });
      print("ERROR loading location data: $e");
    }
  }

  void _onLocationSelected(Map<String, dynamic> location) {
    // Debug the incoming location data in detail
    print('📍 LOCATION SELECTED:');
    print('📍 Raw data: ${location.toString()}');
    print('📍 Type: ${location['type']}');
    print('📍 ID: ${location['id']}');
    print('📍 Name: ${location['name']}');
    print('📍 Parent ID: ${location['parent_id']}');
    print('📍 Country ID: ${location['country_id']}');
    print('📍 System Country ID: ${location['system_country_id']}');
    print('📍 Province ID: ${location['province_id']}');
    
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
            } else {
              print('⚠️ No country codes found for this country');
            }
            
            if (country.telephonePrefixes != null && country.telephonePrefixes!.isNotEmpty) {
              try {
                // Debug the telephone prefixes in detail
                print('📱 Telephone prefixes count: ${country.telephonePrefixes!.length}');
                print('📱 Telephone prefixes data: ${country.telephonePrefixes!.map((p) => "${p.id}:${p.prefix}").join(", ")}');
                
                // Direct extraction - no need for complex error handling since we know the structure
                newPrefixes = country.telephonePrefixes!
                  .map((prefix) => prefix.prefix)
                  .toList();
                
                if (newPrefixes.isNotEmpty) {
                  // Log the prefixes we extracted
                  print('✅ Successfully extracted prefixes: $newPrefixes');
                } else {
                  print('⚠️ Extracted prefixes list is empty');
                  newPrefixes = ['81', '82', '89', '99']; // Default fallback
                  print('📱 Using default prefixes as fallback');
                }
              } catch (e) {
                print('❌ Error extracting prefixes: $e');
                // Use default prefixes only if there's an error
                newPrefixes = ['81', '82', '89', '99'];
                print('📱 Using fallback prefixes due to error');
              }
            } else {
              // No telephone prefixes in the data
              print('⚠️ No telephone prefixes found in the API data for this country');
              newPrefixes = ['81', '82', '89', '99']; // Default fallback
              print('📱 Using default prefixes due to no prefixes in data');
            }
            
            // Get the country flag
            if (country.countryFlag != null && country.countryFlag!.isNotEmpty) {
              countryFlag = country.countryFlag;
              print('🏳️ Found country flag: $countryFlag');
            } else {
              print('⚠️ No country flag found');
            }
            
            // We found what we needed, break the loop
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
    
    // Before state update - log what we're about to set
    print('📱 BEFORE STATE UPDATE:');
    print('📱 New country code: $newCountryCode');
    print('📱 New prefixes: $newPrefixes');
    
    // Update state after all data processing to ensure UI updates properly
    setState(() {
      bool locationChanged = _selectedLocation.isEmpty || 
                             _selectedLocation['id'] != location['id'];
      
      _selectedLocation = Map<String, dynamic>.from(location); // Create a copy to safely modify
      
      // Use default values only if nothing was found
      if (_selectedLocation.isNotEmpty) {
        // Use fetched values or fallback to defaults if empty
        String? oldCountryCode = _countryCode;
        _countryCode = newCountryCode ?? '+243'; // Default to Congo if not found
        
        // Make sure we're setting the prefixes from the API data
        if (newPrefixes.isNotEmpty) {
          _validPrefixes = List<String>.from(newPrefixes); // Create a new copy to avoid reference issues
          print('📱 Using API prefixes: $_validPrefixes');
        } else {
          _validPrefixes = ['81', '82', '89', '99'];
          print('📱 Using default prefixes: $_validPrefixes');
        }
        
        // Add country code and prefixes to the selected location data
        // Store as a joined string to avoid type issues
        _selectedLocation['country_code'] = _countryCode;
        _selectedLocation['telephone_prefixes_string'] = _validPrefixes.join(',');
        _selectedLocation['country_flag'] = countryFlag ?? '🇨🇩'; // Default Congo flag
        
        // Clear phone if country code changed to avoid invalid numbers
        if (locationChanged || oldCountryCode != _countryCode) {
          _phoneController.clear();
          print('📱 Phone field cleared due to location/country code change');
        }
      } else {
        // Clear data when location is not selected
        _countryCode = null;
        _validPrefixes = [];
        _phoneController.clear();
        print('📱 All phone-related data cleared (no location)');
      }
      
      // Clear any existing phone error
      _phoneError = null;
    });
    
    // Debug log selected location
    if (_selectedLocation.isNotEmpty) {
      print('Selected location: ${_selectedLocation['type']} - ${_selectedLocation['town_name'] ?? _selectedLocation['province_name'] ?? _selectedLocation['country_name']}');
      print('Selected location id (ref_entity_id): ${_selectedLocation['id']}');
      print('Country code: $_countryCode');
      if (_validPrefixes.isNotEmpty) {
        print('Valid prefixes: ${_validPrefixes.join(", ")}');
      }
    } else {
      print('Location selection cleared');
    }
    
    // Ensure that any text field validation errors are cleared when selection changes
    _phoneError = null;
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
  
  // No unused methods

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
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
        title: Text(
          'personal_account'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
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
                      // Personal Information Section
                      _buildSectionHeader('personal_information'.tr),
                      const SizedBox(height: 20),
                      
                      // Name fields
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _firstNameController,
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
                                controller: _lastNameController,
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
                      
                      // Gender dropdown
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: CustomDropdown<String>(
                          label: 'gender'.tr,
                          hint: 'hint_select_gender'.tr,
                          value: _selectedGender,
                          items: _genders.map((gender) => DropdownMenuItem(
                            value: gender['value'],
                            child: Text(gender['label']!.tr),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedGender = value),
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Date of Birth field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 150),
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: _dateOfBirthController,
                              label: 'date_of_birth'.tr,
                              hint: 'hint_date_format'.tr,
                              prefixIcon: Ionicons.calendar_outline,
                              validator: _validateDateOfBirth,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Contact Information Section
                      _buildSectionHeader('contact_information'.tr),
                      const SizedBox(height: 20),
                      
                      // Location dropdown (country, province, town) - MOVED TO TOP
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: LocationTreeSelect(
                          label: 'your_location'.tr,
                          hint: 'hint_select_location'.tr,
                          locations: _locationData,
                          onLocationSelected: _onLocationSelected,
                          isLoading: _isLoadingLocations,
                          errorText: _locationError,
                          isRequired: true,
                          prefixIcon: Icon(Ionicons.location_outline),
                          showPath: true,
                          selectOnlyLastChild: true, // Only allow selecting towns (leaf nodes)
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Email field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _emailController,
                              label: 'email'.tr,
                              hint: 'hint_email'.tr,
                              prefixIcon: Ionicons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              enabled: widget.extra?['registration_mode'] != 'google',
                              validator: widget.extra?['registration_mode'] == 'google' ? null : _validateEmail,
                            ),
                            if (widget.extra?['registration_mode'] == 'google')
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Ionicons.shield_checkmark,
                                      size: 16,
                                      color: Colors.green[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Verified by Google',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      
                      // Phone field - Only shown when location is selected
                      if (_selectedLocation.isNotEmpty && _countryCode != null)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom phone field with country flag and code
                            Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                'phone_number'.tr,
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
                                          _countryCode ?? '', // Display country code without adding an extra +
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
                                      controller: _phoneController,
                                      decoration: InputDecoration(
                                        hintText: _validPrefixes.isNotEmpty 
                                          ? '${_validPrefixes.first} XXXXXXX'  // Show first prefix as example
                                          : "XXXXXXXX",
                                        hintStyle: TextStyle(color: Colors.grey[400]),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        prefixIcon: Icon(Ionicons.call_outline, color: Colors.grey[600], size: 20),
                                        errorText: _phoneError,
                                        // Show a tooltip with all valid prefixes
                                        helperText: _validPrefixes.isNotEmpty
                                          ? 'Use one of the valid prefixes shown below'
                                          : null,
                                        helperStyle: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      onChanged: (value) {
                                        // Validate the phone number on change
                                        setState(() {
                                          _phoneError = _validatePhone(value);
                                        });
                                      },
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
                      
                      const SizedBox(height: 20),
                      
                      // Address field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 450),
                        child: CustomTextField(
                          controller: _addressController,
                          label: 'address'.tr,
                          hint: 'hint_address'.tr,
                          prefixIcon: Ionicons.home_outline,
                          keyboardType: TextInputType.streetAddress,
                          validator: _validateRequired,
                          maxLines: 3,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Blood Information Section
                      _buildSectionHeader('blood_information'.tr),
                      const SizedBox(height: 20),
                      
                      // Blood type dropdown
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: CustomDropdown<String>(
                          label: 'blood_type'.tr,
                          hint: 'hint_select_blood'.tr,
                          value: _selectedBloodType,
                          items: _bloodTypes.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedBloodType = value),
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Registration Reason dropdown
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: CustomDropdown<String>(
                          label: 'registration_reason'.tr,
                          hint: 'hint_select_reason'.tr,
                          value: _selectedReason,
                          items: _reasons.map((reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(reason.tr),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedReason = value),
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Account Security Section
                      _buildSectionHeader('account_security'.tr),
                      const SizedBox(height: 20),
                      
                      // Password field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                        child: CustomTextField(
                          controller: _passwordController,
                          label: 'password'.tr,
                          hint: 'hint_password'.tr,
                          prefixIcon: Ionicons.lock_closed_outline,
                          obscureText: true,
                          validator: _validatePassword,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Confirm password field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 800),
                        child: CustomTextField(
                          controller: _confirmPasswordController,
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
                        delay: const Duration(milliseconds: 900),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                              activeColor: ColorPages.COLOR_PRINCIPAL,
                            ),
                            Expanded(
                              child: Text(
                                'terms_and_conditions_acceptance'.tr,
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
              
              // Register button (Inscription)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 1000),
                  child: CustomButton(
                    text: 'register'.tr, // Fallback text if child is not rendered
                    onPressed: _isLoading ? null : () {
                      print('👆 Inscription button pressed');
                      _handleRegistration();
                    },
                    isLoading: _isLoading,
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    height: 60, // Make the button taller
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Ionicons.person_add_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'register'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
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
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    // Calculate the maximum allowed date (exactly 16 years ago from today)
    final DateTime maxDate = DateTime(now.year - 16, now.month, now.day);
    // Use the maxDate or previously selected date, but ensure it's not after maxDate
    final DateTime initialDate = (_selectedDate != null && _selectedDate!.isBefore(maxDate)) 
        ? _selectedDate! 
        : maxDate;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920, 1),
      lastDate: maxDate, // Restrict to max 16 years ago (no future dates or recent dates)
      helpText: 'select_date_of_birth'.tr,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: ColorPages.COLOR_PRINCIPAL,
            colorScheme: ColorScheme.light(
              primary: ColorPages.COLOR_PRINCIPAL,
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        
        // Format the date based on the current language
        String locale = Get.locale?.toString() ?? 'en_US';
        if (locale.startsWith('fr')) {
          // French format: DD/MM/YYYY
          _dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        } else if (locale.startsWith('es')) {
          // Spanish format: DD/MM/YYYY
          _dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        } else if (locale.startsWith('ar')) {
          // Arabic format: DD/MM/YYYY (right-to-left)
          _dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        } else {
          // Default format (English, etc.): YYYY-MM-DD
          _dateOfBirthController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        }
      });
    }
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
    if (value != _passwordController.text) {
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
        // and we know they're done with the prefix part
        return 'invalid_phone_prefix'.tr;
      }
    }
    
    // Only check length if the prefix is valid and the user has entered a substantial part of the number
    // We don't want to show length errors while the user is still typing
    if (_hasValidPrefix(value) && value.length > 5 && value.length < 9) {
      // Show a warning only if they've entered most of the number but it's still too short
      return 'invalid_phone_length'.tr;
    } else if (value.length > 15) {
      // Phone numbers are rarely longer than 15 digits including prefix
      return 'invalid_phone_length'.tr;
    }
    
    return null;
  }
  
  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'date_of_birth_required'.tr;
    }
    
    DateTime? date;
    String locale = Get.locale?.toString() ?? 'en_US';
    
    try {
      if (locale.startsWith('fr') || locale.startsWith('es') || locale.startsWith('ar')) {
        // Parse DD/MM/YYYY format
        final parts = value.split('/');
        if (parts.length != 3) {
          return 'invalid_date_format'.tr;
        }
        
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        // Validate date components
        if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1920) {
          return 'invalid_date'.tr;
        }
        
        date = DateTime(year, month, day);
      } else {
        // Parse YYYY-MM-DD format
        final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        if (!datePattern.hasMatch(value)) {
          return 'invalid_date_format'.tr;
        }
        
        // Parse the date
        date = DateTime.parse(value);
      }
      
      // Validate age (minimum 16 years)
      final now = DateTime.now();
      final minimumAge = DateTime(now.year - 16, now.month, now.day);
      
      // Check if date is after minimumAge (meaning user is less than 16 years old)
      if (date.isAfter(minimumAge)) {
        return 'minimum_age_requirement'.tr;
      }
      
      // Check if date is realistic (not too old)
      final maxAge = DateTime(1920, 1, 1);
      if (date.isBefore(maxAge)) {
        return 'invalid_date'.tr;
      }
    } catch (e) {
      return 'invalid_date'.tr;
    }
    
    return null;
  }

  // Variable to store normalized date outside of the method
  String _getNormalizedDateForAPI() {
    // Create a normalized date for API but don't change the display value
    String apiDateOfBirth = _dateOfBirthController.text;
    String locale = Get.locale?.toString() ?? 'en_US';
    
    // Only normalize if not already in YYYY-MM-DD format
    if (locale.startsWith('fr') || locale.startsWith('es') || locale.startsWith('ar')) {
      try {
        // Convert from DD/MM/YYYY to YYYY-MM-DD for API
        final parts = _dateOfBirthController.text.split('/');
        if (parts.length == 3) {
          apiDateOfBirth = "${parts[2]}-${parts[1]}-${parts[0]}";
          print('📅 Normalized date format for API: $apiDateOfBirth');
        }
      } catch (e) {
        print('⚠️ Error normalizing date: $e');
      }
    }
    
    return apiDateOfBirth;
  }
  
  void _handleRegistration() async {
    final bool isGoogle = widget.extra?['registration_mode'] == 'google';
    if (isGoogle) {
      // Minimal validation for google: ensure first/last name & location, account type personal by default
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('name_required'.tr), backgroundColor: Colors.red));
        return;
      }
      if (!_selectedLocation.containsKey('id')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('select_valid_location'.tr), backgroundColor: Colors.red));
        return;
      }
      setState(() => _isLoading = true);
      try {
        final authService = AuthService();
        final payload = {
          'first_name': _firstNameController.text,
            'last_name': _lastNameController.text,
            'email': _emailController.text,
            'account_type': 'personal',
            'ref_entity_id': _selectedLocation['id'],
            'registration_provider': 'google',
        };
        final result = await authService.googleRegister(payload);
        if (result['success'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('registration_success'.tr), backgroundColor: Colors.green));
          context.go('/app/MainApp');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'registration_failed'.tr), backgroundColor: Colors.red));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('registration_failed'.tr), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return; // Skip standard flow
    }
    print('🔍 Starting registration validation...');
    
    try {
      // Check form validation
      if (_formKey.currentState == null) {
        print('❌ Form key state is null');
        Get.snackbar(
          'Error',
          'Form validation error. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      final isValid = _formKey.currentState!.validate();
      print('📝 Form validation result: $isValid');
      
      if (!isValid) {
        return;
      }
      
      // Manually validate phone number since it's not part of the form
      if (_countryCode != null) {
        final String? phoneError = _validatePhone(_phoneController.text);
        if (phoneError != null) {
          print('❌ Phone validation failed: $phoneError');
          setState(() => _phoneError = phoneError);
          // Scroll to the phone field
          _scrollController.animateTo(
            _scrollController.position.pixels + 200, // approximate position
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return;
        }
      }

      // Check terms acceptance
      if (!_acceptTerms) {
        print('❌ Terms not accepted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('accept_terms_conditions'.tr),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Check if location is selected (we need an entity id)
      print('🌍 Selected location: $_selectedLocation');
      
      // Ensure we have an entity ID selected
      final bool hasValidEntityId = _selectedLocation.containsKey('id') && _selectedLocation['id']?.isNotEmpty == true;
                               
      if (!hasValidEntityId) {
        print('❌ Location entity ID not selected');
        // Use ScaffoldMessenger instead of Get.snackbar to avoid the null error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('select_valid_location'.tr),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      print('✅ All validation passed');
    } catch (e) {
      print('⚠️ Error during validation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form validation error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Create auth service instance
      final AuthService authService = AuthService();
      
      // Get the entity ID for the selected location
      final String refEntityId = _selectedLocation.containsKey('id') 
                          ? _selectedLocation['id']!
                          : '';
      
      // Prepare registration payload
      final Map<String, dynamic> payload = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'gender': _selectedGender,
        'email': _emailController.text,
        'phone_number': _countryCode! + _phoneController.text,
        'blood_type': _selectedBloodType,
        'registration_reason': _selectedReason,
        'address': _addressController.text,
        'date_of_birth': _getNormalizedDateForAPI(), // Use the normalized format for API submission
        'ref_entity_id': refEntityId,
        'password': _passwordController.text,
        'confirm_password': _confirmPasswordController.text,
        'account_type': 'personal'
      };
      
      // Log the payload for debugging
      print('Registration payload: $payload');
      
      // NEW FLOW: First validate the user info before proceeding with registration
      print('📤 Sending user info validation request...');
      
      // Get verification mode from widget extras (default to email if not specified)
      final String verificationMode = widget.extra?['verification_mode'] ?? 'email';
      print('🔍 Using verification mode: $verificationMode');
      
      // Create a UserInfoValidation object
      final userValidation = UserInfoValidation(
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        validationType: verificationMode, // Use the verification mode from extras
      );
      
      // Call the API to validate user info
      final validationResult = await authService.validateUserInfo(userValidation);
      print('📥 User info validation response: $validationResult');
      
      if (validationResult['success'] == true) {
        print('✅ User info validation successful, navigating to OTP verification');
        
        // Extract the validation key from the response
        final String? validationKey = validationResult['data']?['validation_key'];
        
        if (validationKey == null) {
          print('❌ No validation key found in response');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Missing validation data from server. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
        
        // Get verification mode from widget extras (default to email if not specified)
        final String verificationMode = widget.extra?['verification_mode'] ?? 'email';
        
        // Navigate to OTP verification page with the registration payload
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              phoneNumber: _phoneController.text,
              email: _emailController.text,
              userData: payload, // Pass the payload to complete registration after OTP verification
              validationKey: validationKey, // Pass the validation key required for verification
              verificationType: verificationMode, // Pass the verification mode
            ),
          ),
        );
      } else {
        print('❌ User info validation failed: ${validationResult['message']}');
        // Show error message
        final errorMsg = (validationResult['message'] as String?) ?? 'User info validation failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('⚠️ Registration error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
