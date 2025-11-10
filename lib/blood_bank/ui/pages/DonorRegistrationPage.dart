import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../controllers/donor_registration_controller.dart';

class DonorRegistrationPage extends ConsumerStatefulWidget {
  const DonorRegistrationPage({super.key});

  @override
  ConsumerState<DonorRegistrationPage> createState() => _DonorRegistrationPageState();
}

class _DonorRegistrationPageState extends ConsumerState<DonorRegistrationPage> {
  // Step tracking
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form data
  File? _donorPhoto;
  bool _faceOk = false;
  bool _faceChecking = false;
  String? _faceErrorKey;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactPhoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedBloodType;
  String? _selectedGender;
  bool _needsAccount = false;
  bool _isSubmitting = false;
  bool _submissionSuccessful = false;
  String _errorMessage = '';

  // Available blood types
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _dobController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'donor_registration'.tr,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // If we're on the first step or showing results, go back to previous page
            if (_currentStep == 0 || _submissionSuccessful) {
              Navigator.pop(context);
            } else {
              // Otherwise go back to previous step
              setState(() {
                _currentStep--;
              });
            }
          },
        ),
      ),
      body: _isSubmitting
          ? _buildLoadingState()
          : _submissionSuccessful
              ? _buildSuccessState()
              : _buildRegistrationStep(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildRegistrationStep() {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildFormStep();
      case 2:
        return _buildOverviewStep();
      default:
        return _buildPhotoStep();
    }
  }

  Widget _buildPhotoStep() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'donor_photo'.tr,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'take_clear_photo_instruction'.tr,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _donorPhoto == null
                ? Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.file(
                      _donorPhoto!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(height: 16),
            if (_faceChecking)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'analyzing_photo'.tr,
                    style: GoogleFonts.poppins(color: Colors.grey.shade700),
                  ),
                ],
              )
            else if (_faceErrorKey != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resolveFaceErrorMessage(_faceErrorKey!),
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_faceOk)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'photo_validated_continue'.tr,
                        style: GoogleFonts.poppins(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _takeDonorPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text('take_photo'.tr, style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => _takeDonorPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text('choose_photo'.tr, style: GoogleFonts.poppins()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'donor_information'.tr,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Personal Information
            _buildSectionTitle('personal_information'.tr),

            // First Name
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'first_name'.tr,
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.user),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'field_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'last_name'.tr,
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.user),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'field_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'phone'.tr,
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.call),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'phone_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email (optional)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'email_optional'.tr,
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.message),
              ),
            ),
            const SizedBox(height: 16),

            // Gender Selection
            _buildSectionTitle('gender'.tr),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('male'.tr, style: GoogleFonts.poppins()),
                    value: 'M',
                    groupValue: _selectedGender,
                    activeColor: Colors.red,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('female'.tr, style: GoogleFonts.poppins()),
                    value: 'F',
                    groupValue: _selectedGender,
                    activeColor: Colors.red,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Blood Type Dropdown
            _buildSectionTitle('blood_type'.tr),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.bloodtype),
              ),
              value: _selectedBloodType,
              items: _bloodTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBloodType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'hint_select_blood'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth
            TextFormField(
              controller: _dobController,
              decoration: InputDecoration(
                labelText: 'date_of_birth'.tr,
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.calendar),
                hintText: 'YYYY-MM-DD',
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'date_of_birth_required'.tr;
                }
                // Validate date format
                final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                if (!datePattern.hasMatch(value)) {
                  return 'invalid_date_format_yyyy_mm_dd'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'address'.tr,
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.location),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            // Emergency Contact Information
            _buildSectionTitle('emergency_contact'.tr),
            const SizedBox(height: 8),

            // Emergency Contact Name
            TextFormField(
              controller: _emergencyContactNameController,
              decoration: InputDecoration(
                labelText: 'emergency_contact_name'.tr,
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.user_tag),
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Contact Phone
            TextFormField(
              controller: _emergencyContactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'emergency_contact_phone'.tr,
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Iconsax.call),
              ),
            ),
            const SizedBox(height: 30),

            // Account Creation Checkbox
            CheckboxListTile(
              title: Text(
'create_user_account_for_donor'.tr,
                style: GoogleFonts.poppins(),
              ),
              value: _needsAccount,
              activeColor: Colors.red,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _needsAccount = value ?? false;
                });
              },
            ),

            // Account Creation Fields (conditionally visible)
            if (_needsAccount) ...[
              const SizedBox(height: 20),
              _buildSectionTitle('account_information'.tr),
              const SizedBox(height: 10),

              // Username/Email
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'email_username'.tr,
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Iconsax.user),
                ),
                validator: (value) {
                  if (_needsAccount) {
                    if (value == null || value.isEmpty) {
                      return 'email_required'.tr;
                    }
                    // Simple email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'email_invalid'.tr;
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'password'.tr,
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Iconsax.lock),
                ),
                validator: (value) {
                  if (_needsAccount) {
                    if (value == null || value.isEmpty) {
                      return 'password_required'.tr;
                    }
                    if (value.length < 8) {
                      return 'password_min_8_chars'.tr;
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'verification_information'.tr,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Donor Photo
          Center(
            child: _donorPhoto == null
                ? Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(
                      _donorPhoto!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Personal Information Summary
          _buildSummaryCard(
            title: 'personal_information'.tr,
            items: [
              SummaryItem(label: 'first_name'.tr, value: _firstNameController.text),
              SummaryItem(label: 'last_name'.tr, value: _lastNameController.text),
              SummaryItem(label: 'phone'.tr, value: _phoneController.text),
              SummaryItem(label: 'email'.tr, value: _emailController.text.isEmpty ? 'not_specified'.tr : _emailController.text),
              SummaryItem(label: 'gender'.tr, value: _selectedGender == 'M' ? 'male'.tr : 'female'.tr),
              SummaryItem(label: 'blood_type'.tr, value: _selectedBloodType ?? ''),
              SummaryItem(label: 'date_of_birth'.tr, value: _dobController.text),
              SummaryItem(label: 'address'.tr, value: _addressController.text.isEmpty ? 'not_specified'.tr : _addressController.text),
            ],
          ),

          // Emergency Contact Information
          if (_emergencyContactNameController.text.isNotEmpty || _emergencyContactPhoneController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'emergency_contact'.tr,
              items: [
                SummaryItem(
                  label: 'last_name'.tr,
                  value: _emergencyContactNameController.text.isEmpty ? 'not_specified'.tr : _emergencyContactNameController.text
                ),
                SummaryItem(
                  label: 'phone'.tr,
                  value: _emergencyContactPhoneController.text.isEmpty ? 'not_specified'.tr : _emergencyContactPhoneController.text
                ),
              ],
            ),
          ],

          if (_needsAccount) ...[
            const SizedBox(height: 16),
            _buildSummaryCard(
              title: 'account_information'.tr,
              items: [
                SummaryItem(label: 'email'.tr, value: _usernameController.text),
                SummaryItem(label: 'password'.tr, value: '••••••••'),
              ],
            ),
          ],

          // Error message if any
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.red),
          const SizedBox(height: 24),
          Text(
            'registration_in_progress'.tr,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'please_wait'.tr,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'registration_successful_title'.tr,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                Column(
                  children: [
                    Text(
                      'donor_registered_successfully'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'keep_donor_code_reference'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        InkWell(
                          onTap: () {
                            final donorCode = ref.read(donorRegistrationProvider.notifier).donorCode;
                            Clipboard.setData(ClipboardData(text: donorCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'copied_to_clipboard'.tr,
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.shade200)
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.code, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${'donor_code_label'.tr}: ${ref.read(donorRegistrationProvider.notifier).donorCode}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Iconsax.copy, color: Colors.red, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_ind, color: Colors.grey.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${'donor_id_label'.tr}: ${ref.read(donorRegistrationProvider.notifier).donorId}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_donorPhoto != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'photo_uploaded_successfully'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Reset the form and start a new registration
                  setState(() {
                    _currentStep = 0;
                    _submissionSuccessful = false;
                    _donorPhoto = null;
                    _faceOk = false;
                    _faceChecking = false;
                    _faceErrorKey = null;
                    _firstNameController.clear();
                    _lastNameController.clear();
                    _phoneController.clear();
                    _emailController.clear();
                    _addressController.clear();
                    _emergencyContactNameController.clear();
                    _emergencyContactPhoneController.clear();
                    _dobController.clear();
                    _usernameController.clear();
                    _passwordController.clear();
                    _selectedBloodType = null;
                    _selectedGender = null;
                    _needsAccount = false;
                  });
                },
                icon: const Icon(Iconsax.add_circle),
                label: Text(
                  'new_registration'.tr,
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: GoogleFonts.poppins(fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, true); // Return true to refresh donor list
                    },
                    icon: const Icon(Icons.home),
                    label: Text(
'return_to_home'.tr,
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Return to donor list and refresh
                      Navigator.pop(context, true); // Pass true to indicate refresh
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'view_donors'.tr,
                      style: GoogleFonts.poppins(),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    if (_isSubmitting || _submissionSuccessful) {
      return const SizedBox.shrink(); // Hide navigation when loading or successful
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index <= _currentStep ? Colors.red : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button (hidden on first step)
              _currentStep > 0
                  ? OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('previous'.tr, style: GoogleFonts.poppins()),
                    )
                  : const SizedBox(width: 100),

              // Step indicator text
              Text(
                'step_x_of_y'.trParams({'x': '${_currentStep + 1}', 'y': '$_totalSteps'}),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Next/Submit Button
              ElevatedButton(
                onPressed: () {
                  _handleNextStep();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  _currentStep == _totalSteps - 1 ? 'submit'.tr : 'next'.tr,
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  Future<void> _takeDonorPhoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );

    if (image != null) {
      final file = File(image.path);
      setState(() {
        _donorPhoto = file;
        _faceOk = false;
        _faceErrorKey = null;
        _faceChecking = false;
      });
      await _validateFace(file);
    }
  }

  Future<void> _validateFace(File file) async {
    setState(() {
      _faceChecking = true;
      _faceErrorKey = null;
      _faceOk = false;
    });

    FaceDetector? faceDetector;

    try {
      final inputImage = InputImage.fromFile(file);
      faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: true,
          enableClassification: true,
          minFaceSize: 0.1,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (!mounted) {
        return;
      }

      if (faces.isEmpty) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_no_face_detected';
          _faceChecking = false;
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_multiple_faces';
          _faceChecking = false;
        });
        return;
      }

      final face = faces.first;
      final faceBounds = face.boundingBox;
      final imageWidth = inputImage.metadata?.size.width ?? 1000;
      final imageHeight = inputImage.metadata?.size.height ?? 1000;

      final faceArea = faceBounds.width * faceBounds.height;
      final imageArea = imageWidth * imageHeight;
      final faceCoveragePercent = imageArea <= 0 ? 0 : (faceArea / imageArea) * 100;

      if (faceCoveragePercent < 15) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_too_small';
          _faceChecking = false;
        });
        return;
      }

      if (faceCoveragePercent > 85) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_too_close';
          _faceChecking = false;
        });
        return;
      }

      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      final mouth = face.landmarks[FaceLandmarkType.bottomMouth];

      int landmarksDetected = 0;
      if (leftEye != null) landmarksDetected++;
      if (rightEye != null) landmarksDetected++;
      if (nose != null) landmarksDetected++;
      if (mouth != null) landmarksDetected++;

      if (landmarksDetected < 3) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_landmarks_not_detected';
          _faceChecking = false;
        });
        return;
      }

      final faceCenterX = faceBounds.left + (faceBounds.width / 2);
      final faceCenterY = faceBounds.top + (faceBounds.height / 2);
      final imageCenterX = imageWidth / 2;
      final imageCenterY = imageHeight / 2;

      final horizontalOffset = imageWidth == 0 ? 0 : ((faceCenterX - imageCenterX).abs() / imageWidth) * 100;
      final verticalOffset = imageHeight == 0 ? 0 : ((faceCenterY - imageCenterY).abs() / imageHeight) * 100;

      if (horizontalOffset > 30 || verticalOffset > 35) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_not_centered';
          _faceChecking = false;
        });
        return;
      }

      final headEulerAngleY = face.headEulerAngleY;
      final headEulerAngleZ = face.headEulerAngleZ;

      if (headEulerAngleY != null && headEulerAngleY.abs() > 25) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_not_straight';
          _faceChecking = false;
        });
        return;
      }

      if (headEulerAngleZ != null && headEulerAngleZ.abs() > 20) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_tilted';
          _faceChecking = false;
        });
        return;
      }

      final leftEyeOpenProb = face.leftEyeOpenProbability;
      final rightEyeOpenProb = face.rightEyeOpenProbability;

      if (leftEyeOpenProb != null && rightEyeOpenProb != null) {
        if (leftEyeOpenProb < 0.3 && rightEyeOpenProb < 0.3) {
          setState(() {
            _faceOk = false;
            _faceErrorKey = 'face_eyes_closed';
            _faceChecking = false;
          });
          return;
        }
      }

      setState(() {
        _faceOk = true;
        _faceErrorKey = null;
        _faceChecking = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _faceOk = false;
        _faceErrorKey = 'face_validation_error';
        _faceChecking = false;
      });
    } finally {
      await faceDetector?.close();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(now.year - 18, now.month, now.day);
    final DateTime firstDate = DateTime(now.year - 100);
    final DateTime lastDate = now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format in YYYY-MM-DD as required by the API
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _handleNextStep() {
    // For the photo step, check if photo is taken
    if (_currentStep == 0) {
      if (_donorPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('take_donor_photo_required'.tr),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_faceChecking) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('photo_analysis_wait'.tr),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!_faceOk) {
        final message = _faceErrorKey != null
            ? _resolveFaceErrorMessage(_faceErrorKey!)
            : 'photo_must_show_clear_face'.tr;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Move to next step
      setState(() {
        _currentStep++;
      });
      return;
    }

    // For form step, validate inputs
    if (_currentStep == 1) {
      if (_formKey.currentState!.validate() && _selectedGender != null) {
        // Form is valid, move to next step
        setState(() {
          _currentStep++;
        });
      } else {
        // Show error if gender is not selected (form validation handles the rest)
        if (_selectedGender == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('select_gender_required'.tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // For overview step, submit the form
    if (_currentStep == 2) {
      _submitDonorRegistration();
    }
  }

  Future<void> _submitDonorRegistration() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      // Create donor data model
      final donorData = DonorData(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        gender: _selectedGender ?? 'M',
        bloodType: _selectedBloodType ?? 'O+',
        dateOfBirth: _dobController.text,
        address: _addressController.text,
        emergencyContactName: _emergencyContactNameController.text,
        emergencyContactPhone: _emergencyContactPhoneController.text,
        photo: _donorPhoto,
        createAccount: _needsAccount,
        username: _needsAccount ? _usernameController.text : null,
        password: _needsAccount ? _passwordController.text : null,
      );

      // Get the registration controller
      final registrationController = ref.read(donorRegistrationProvider.notifier);

      // Submit registration - now returns Map with additional info
      final result = await registrationController.registerDonor(donorData);

      if (result['success']) {
        // Store donor ID and code in case we need them later
        final donorId = result['donorId'];
        final donorCode = result['donorCode'];
        debugPrint('Donor registered successfully with ID: $donorId, Code: $donorCode');

        setState(() {
          _isSubmitting = false;
          _submissionSuccessful = true;
        });
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result['message'] ?? 'error_occurred_try_again'.tr;
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'error_with_message'.trParams({'message': e.toString()});
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  String _resolveFaceErrorMessage(String key) {
    switch (key) {
      case 'face_no_face_detected':
        return 'face_no_face_detected'.tr;
      case 'face_multiple_faces':
        return 'face_multiple_faces'.tr;
      case 'face_too_small':
        return 'face_too_small'.tr;
      case 'face_too_close':
        return 'face_too_close'.tr;
      case 'face_landmarks_not_detected':
        return 'face_landmarks_not_detected'.tr;
      case 'face_not_centered':
        return 'face_not_centered'.tr;
      case 'face_not_straight':
        return 'face_not_straight'.tr;
      case 'face_tilted':
        return 'face_tilted'.tr;
      case 'face_eyes_closed':
        return 'face_eyes_closed'.tr;
      case 'face_validation_error':
        return 'face_validation_error'.tr;
      default:
        return 'photo_must_show_clear_face'.tr;
    }
  }

  Widget _buildSummaryCard({required String title, required List<SummaryItem> items}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(),
            ...items.map((item) => _buildSummaryRow(item.label, item.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryItem {
  final String label;
  final String value;

  SummaryItem({required this.label, required this.value});
}