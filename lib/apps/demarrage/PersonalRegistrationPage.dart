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
  Map<String, String> _selectedLocation = {};
  List<SystemCountry> _locationData = [];
  bool _isLoadingLocations = false;
  String? _locationError;
  final LocationService _locationService = LocationService();
  
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

  void _onLocationSelected(Map<String, String> location) {
    setState(() {
      _selectedLocation = location;
      
      // Clear location error if location is selected
      if (location.isNotEmpty) {
        _locationError = null;
      }
    });
    
    // Debug log selected location
    if (location.isNotEmpty) {
      print('Selected location: ${location['type']} - ${location['town_name'] ?? location['province_name'] ?? location['country_name']}');
      print('Selected location id (ref_entity_id): ${location['id']}');
    } else {
      print('Location selection cleared');
    }
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
                      
                      // Email field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: CustomTextField(
                          controller: _emailController,
                          label: 'email'.tr,
                          hint: 'hint_email'.tr,
                          prefixIcon: Ionicons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Phone field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: CustomTextField(
                          controller: _phoneController,
                          label: 'phone_number'.tr,
                          hint: 'hint_phone'.tr,
                          prefixIcon: Ionicons.call_outline,
                          keyboardType: TextInputType.phone,
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      

                      
                      // Location dropdown (country, province, town)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
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
        'phone_number': _phoneController.text,
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
