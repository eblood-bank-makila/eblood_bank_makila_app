import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/widgets/network_status_widget.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/CustomDropdown.dart';
import '../../core/widgets/location_bottom_sheet_select.dart';
import '../models/SystemCountry.dart';
import '../services/LocationService.dart';
import '../services/AuthService.dart';
import '../config/theme/ColorPages.dart';
import '../models/UserInfoValidation.dart';
import 'OTPVerificationPage.dart';
import 'package:eblood_bank_mak_app/apps/models/registration_origin.dart';
import 'package:go_router/go_router.dart';

class PersonalRegistrationStepperPage extends StatefulWidget {
  final Map<String, dynamic>? extra;
  
  const PersonalRegistrationStepperPage({super.key, this.extra});

  @override
  State<PersonalRegistrationStepperPage> createState() => _PersonalRegistrationStepperPageState();
}

class _PersonalRegistrationStepperPageState extends State<PersonalRegistrationStepperPage> {
  int _currentStep = 0;
  final _personalFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _bloodFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  
  // Personal Information Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  
  // Contact Information Controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Account Information Controllers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Selected values
  String? _selectedGender;
  String? _selectedBloodType;
  String? _selectedReason;
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedBloodBank;

  // Blood bank data
  List<Map<String, dynamic>> _bloodBanks = [];
  bool _isLoadingBloodBanks = false;
  String? _bloodBankError;
  
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
  bool get _isGoogleMode => widget.extra?['registration_mode'] == 'google';
  String? get _googleIdToken => widget.extra?['google_id_token'] as String?;
  
  // Mock data
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
    
    _phoneController.addListener(() {
      if (_phoneController.text.isNotEmpty && _validPrefixes.isNotEmpty) {
        setState(() {
          _phoneError = _validatePhone(_phoneController.text);
        });
      }
    });
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
    } catch (e) {
      setState(() {
        _locationError = 'Failed to load location data: $e';
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _fetchNearbyBloodBanks() async {
    setState(() {
      _isLoadingBloodBanks = true;
      _bloodBankError = null;
    });

    try {
      // Get device location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      print('📍 Device location: ${position.latitude}, ${position.longitude}');

      // Fetch nearby blood banks
      final authService = AuthService();
      final result = await authService.getNearbyBloodBanks(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0,
        limit: 10,
      );

      if (result['success'] == true) {
        setState(() {
          _bloodBanks = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoadingBloodBanks = false;
        });
      } else {
        setState(() {
          _bloodBankError = result['message'] ?? 'Failed to fetch blood banks';
          _isLoadingBloodBanks = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching blood banks: $e');
      setState(() {
        _bloodBankError = 'Error: $e';
        _isLoadingBloodBanks = false;
      });
    }
  }

  void _onLocationSelected(Map<String, dynamic> location) {
    String? newCountryCode;
    List<String> newPrefixes = [];
    
    if (location.isNotEmpty) {
      _locationError = null;
      String? selectedType = location['type'];
      String? selectedCountryId;
      
      if (selectedType == 'country') {
        selectedCountryId = location['id'];
      } else if (selectedType == 'province') {
        selectedCountryId = location['country_id'] ?? location['system_country_id'];
      } else if (selectedType == 'town') {
        selectedCountryId = location['country_id'] ?? location['system_country_id'];
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
              if (selectedCountryId != null) break;
            }
          }
        }
      }
      
      if (selectedCountryId != null) {
        for (var country in _locationData) {
          if (country.id == selectedCountryId) {
            if (country.countryCodes != null && country.countryCodes!.isNotEmpty) {
              newCountryCode = country.countryCodes!.first.countryCode;
            }
            if (country.telephonePrefixes != null && country.telephonePrefixes!.isNotEmpty) {
              newPrefixes = country.telephonePrefixes!.map((p) => p.prefix).toList();
            }
            break;
          }
        }
      }
    }
    
    setState(() {
      _selectedLocation = location;
      _countryCode = newCountryCode;
      _validPrefixes = newPrefixes;
      _phoneError = null;
    });
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'field_required'.tr;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'email_required'.tr;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'invalid_email'.tr;
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
      return 'passwords_do_not_match'.tr;
    }
    return null;
  }



  String? _validatePhone(String value) {
    if (value.isEmpty) {
      return 'phone_required'.tr;
    }
    if (!_hasValidPrefix(value)) {
      return 'invalid_phone_prefix'.tr;
    }
    if (value.length < 7) {
      return 'phone_too_short'.tr;
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'date_of_birth_required'.tr;
    }
    return null;
  }

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

  /// Build the node key in the same format as LocationBottomSheetSelect
  String _buildNodeKey(Map<String, dynamic> location) {
    final type = location['type']?.toString().toLowerCase() ?? 'unknown';
    final id = location['id']?.toString() ?? '';
    return '$type-$id';
  }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('personal_account'.tr, style: const TextStyle(color: ColorPages.COLOR_BLANCHE)),
        centerTitle: false,
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ColorPages.COLOR_BLANCHE),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            onStepTapped: (step) => _validateAndNavigateToStep(step),
            steps: _buildSteps(),
            physics: const ClampingScrollPhysics(),
            controlsBuilder: (context, details) {
              // Last step is always 4 (account information)
              final lastStep = 4;
              final isSubmitStep = _currentStep == lastStep;
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
                          if (_isLoading && isSubmitStep)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(ColorPages.COLOR_BLANCHE),
                              ),
                            ),
                          if (_isLoading && isSubmitStep)
                            const SizedBox(width: 8),
                          Text(isSubmitStep ? 'submit'.tr : 'continue'.tr),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorPages.COLOR_PRINCIPAL,
                        side: const BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                      ),
                      child: Text(_currentStep == 0 ? 'annuler'.tr : 'back'.tr),
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
    // Always include all steps to avoid Stepper assertion error
    // The blood bank step is conditionally shown based on _selectedReason
    final steps = [
      Step(
        title: Text('personal_information'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 0,
        content: _buildPersonalStep(),
      ),
      Step(
        title: Text('contact_information'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 1,
        content: _buildContactStep(),
      ),
      Step(
        title: Text('blood_information'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 2,
        content: _buildBloodStep(),
      ),
      // Blood bank selection step - always included but only shown if blood_donor
      Step(
        title: Text('blood_bank_selection'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 3,
        content: _selectedReason == 'blood_donor'
          ? _buildBloodBankStep()
          : const SizedBox.shrink(), // Hide if not blood donor
        state: _selectedReason == 'blood_donor' ? StepState.complete : StepState.disabled,
      ),
      // Account information step
      Step(
        title: Text('account_information'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 4,
        content: _buildAccountStep(),
      ),
    ];

    return steps;
  }

  Widget _buildPersonalStep() {
    return Form(
      key: _personalFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _firstNameController,
                    label: 'first_name'.tr,
                    hint: 'hint_first_name'.tr,
                    prefixIcon: Ionicons.person_outline,
                    validator: _validateRequired,
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomDropdown<String>(
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
            const SizedBox(height: 16),
            GestureDetector(
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
          ],
        ),
      ),
    );
  }

  Widget _buildContactStep() {
    return Column(
      children: [
        if (_isLoadingLocations)
          const Center(child: CircularProgressIndicator())
        else if (_locationError != null)
          Text(_locationError!, style: const TextStyle(color: Colors.red))
        else
          Form(
            key: _contactFormKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LocationBottomSheetSelect(
                    locations: _locationData,
                    onLocationSelected: _onLocationSelected,
                    selectedLocationId: _selectedLocation.isNotEmpty
                        ? _buildNodeKey(_selectedLocation)
                        : null,
                    label: 'your_location'.tr,
                    hint: 'hint_select_location'.tr,
                    isRequired: true,
                    isLoading: _isLoadingLocations,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _emailController,
                        label: 'email'.tr,
                        hint: 'hint_email'.tr,
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
                  if (_selectedLocation.isNotEmpty && _countryCode != null)
                    _buildPhoneField(),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _addressController,
                    label: 'address'.tr,
                    hint: 'hint_address'.tr,
                    prefixIcon: Ionicons.home_outline,
                    validator: _validateRequired,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          child: Text(
            'phone_number'.tr,
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
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: _validPrefixes.isNotEmpty 
                      ? '${_validPrefixes.first} XXXXXXX'
                      : "XXXXXXXX",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: Icon(Ionicons.call_outline, color: Colors.grey[600], size: 20),
                    errorText: _phoneError,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    setState(() {
                      _phoneError = _validatePhone(value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBloodStep() {
    return Form(
      key: _bloodFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            CustomDropdown<String>(
              label: 'blood_type'.tr,
              hint: 'hint_select_blood_type'.tr,
              value: _selectedBloodType,
              items: _bloodTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              )).toList(),
              onChanged: (value) => setState(() => _selectedBloodType = value),
              validator: _validateRequired,
            ),
            const SizedBox(height: 16),
            CustomDropdown<String>(
              label: 'registration_reason'.tr,
              hint: 'hint_select_reason'.tr,
              value: _selectedReason,
              items: _reasons.map((reason) => DropdownMenuItem(
                value: reason,
                child: Text(reason.tr),
              )).toList(),
              onChanged: (value) {
                setState(() => _selectedReason = value);
                // Fetch blood banks if blood donor is selected
                if (value == 'blood_donor') {
                  _fetchNearbyBloodBanks();
                }
              },
              validator: _validateRequired,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodBankStep() {
    if (_isLoadingBloodBanks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bloodBankError != null) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(
              Ionicons.alert_circle_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _bloodBankError!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNearbyBloodBanks,
              child: Text('retry'.tr),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    if (_bloodBanks.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(
              Ionicons.location_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'no_blood_banks_found'.tr,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'try_different_location'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Description header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorPages.COLOR_BLUE.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPages.COLOR_BLUE.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Ionicons.information_circle_outline,
                  color: ColorPages.COLOR_BLUE,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'select_blood_bank'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_BLUE,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'select_blood_bank_description'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorPages.COLOR_BLUE.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Blood banks list
          ..._bloodBanks.map((bank) {
            final isSelected = _selectedBloodBank?['id'] == bank['id'] ||
                _selectedBloodBank?['sys_id'] == bank['sys_id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedBloodBank = bank),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected ? ColorPages.COLOR_BLUE.withValues(alpha: 0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? ColorPages.COLOR_BLUE : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bank['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (bank['address'] != null)
                              Text(
                                bank['address'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (bank['distance_km'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${(bank['distance_km'] as num).toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Ionicons.checkmark_circle,
                          color: ColorPages.COLOR_BLUE,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    return Form(
      key: _accountFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (!_isGoogleMode) ...[
              CustomTextField(
                controller: _passwordController,
                label: 'password'.tr,
                hint: 'hint_password'.tr,
                prefixIcon: Ionicons.lock_closed_outline,
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'confirm_password'.tr,
                hint: 'hint_confirm_password'.tr,
                prefixIcon: Ionicons.lock_closed_outline,
                obscureText: true,
                validator: _validateConfirmPassword,
              ),
            ],
            const SizedBox(height: 24),
            // Terms and conditions checkbox
            Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                  activeColor: ColorPages.COLOR_PRINCIPAL,
                ),
                Expanded(
                  child: Text(
                    'terms_and_conditions_acceptance'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndNavigateToStep(int step) {
    if (step > _currentStep) {
      if (!_validateCurrentStep()) {
        return;
      }
    }
    setState(() => _currentStep = step);
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (!_personalFormKey.currentState!.validate()) {
          Get.snackbar('Error', 'please_fill_all_required_fields'.tr);
          return false;
        }
        return true;
      case 1:
        // Check if locations are still loading
        if (_isLoadingLocations) {
          Get.snackbar('Error', 'locations_loading'.tr);
          return false;
        }

        // Check if there was an error loading locations
        if (_locationError != null) {
          Get.snackbar('Error', _locationError!);
          return false;
        }

        // Validate form if it exists
        if (_contactFormKey.currentState != null && !_contactFormKey.currentState!.validate()) {
          Get.snackbar('Error', 'please_fill_all_required_fields'.tr);
          return false;
        }

        if (_selectedLocation.isEmpty) {
          Get.snackbar('Error', 'location_required'.tr);
          return false;
        }

        // Phone field is only shown if location and country code are selected
        if (_selectedLocation.isNotEmpty && _countryCode != null) {
          if (_phoneController.text.isEmpty) {
            Get.snackbar('Error', 'phone_required'.tr);
            return false;
          }

          if (_phoneError != null) {
            Get.snackbar('Error', _phoneError!);
            return false;
          }
        }

        return true;
      case 2:
        if (_selectedBloodType == null || _selectedReason == null) {
          Get.snackbar('Error', 'please_fill_all_required_fields'.tr);
          return false;
        }
        // If blood donor is selected, fetch blood banks for next step
        if (_selectedReason == 'blood_donor' && _bloodBanks.isEmpty && !_isLoadingBloodBanks) {
          _fetchNearbyBloodBanks();
        }
        return true;
      case 3:
        // This is the blood bank selection step (only for blood donors)
        if (_selectedReason == 'blood_donor') {
          // Only require blood bank selection if blood banks are available
          if (_bloodBanks.isNotEmpty && _selectedBloodBank == null) {
            Get.snackbar('Error', 'blood_bank_required'.tr);
            return false;
          }
          // If no blood banks are available, allow proceeding without selection
          return true;
        }
        // If not blood donor, this step should not be reached
        return true;
      case 4:
        // This is the account information step
        if (!_isGoogleMode && !_accountFormKey.currentState!.validate()) {
          Get.snackbar('Error', 'please_fill_all_required_fields'.tr);
          return false;
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

    // Last step is always 4 (account information)
    const lastStep = 4;

    if (_currentStep < lastStep) {
      // If not blood donor, skip the blood bank step (step 3)
      if (_currentStep == 2 && _selectedReason != 'blood_donor') {
        setState(() => _currentStep = 4); // Jump to account step
      } else {
        setState(() => _currentStep += 1);
      }
    } else {
      _handleRegistration();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.of(context).pop();
    }
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
      lastDate: maxDate,
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

  // Helper method to normalize date to YYYY-MM-DD format for API
  String _getNormalizedDateForAPI() {
    String apiDateOfBirth = _dateOfBirthController.text;
    String locale = Get.locale?.toString() ?? 'en_US';

    // Only normalize if not already in YYYY-MM-DD format
    if (locale.startsWith('fr') || locale.startsWith('es') || locale.startsWith('ar')) {
      try {
        // Convert from DD/MM/YYYY to YYYY-MM-DD for API
        final parts = _dateOfBirthController.text.split('/');
        if (parts.length == 3) {
          // Ensure day and month are padded with leading zeros
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          final year = parts[2];
          apiDateOfBirth = "$year-$month-$day";
          print('📅 Normalized date format for API: $apiDateOfBirth');
        }
      } catch (e) {
        print('⚠️ Error normalizing date: $e');
      }
    }

    return apiDateOfBirth;
  }

  Future<void> _handleRegistration() async {
    if (!_personalFormKey.currentState!.validate() ||
        !_contactFormKey.currentState!.validate() ||
        !_bloodFormKey.currentState!.validate() ||
        (!_isGoogleMode && !_accountFormKey.currentState!.validate())) {
      Get.snackbar('Error', 'please_fill_all_required_fields'.tr);
      return;
    }

    // Check terms acceptance
    if (!_acceptTerms) {
      print('❌ Terms not accepted');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('accept_terms_conditions'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('select_valid_location'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
  // Determine verification mode and derive registration origin enum
  final String verificationMode = widget.extra?['verification_mode'] ?? (_isGoogleMode ? 'none' : 'email');

      final Map<String, dynamic> payload = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'gender': _selectedGender,
        'date_of_birth': _getNormalizedDateForAPI(),
        'email': _emailController.text,
        'phone_number': _countryCode! + _phoneController.text,
        'address': _addressController.text,
        'ref_entity_id': _selectedLocation['id'],
        'blood_type': _selectedBloodType,
        'registration_reason': _selectedReason,
    if (!_isGoogleMode) 'password': _passwordController.text,
    if (!_isGoogleMode) 'confirm_password': _confirmPasswordController.text,
    'account_type': 'personal',
    'registration_origin': _isGoogleMode ? ERegistrationOrigin.google.value : registrationOriginFromVerificationMode(verificationMode).value,
      };

      // Add blood bank ID if blood donor
      if (_selectedReason == 'blood_donor' && _selectedBloodBank != null) {
        payload['sys_health_structure_id'] =
            _selectedBloodBank!['id'] ?? _selectedBloodBank!['sys_id'];
      }

      print('Registration payload: $payload');

      final authService = AuthService();

      if (_isGoogleMode) {
        // Direct Google registration: include ID token and skip OTP
        payload['google_id_token'] = _googleIdToken;
        print('📤 Registering via Google with payload: $payload');
        final result = await authService.googleRegister(payload);
        print('� Google registration response: $result');
        if (result['success'] == true) {
          // Handle auto-login response - same as OTP validation success
          await authService.handleAutoLoginAfterRegistration(result);

          if (mounted) {
            // Auto-login: go straight to the main app
            context.go('/app/MainApp');
          }
        } else {
          final msg = (result['message'] as String?) ?? 'Registration failed';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        // Email/OTP flow
        print('📤 Sending user info validation request...');
        print('🔍 Using verification mode: $verificationMode');

        final userValidation = UserInfoValidation(
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          validationType: verificationMode,
        );

        final validationResult = await authService.validateUserInfo(userValidation);
        print('📥 User info validation response: $validationResult');

        if (validationResult['success'] == true) {
          print('✅ User info validation successful, navigating to OTP verification');
          final String? validationKey = validationResult['data']?['validation_key'];
          if (validationKey == null) {
            print('❌ No validation key found in response');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Missing validation data from server. Please try again.'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            return;
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationPage(
                  phoneNumber: _phoneController.text,
                  email: _emailController.text,
                  userData: payload,
                  validationKey: validationKey,
                  verificationType: verificationMode,
                ),
              ),
            );
          }
        } else {
          print('❌ User info validation failed: ${validationResult['message']}');
          final errorMsg = (validationResult['message'] as String?) ?? 'User info validation failed. Please try again.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('⚠️ Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

