import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ionicons/ionicons.dart';
import '../config/theme/ColorPages.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/CustomDropdown.dart';
import '../widgets/CustomButton.dart';

class BloodBankRegistrationPage extends StatefulWidget {
  const BloodBankRegistrationPage({super.key});

  @override
  State<BloodBankRegistrationPage> createState() => _BloodBankRegistrationPageState();
}

class _BloodBankRegistrationPageState extends State<BloodBankRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Blood Bank Information Controllers
  final _bloodBankNameController = TextEditingController();
  final _bloodBankEmailController = TextEditingController();
  final _bloodBankPhoneController = TextEditingController();
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
  
  // Selected values
  String? _selectedCity;
  String? _contactGender;
  String? _adminGender;
  
  // Loading state
  bool _isLoading = false;
  bool _acceptTerms = false;
  
  // Mock data - in real app, this would come from API
  final List<String> _cities = ['Kinshasa', 'Lubumbashi', 'Goma', 'Mbuji-Mayi', 'Kisangani', 'Bukavu', 'Kananga'];
  final List<String> _genders = ['male', 'female', 'other'];

  @override
  void dispose() {
    _bloodBankNameController.dispose();
    _bloodBankEmailController.dispose();
    _bloodBankPhoneController.dispose();
    _addressController.dispose();
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
        title: Text(
          'blood_bank_account'.tr,
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
                      // Blood Bank Information Section
                      _buildSectionHeader('organization_information'.tr),
                      const SizedBox(height: 20),
                      
                      // Blood bank name
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: CustomTextField(
                          controller: _bloodBankNameController,
                          label: 'blood_bank_name'.tr,
                          hint: 'Enter blood bank name',
                          prefixIcon: Ionicons.water_outline,
                          validator: _validateRequired,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Blood bank email and phone
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _bloodBankEmailController,
                                label: 'email'.tr,
                                hint: 'Blood bank email',
                                prefixIcon: Ionicons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _bloodBankPhoneController,
                                label: 'phone_number'.tr,
                                hint: 'Blood bank phone',
                                prefixIcon: Ionicons.call_outline,
                                keyboardType: TextInputType.phone,
                                validator: _validateRequired,
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
                          hint: 'Enter blood bank address',
                          prefixIcon: Ionicons.location_outline,
                          validator: _validateRequired,
                          maxLines: 2,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // City dropdown
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: CustomDropdown<String>(
                          label: 'city'.tr,
                          hint: 'Select city',
                          value: _selectedCity,
                          items: _cities.map((city) => DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedCity = value),
                          validator: _validateRequired,
                        ),
                      ),
                      
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
                                hint: 'Enter longitude',
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
                                hint: 'Enter latitude',
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
                            foregroundColor: Colors.red[600],
                            side: BorderSide(color: Colors.red[600]!),
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
                                hint: 'Contact first name',
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
                                hint: 'Contact last name',
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
                          hint: 'Select gender',
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
                      
                      // Contact email and phone
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 800),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _contactEmailController,
                                label: 'email'.tr,
                                hint: 'Contact email',
                                prefixIcon: Ionicons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _contactPhoneController,
                                label: 'phone_number'.tr,
                                hint: 'Contact phone',
                                prefixIcon: Ionicons.call_outline,
                                keyboardType: TextInputType.phone,
                                validator: _validateRequired,
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
                                hint: 'Admin first name',
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
                                hint: 'Admin last name',
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
                          hint: 'Select admin gender',
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
                      
                      // Admin email and phone
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1100),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _adminEmailController,
                                label: 'email'.tr,
                                hint: 'Admin email',
                                prefixIcon: Ionicons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _adminPhoneController,
                                label: 'phone_number'.tr,
                                hint: 'Admin phone',
                                prefixIcon: Ionicons.call_outline,
                                keyboardType: TextInputType.phone,
                                validator: _validateRequired,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Admin username
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1200),
                        child: CustomTextField(
                          controller: _adminUsernameController,
                          label: 'username'.tr,
                          hint: 'Enter admin username',
                          prefixIcon: Ionicons.at_outline,
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Admin password
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1300),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _adminPasswordController,
                                label: 'password'.tr,
                                hint: 'Admin password',
                                prefixIcon: Ionicons.lock_closed_outline,
                                obscureText: true,
                                validator: _validatePassword,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _adminConfirmPasswordController,
                                label: 'confirm_password'.tr,
                                hint: 'Confirm password',
                                prefixIcon: Ionicons.lock_closed_outline,
                                obscureText: true,
                                validator: _validateConfirmPassword,
                              ),
                            ),
                          ],
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
                              activeColor: Colors.red[600],
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
                    text: 'register'.tr,
                    onPressed: _isLoading ? null : _handleRegistration,
                    isLoading: _isLoading,
                    backgroundColor: Colors.red[600]!,
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
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _adminPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _getCurrentLocation() {
    // TODO: Implement location service
    Get.snackbar(
      'Info',
      'Location service will be implemented',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_acceptTerms) {
      Get.snackbar(
        'Error',
        'Please accept the terms and conditions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement actual registration API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      Get.snackbar(
        'Success',
        'Blood bank registration successful! Please check your email for verification.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Navigate to success screen or login
      Get.offAllNamed('/welcome');
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Registration failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
