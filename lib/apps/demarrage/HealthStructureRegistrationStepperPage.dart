import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Removed unused UI imports
import 'package:ionicons/ionicons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/network_manager.dart';
import '../../core/widgets/network_status_widget.dart';
import '../config/theme/ColorPages.dart';
import 'HealthStructureEmailVerificationPage.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/CustomDropdown.dart';
import '../../core/widgets/location_bottom_sheet_select.dart';
import '../models/SystemCountry.dart';
import '../services/LocationService.dart';
import '../services/AuthService.dart';
import 'package:eblood_bank_mak_app/apps/models/registration_origin.dart';

// Health Structure Type Enum
enum HealthStructureType {
  BLOOD_BANK("blood_bank", "blood_bank", Icons.bloodtype_outlined),
  GENERAL_HOSPITAL(
    "general_hospital",
    "general_hospital",
    Icons.local_hospital_outlined,
  ),
  CLINIC("clinic", "clinic", Icons.medical_services_outlined),
  PHARMACY("pharmacy", "pharmacy", Icons.local_pharmacy_outlined),
  HEALTH_CENTER(
    "health_center",
    "health_center",
    Icons.health_and_safety_outlined,
  ),
  MATERNITY("maternity", "maternity", Icons.pregnant_woman_outlined),
  MEDICAL_LAB("medical_lab", "medical_lab", Icons.science_outlined),
  REHABILITATION_CENTER(
    "rehabilitation_center",
    "rehabilitation_center",
    Icons.accessible_outlined,
  ),
  HEALTH_CARE_CENTER(
    "health_care_center",
    "health_care_center",
    Icons.healing_outlined,
  ),
  MENTAL_HEALTH_CENTER(
    "mental_health_center",
    "mental_health_center",
    Icons.psychology_outlined,
  ),
  RETIREMENT_HOME("retirement_home", "retirement_home", Icons.elderly_outlined),
  EMERGENCY_CENTER(
    "emergency_center",
    "emergency_center",
    Icons.emergency_outlined,
  ),
  UNIVERSITY_HOSPITAL(
    "university_hospital",
    "university_hospital",
    Icons.school_outlined,
  ),
  PRIVATE_PRACTICE(
    "private_practice",
    "private_practice",
    Icons.person_outlined,
  );

  final String value;
  final String label;
  final IconData icon;

  const HealthStructureType(this.value, this.label, this.icon);

  String getTranslatedLabel() {
    return label.toLowerCase().tr;
  }
}

class HealthStructureRegistrationStepperPage extends StatefulWidget {
  const HealthStructureRegistrationStepperPage({super.key, this.extra});

  final Map<String, dynamic>? extra;

  @override
  State<HealthStructureRegistrationStepperPage> createState() =>
      _HealthStructureRegistrationStepperPageState();
}

class _HealthStructureRegistrationStepperPageState
    extends State<HealthStructureRegistrationStepperPage> {
  int _currentStep = 0;
  final _structureFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();

  // Structure Information Controllers
  final _structureNameController = TextEditingController();
  final _structureEmailController = TextEditingController();
  final _structurePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();

  // Admin Account Controllers
  final _adminFirstNameController = TextEditingController();
  final _adminLastNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();

  // Location data
  Map<String, dynamic> _selectedLocation = {};
  List<SystemCountry> _locationData = [];
  bool _isLoadingLocations = false;
  String? _locationError;
  final LocationService _locationService = LocationService();

  // Phone formatting
  String? _countryCode;
  List<String> _validPrefixes = [];
  String? _structurePhoneError;
  String? _adminPhoneError;

  // Selected values
  String? _adminGender;
  HealthStructureType? _selectedHealthStructureType;

  // Loading state
  bool _isLoading = false;
  bool get _isGoogleMode => widget.extra?['registration_mode'] == 'google';
  Map<String, dynamic>? get _googleData => widget.extra?['google_user'];
  String? get _googleIdToken => widget.extra?['google_id_token'] as String?;

  final List<String> _genders = ['male', 'female'];

  @override
  void initState() {
    super.initState();
    _fetchLocationData();
    NetworkManager().initialize(skipInitialCheck: true);

    _structurePhoneController.addListener(() {
      if (_structurePhoneController.text.isNotEmpty &&
          _validPrefixes.isNotEmpty) {
        setState(() {
          _structurePhoneError = _validatePhone(_structurePhoneController.text);
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

    if (_isGoogleMode) {
      final g = _googleData ?? {};
      final email = g['email']?.toString() ?? '';
      final displayName = g['displayName']?.toString() ?? '';
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
      _adminEmailController.text = email;
      _adminFirstNameController.text = firstName;
      _adminLastNameController.text = lastName;
    }
  }

  @override
  void dispose() {
    _structureNameController.dispose();
    _structureEmailController.dispose();
    _structurePhoneController.dispose();
    _addressController.dispose();
    _longitudeController.dispose();
    _latitudeController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationData() async {
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });

    try {
      final response = await _locationService.fetchLocationData();
      setState(() {
        _locationData = response.data;
        _isLoadingLocations = false;
      });
      NetworkManager().markBackendAsAvailable();
    } catch (e) {
      setState(() {
        _locationError = 'Failed to load location data: $e';
        _isLoadingLocations = false;
      });
    }
  }

  void _onLocationSelected(Map<String, dynamic> location) {
    String? newCountryCode;
    List<String> newPrefixes = [];

    if (location.isNotEmpty) {
      String? selectedType = location['type'];
      String? selectedCountryId;

      if (selectedType == 'country') {
        selectedCountryId = location['id'];
      } else if (selectedType == 'province') {
        selectedCountryId =
            location['country_id'] ?? location['system_country_id'];
      } else if (selectedType == 'town') {
        selectedCountryId =
            location['country_id'] ?? location['system_country_id'];
        if (selectedCountryId == null) {
          String? provinceId = location['province_id'] ?? location['parent_id'];
          if (provinceId != null) {
            for (var country in _locationData) {
              for (var province in country.children) {
                if (province.id == provinceId) {
                  selectedCountryId = country.id;
                  break;
                }
              }
            }
          }
        }
      }

      if (selectedCountryId != null) {
        for (var country in _locationData) {
          if (country.id == selectedCountryId) {
            newCountryCode = country.countryCodes?.isNotEmpty == true
                ? country.countryCodes!.first.countryCode
                : null;
            newPrefixes =
                country.telephonePrefixes?.map((p) => p.prefix).toList() ?? [];
            break;
          }
        }
      }
    }

    setState(() {
      _selectedLocation = location;
      _locationError = null;
      _countryCode = newCountryCode;
      _validPrefixes = newPrefixes;
    });
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'field_required'.tr;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'email_required'.tr;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'invalid_email'.tr;
    }
    return null;
  }

  String? _validatePhone(String value) {
    if (value.isEmpty) {
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'password_required'.tr;
    if (value.length < 8) return 'password_min_length'.tr;
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _adminPasswordController.text) {
      return 'passwords_do_not_match'.tr;
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.isEmpty) return null;
    final lon = double.tryParse(value);
    if (lon == null || lon < -180 || lon > 180) {
      return 'invalid_longitude'.tr;
    }
    return null;
  }

  String? _validateLatitude(String? value) {
    if (value == null || value.isEmpty) return null;
    final lat = double.tryParse(value);
    if (lat == null || lat < -90 || lat > 90) {
      return 'invalid_latitude'.tr;
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to get location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'health_structure_registration'.tr,
          style: const TextStyle(color: ColorPages.COLOR_BLANCHE),
        ),
        centerTitle: false,
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: ColorPages.COLOR_BLANCHE,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: ColorPages.COLOR_PRINCIPAL),
          ),
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            onStepTapped: (step) => _validateAndNavigateToStep(step),
            steps: _buildSteps(),
            physics: const ClampingScrollPhysics(),
            controlsBuilder: (context, details) {
              final isSubmit = _currentStep == 3;
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPages.COLOR_PRINCIPAL,
                        foregroundColor: ColorPages.COLOR_BLANCHE,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading && isSubmit)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorPages.COLOR_BLANCHE,
                                ),
                              ),
                            ),
                          if (_isLoading && isSubmit)
                            const SizedBox(width: 8),
                          Text(isSubmit ? 'submit'.tr : 'continue'.tr),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorPages.COLOR_PRINCIPAL,
                        side: const BorderSide(
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                      child: Text(
                        _currentStep == 0 ? 'annuler'.tr : 'back'.tr,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: Text(
          'location_information'.tr,
          style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL),
        ),
        isActive: _currentStep >= 0,
        content: _buildLocationStep(),
      ),
      Step(
        title: Text(
          'health_structure_type'.tr,
          style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL),
        ),
        isActive: _currentStep >= 1,
        content: _buildTypeStep(),
      ),
      Step(
        title: Text(
          'structure_information'.tr,
          style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL),
        ),
        isActive: _currentStep >= 2,
        content: _buildStructureStep(),
      ),
      Step(
        title: Text(
          'admin_account_information'.tr,
          style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL),
        ),
        isActive: _currentStep >= 3,
        content: _buildAdminStep(),
      ),
    ];
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        if (_isLoadingLocations)
          const Center(child: CircularProgressIndicator())
        else if (_locationError != null)
          Text(_locationError!, style: const TextStyle(color: Colors.red))
        else
          LocationBottomSheetSelect(
            locations: _locationData,
            onLocationSelected: _onLocationSelected,
            selectedLocationId: _selectedLocation.isNotEmpty
                ? _buildNodeKey(_selectedLocation)
                : null,
            label: 'location'.tr,
            hint: 'select_location'.tr,
            isRequired: true,
            isLoading: _isLoadingLocations,
          ),
      ],
    );
  }

  /// Build the node key in the same format as LocationTreeSelect
  String _buildNodeKey(Map<String, dynamic> location) {
    final type = location['type']?.toString().toLowerCase() ?? 'unknown';
    final id = location['id']?.toString() ?? '';
    return '$type-$id';
  }

  Widget _buildTypeStep() {
    return Column(
      children: [
        Text('select_health_structure_type'.tr),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HealthStructureType.values.map((type) {
            final isSelected = _selectedHealthStructureType == type;
            return FilterChip(
              label: Text(type.getTranslatedLabel()),
              selected: isSelected,
              onSelected: (selected) {
                setState(
                  () => _selectedHealthStructureType = selected ? type : null,
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStructureStep() {
    return Form(
      key: _structureFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            CustomTextField(
              controller: _structureNameController,
              label: 'structure_name'.tr,
              hint: 'hint_structure_name'.tr,
              prefixIcon: Ionicons.medical_outline,
              validator: _validateRequired,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _structureEmailController,
                  label: 'email'.tr,
                  hint: 'hint_structure_email'.tr,
                  prefixIcon: Ionicons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isGoogleMode,
                  validator: _isGoogleMode ? null : _validateEmail,
                ),
                if (_isGoogleMode)
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
            const SizedBox(height: 16),
            // Phone field - Always shown in structure information step
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'structure_phone'.tr,
                    style: const TextStyle(
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
                            if (_selectedLocation.isNotEmpty &&
                                _selectedLocation['country_flag'] != null)
                              Text(
                                _selectedLocation['country_flag'],
                                style: const TextStyle(fontSize: 20),
                              ),
                            const SizedBox(width: 5),
                            Text(
                              _countryCode ?? '+XXX',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _structurePhoneController,
                          decoration: InputDecoration(
                            hintText: _validPrefixes.isNotEmpty
                                ? '${_validPrefixes.first} XXXXXXX'
                                : "XXXXXXXX",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Ionicons.call_outline,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            errorText: _structurePhoneError,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            CustomTextField(
              controller: _addressController,
              label: 'address'.tr,
              hint: 'hint_structure_address'.tr,
              prefixIcon: Ionicons.location_outline,
              validator: _validateRequired,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _longitudeController,
                    label: 'longitude'.tr,
                    hint: 'hint_longitude'.tr,
                    prefixIcon: Ionicons.navigate_outline,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateLongitude,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _latitudeController,
                    label: 'latitude'.tr,
                    hint: 'hint_latitude'.tr,
                    prefixIcon: Ionicons.navigate_outline,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateLatitude,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _getCurrentLocation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Ionicons.location_outline),
              label: Text(
                _isLoading
                    ? 'obtaining_location'.tr
                    : 'use_current_location'.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStep() {
    return Form(
      key: _adminFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _adminFirstNameController,
                    label: 'first_name'.tr,
                    hint: 'hint_first_name'.tr,
                    prefixIcon: Ionicons.person_outline,
                    validator: _validateRequired,
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomDropdown<String>(
              label: 'gender'.tr,
              hint: 'hint_select_gender'.tr,
              value: _adminGender,
              items: _genders
                  .map(
                    (gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender.tr)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _adminGender = value),
              validator: _validateRequired,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _adminEmailController,
                  label: 'email'.tr,
                  hint: 'hint_admin_email'.tr,
                  prefixIcon: Ionicons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isGoogleMode,
                  validator: _isGoogleMode ? null : _validateEmail,
                ),
                if (_isGoogleMode)
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
            const SizedBox(height: 16),
            // Admin phone field - Only shown when location is selected
            if (_selectedLocation.isNotEmpty && _countryCode != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      'admin_phone'.tr,
                      style: const TextStyle(
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
                              if (_selectedLocation['country_flag'] != null)
                                Text(
                                  _selectedLocation['country_flag'],
                                  style: const TextStyle(fontSize: 20),
                                ),
                              const SizedBox(width: 5),
                              Text(
                                _countryCode ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _adminPhoneController,
                            decoration: InputDecoration(
                              hintText: _validPrefixes.isNotEmpty
                                  ? '${_validPrefixes.first} XXXXXXX'
                                  : "XXXXXXXX",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(
                                Ionicons.call_outline,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              errorText: _adminPhoneError,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (!_isGoogleMode) ...[
              CustomTextField(
                controller: _adminPasswordController,
                label: 'password'.tr,
                hint: 'hint_password'.tr,
                prefixIcon: Ionicons.lock_closed_outline,
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _adminConfirmPasswordController,
                label: 'confirm_password'.tr,
                hint: 'hint_confirm_password'.tr,
                prefixIcon: Ionicons.lock_closed_outline,
                obscureText: true,
                validator: _validateConfirmPassword,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _validateAndNavigateToStep(int step) {
    // Only allow navigation if current step is valid
    if (step > _currentStep) {
      // Moving forward - validate current step
      if (!_validateCurrentStep()) {
        return;
      }
    }
    // Allow backward navigation without validation
    setState(() => _currentStep = step);
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Location step
        if (_selectedLocation.isEmpty) {
          Get.snackbar('Error', 'location_required'.tr);
          return false;
        }
        return true;
      case 1: // Health structure type step
        if (_selectedHealthStructureType == null) {
          Get.snackbar('Error', 'health_structure_type_required'.tr);
          return false;
        }
        return true;
      case 2: // Structure information step
        if (!_structureFormKey.currentState!.validate()) {
          Get.snackbar('Error', 'please_fill_all_required_fields'.tr);
          return false;
        }
        // Phone field is always required
        if (_structurePhoneController.text.isEmpty) {
          Get.snackbar('Error', 'phone_required'.tr);
          return false;
        }
        if (_structurePhoneError != null) {
          Get.snackbar('Error', _structurePhoneError!);
          return false;
        }
        return true;
      case 3: // Admin account step
        if (!_adminFormKey.currentState!.validate()) {
          Get.snackbar('Error', 'please_fill_all_required_fields'.tr);
          return false;
        }
        // Phone field is only shown if location and country code are selected
        if (_selectedLocation.isNotEmpty && _countryCode != null) {
          if (_adminPhoneController.text.isEmpty) {
            Get.snackbar('Error', 'phone_required'.tr);
            return false;
          }
          if (_adminPhoneError != null) {
            Get.snackbar('Error', _adminPhoneError!);
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  void _onStepContinue() {
    if (!_validateCurrentStep()) {
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      _handleRegistration();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      // Exit registration on first step cancel
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleRegistration() async {
    // Validate all steps
    if (_selectedLocation.isEmpty) {
      Get.snackbar('Error', 'Please select a location');
      return;
    }
    if (_selectedHealthStructureType == null) {
      Get.snackbar('Error', 'Please select a health structure type');
      return;
    }
    if (!_structureFormKey.currentState!.validate() ||
        (!_isGoogleMode && !_adminFormKey.currentState!.validate())) {
      Get.snackbar('Error', 'Please fill all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build phone numbers with country code
      final String structurePhone =
          (_countryCode != null && _countryCode!.isNotEmpty)
          ? _countryCode! + _structurePhoneController.text
          : _structurePhoneController.text;
      final String adminPhone =
          (_countryCode != null && _countryCode!.isNotEmpty)
          ? _countryCode! + _adminPhoneController.text
          : _adminPhoneController.text;

      final Map<String, dynamic> payload = {
        'health_structure_name': _structureNameController.text,
        'email': _structureEmailController.text,
        'phone_number': structurePhone,
        'address': _addressController.text,
        'location_id': _selectedLocation['id'],
        'health_structure_type_flag': _selectedHealthStructureType!.value,
        'latitude': _latitudeController.text.isNotEmpty
            ? double.parse(_latitudeController.text)
            : null,
        'longitude': _longitudeController.text.isNotEmpty
            ? double.parse(_longitudeController.text)
            : null,
        'registration_origin': _isGoogleMode
            ? ERegistrationOrigin.google.value
            : registrationOriginFromVerificationMode(
                widget.extra?['verification_mode'] ?? 'email',
              ).value,
        'account_type': 'health_structure',
        'admin_account': {
          'first_name': _adminFirstNameController.text,
          'last_name': _adminLastNameController.text,
          'email': _adminEmailController.text,
          'phone': adminPhone,
          'username': _adminEmailController.text.trim(),
          if (!_isGoogleMode) 'password': _adminPasswordController.text,
          'gender': _adminGender,
        },
      };

      final Set<String> emailSet = {};
      if (_structureEmailController.text.trim().isNotEmpty)
        emailSet.add(_structureEmailController.text.trim());
      if (_adminEmailController.text.trim().isNotEmpty)
        emailSet.add(_adminEmailController.text.trim());
      final emails = emailSet.toList();

      if (emails.isEmpty) {
        Get.snackbar('Error', 'email_required'.tr);
        return;
      }

      if (_isGoogleMode) {
        // Direct Google registration for health structure
        payload['google_id_token'] = _googleIdToken;
        final auth = AuthService();
        final result = await auth.googleRegister(payload);
        if (result['success'] == true) {
          // Handle auto-login response - same as OTP validation success
          await auth.handleAutoLoginAfterRegistration(result);

          if (mounted) {
            // Navigate through RBAC loading
            // ignore: use_build_context_synchronously
            context.go('/rbac-loading');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message']?.toString() ?? 'Registration failed',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
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
      }
    } catch (e) {
      Get.snackbar('Error', 'registration_failed'.tr);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
