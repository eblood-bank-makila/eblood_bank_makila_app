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

class PersonalRegistrationPage extends StatefulWidget {
  const PersonalRegistrationPage({super.key});

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
  
  // Selected values
  String? _selectedGender;
  String? _selectedBloodType;
  String? _selectedCity;
  String? _selectedRole;
  
  // Loading state
  bool _isLoading = false;
  bool _acceptTerms = false;
  
  // Mock data - in real app, this would come from API
  final List<String> _genders = ['male', 'female', 'other'];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _cities = ['Kinshasa', 'Lubumbashi', 'Goma', 'Mbuji-Mayi', 'Kisangani', 'Bukavu', 'Kananga'];
  final List<String> _roles = ['donor', 'recipient', 'both'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                                hint: 'Enter your first name',
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
                                hint: 'Enter your last name',
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
                          hint: 'Select your gender',
                          value: _selectedGender,
                          items: _genders.map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender.tr),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedGender = value),
                          validator: _validateRequired,
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
                          hint: 'Enter your email address',
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
                          hint: 'Enter your phone number',
                          prefixIcon: Ionicons.call_outline,
                          keyboardType: TextInputType.phone,
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // City dropdown
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: CustomDropdown<String>(
                          label: 'city'.tr,
                          hint: 'Select your city',
                          value: _selectedCity,
                          items: _cities.map((city) => DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedCity = value),
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Blood Information Section
                      _buildSectionHeader('Blood Information'),
                      const SizedBox(height: 20),
                      
                      // Blood type dropdown
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: CustomDropdown<String>(
                          label: 'blood_type'.tr,
                          hint: 'Select your blood type',
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
                      
                      // Role dropdown
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: CustomDropdown<String>(
                          label: 'Role',
                          hint: 'Select your role',
                          value: _selectedRole,
                          items: _roles.map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.tr),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedRole = value),
                          validator: _validateRequired,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Account Security Section
                      _buildSectionHeader('Account Security'),
                      const SizedBox(height: 20),
                      
                      // Password field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                        child: CustomTextField(
                          controller: _passwordController,
                          label: 'password'.tr,
                          hint: 'Enter your password',
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
                          hint: 'Confirm your password',
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
                  delay: const Duration(milliseconds: 1000),
                  child: CustomButton(
                    text: 'register'.tr,
                    onPressed: _isLoading ? null : _handleRegistration,
                    isLoading: _isLoading,
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
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
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
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
        'Registration successful! Please check your email for verification.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Navigate to OTP verification or login screen
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
