import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:go_router/go_router.dart';
import '../../core/rbac/services/rbac_guard.dart';
import '../config/theme/ColorPages.dart';
import '../widgets/GradientScaffold.dart';
import '../../core/widgets/location_tree_select.dart';
import '../models/SystemCountry.dart';
import '../services/LocationService.dart';
import '../services/AuthService.dart';
import '../widgets/CustomTextField.dart';
import '../widgets/CustomDropdown.dart';
import '../models/UserInfoValidation.dart';
import '../demarrage/OTPVerificationPage.dart';
import '../services/AuthApi.dart';

/// Stepper for users to become benevol donors (volunteer donors)
/// Step 1: Photo selection/capture with face validation
/// Steps 2-5: Personal information (same as PersonalRegistrationStepperPage)
class BenevolDonorRegistrationStepper extends ConsumerStatefulWidget {
  final bool isDonor;
  const BenevolDonorRegistrationStepper({super.key, this.isDonor = false});

  @override
  ConsumerState<BenevolDonorRegistrationStepper> createState() => _BenevolDonorRegistrationStepperState();
}

class _BenevolDonorRegistrationStepperState extends ConsumerState<BenevolDonorRegistrationStepper> {
  int _currentStep = 0;
  bool _loading = false;

  // Photo (Step 0)
  File? _photo;
  final _picker = ImagePicker();
  bool _faceOk = false;
  bool _faceChecking = false;
  String? _faceErrorKey;

  // Form keys
  final _personalFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _bloodFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();

  // Personal Information (Step 1)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;

  // Contact Information (Step 2)
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  Map<String, String> _selectedLocation = {};
  String? _countryCode;
  List<String> _validPrefixes = [];
  String? _phoneError;

  // Blood Information (Step 3)
  String? _selectedBloodType;
  String? _selectedReason = 'blood_donor'; // Default to blood_donor for benevol

  // Account Information (Step 4) - Password REQUIRED for volunteers
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  // Location data
  List<SystemCountry> _locationData = [];
  bool _isLoadingLocations = false;
  String? _locationError;
  final LocationService _locationService = LocationService();

  // Mock data
  final List<Map<String, String>> _genders = [
    {'value': 'm', 'label': 'male'},
    {'value': 'f', 'label': 'female'},
  ];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final _box = GetStorage();
  final AuthApi _authApi = AuthApi.instance;

  @override
  void initState() {
    super.initState();
    // RBAC entry guard — volunteer sub_menu flag.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_home_volunteer',
    );
    _prefillFromUser();
    _fetchLocationData();

    _phoneController.addListener(() {
      if (_phoneController.text.isNotEmpty && _validPrefixes.isNotEmpty) {
        setState(() {
          _phoneError = _validatePhone(_phoneController.text);
        });
      }
    });
  }

  void _prefillFromUser() {
    try {
      // Only prefill if user is authenticated with real profile (NOT visitor)
      final user = _box.read('user_data');
      final accountType = _box.read('account_type');
      final authToken = _box.read('auth_token');
      final profiles = _box.read('user_profils');
      
      // 🐛 DEBUG: Log what we're checking
      print('🔍 BenevolDonor Prefill Check:');
      print('   user: ${user != null ? "exists" : "null"}');
      print('   accountType: $accountType');
      print('   authToken: ${authToken != null ? "exists" : "null"}');
      print('   profiles: $profiles');
      
      // STRICT CHECK: Don't prefill for visitors or unauthenticated users
      if (user == null || accountType == null || accountType == 'visitor' || authToken == null) {
        print('   ❌ PREFILL BLOCKED - Visitor or missing data');
        return; // Exit early - no prefill for visitors
      }
      
      // Additional check: ensure user has a valid ID (real users have database IDs)
      final userId = user['id'] ?? user['_id'] ?? user['uId'];
      if (userId == null || userId.toString().isEmpty) {
        print('   ❌ PREFILL BLOCKED - No valid user ID');
        return; // No valid user ID - likely a visitor
      }
      
      if (user is Map) {
        final firstName = (user['first_name'] ?? user['uPrenom'] ?? '').toString().trim();
        final lastName = (user['last_name'] ?? user['uNom'] ?? '').toString().trim();
        final email = (user['email'] ?? '').toString().trim();
        
        // Only prefill if we have meaningful data (not empty, not visitor/guest)
        if (firstName.isNotEmpty && 
            !firstName.toLowerCase().contains('visitor') && 
            !firstName.toLowerCase().contains('guest') &&
            !firstName.toLowerCase().contains('anonymous')) {
          _firstNameController.text = firstName;
          print('   ✅ Prefilled firstName: $firstName');
        }
        if (lastName.isNotEmpty && 
            !lastName.toLowerCase().contains('visitor') && 
            !lastName.toLowerCase().contains('guest') &&
            !lastName.toLowerCase().contains('anonymous')) {
          _lastNameController.text = lastName;
          print('   ✅ Prefilled lastName: $lastName');
        }
        if (email.isNotEmpty && 
            email.contains('@') && 
            !email.toLowerCase().contains('fake') &&
            !email.toLowerCase().contains('visitor') &&
            !email.toLowerCase().contains('anonymous')) {
          _emailController.text = email;
          print('   ✅ Prefilled email: $email');
        }
        
        final rawPhone = (user['phone_number'] ?? user['telephone'] ?? '').toString().trim();
        if (rawPhone.isNotEmpty && 
            rawPhone != '0000000000' && 
            !rawPhone.contains('fake') &&
            !rawPhone.contains('visitor') &&
            rawPhone.length > 5) {
          _phoneController.text = rawPhone.replaceAll('+', '');
          print('   ✅ Prefilled phone: $rawPhone');
        }
        
        final g = (user['gender'] ?? user['uGenre'] ?? '').toString().toLowerCase();
        if (g == 'm' || g == 'male') _selectedGender = 'm';
        if (g == 'f' || g == 'female') _selectedGender = 'f';
      }
    } catch (_) {}
    setState(() {});
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

  void _onLocationSelected(Map<String, String> location) {
    String? newCountryCode;
    List<String> newPrefixes = [];
    String? selectedCountryFlag;
    String? selectedCountryId;

    if (location.isNotEmpty) {
      _locationError = null;
      String? selectedType = location['type'];

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

      SystemCountry? countryNode;
      if (selectedCountryId != null) {
        countryNode = _findCountryById(selectedCountryId, _locationData);
        if (countryNode != null && countryNode.namedEntityFlag.toLowerCase() != 'country') {
          countryNode = _findCountryForNodeId(selectedCountryId);
        }
      }

      countryNode ??= _findCountryForNodeId(location['id'] ?? '');

      if (countryNode != null) {
        selectedCountryId = countryNode.id;
        if (countryNode.countryCodes != null && countryNode.countryCodes!.isNotEmpty) {
          newCountryCode = countryNode.countryCodes!.first.countryCode;
        }
        if (countryNode.telephonePrefixes != null && countryNode.telephonePrefixes!.isNotEmpty) {
          newPrefixes = countryNode.telephonePrefixes!.map((p) => p.prefix).toList();
        }
        if (countryNode.countryFlag != null && countryNode.countryFlag!.isNotEmpty) {
          selectedCountryFlag = countryNode.countryFlag;
        }
      }
    }

    setState(() {
      _selectedLocation = Map<String, String>.from(location);
      _countryCode = newCountryCode;
      _validPrefixes = newPrefixes;
      _phoneError = null;
      if (selectedCountryId != null && selectedCountryId.isNotEmpty) {
        _selectedLocation['country_id'] = selectedCountryId;
      }
      if (selectedCountryFlag != null && selectedCountryFlag.isNotEmpty) {
        _selectedLocation['country_flag'] = selectedCountryFlag;
      } else {
        _selectedLocation.remove('country_flag');
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_BLANCHE.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: ColorPages.COLOR_PRINCIPAL),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'become_benevol_donor'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Stepper content
            Expanded(
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
                    // Last step is 3 for donors (no account step), 4 for benevol donors
                    final isLastStep = widget.isDonor ? _currentStep == 3 : _currentStep == 4;
                    final bool canContinue = !_loading && (_currentStep == 0 ? (_photo != null && _faceOk && !_faceChecking) : true);
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: canContinue ? details.onStepContinue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPages.COLOR_PRINCIPAL,
                              foregroundColor: ColorPages.COLOR_BLANCHE,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_loading && isLastStep)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(ColorPages.COLOR_BLANCHE),
                                    ),
                                  ),
                                if (_loading && isLastStep) const SizedBox(width: 8),
                                Text(isLastStep ? 'submit'.tr : 'continue'.tr),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: _loading ? null : details.onStepCancel,
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
          ],
        ),
      ),
    );
  }

  List<Step> _buildSteps() {
    final steps = [
      Step(
        title: Text('profile_photo'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 0,
        content: _buildPhotoStep(),
      ),
      Step(
        title: Text('personal_information'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 1,
        content: _buildPersonalStep(),
      ),
      Step(
        title: Text('contact_information'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 2,
        content: _buildContactStep(),
      ),
      Step(
        title: Text('blood_information'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
        isActive: _currentStep >= 3,
        content: _buildBloodStep(),
      ),
    ];

    // Only add account information step for benevol donors (not regular donors)
    if (!widget.isDonor) {
      steps.add(
        Step(
          title: Text('account_information'.tr, style: const TextStyle(color: ColorPages.COLOR_PRINCIPAL)),
          isActive: _currentStep >= 4,
          content: _buildAccountStep(),
        ),
      );
    }

    return steps;
  }

  // ==================== STEP 0: Photo ====================
  Widget _buildPhotoStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPages.COLOR_BLUE.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.badge_outlined, color: ColorPages.COLOR_BLUE),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'profile_photo_tip'.tr,
                    style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_faceErrorKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _faceErrorKey!.tr,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _photo != null ? FileImage(_photo!) : null,
          child: _photo == null ? const Icon(Icons.person, size: 48, color: Colors.grey) : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text('take_photo'.tr),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text('choose_photo'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) {
      final file = File(x.path);
      setState(() {
        _photo = file;
        _faceOk = false;
        _faceErrorKey = null;
      });
      await _validateFace(file);
    }
  }

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) {
      final file = File(x.path);
      setState(() {
        _photo = file;
        _faceOk = false;
        _faceErrorKey = null;
      });
      await _validateFace(file);
    }
  }

  Future<void> _validateFace(File file) async {
    try {
      if (!mounted) return;
      setState(() {
        _faceChecking = true;
        _faceErrorKey = null;
      });

      final inputImage = InputImage.fromFile(file);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: true,
          enableClassification: true,
          minFaceSize: 0.1, // Reduced from 0.15 to detect smaller faces
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (!mounted) return;

      // No face detected
      if (faces.isEmpty) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_no_face_detected';
          _faceChecking = false;
        });
        return;
      }

      // Multiple faces detected
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

      // Get image dimensions
      final imageWidth = inputImage.metadata?.size.width ?? 1000;
      final imageHeight = inputImage.metadata?.size.height ?? 1000;

      // Calculate face coverage percentage
      final faceArea = faceBounds.width * faceBounds.height;
      final imageArea = imageWidth * imageHeight;
      final faceCoveragePercent = (faceArea / imageArea) * 100;

      // Check if face is too small (likely an ID card photo)
      // A proper selfie should have the face covering at least 15% of the image
      if (faceCoveragePercent < 15) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_too_small';
          _faceChecking = false;
        });
        return;
      }

      // Check if face is too large (too close to camera)
      if (faceCoveragePercent > 85) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_too_close';
          _faceChecking = false;
        });
        return;
      }

      // Check key facial landmarks
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      final mouth = face.landmarks[FaceLandmarkType.bottomMouth];

      // Require at least 3 out of 4 key landmarks for better flexibility
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

      // Check face position - should be reasonably centered
      final faceCenterX = faceBounds.left + (faceBounds.width / 2);
      final faceCenterY = faceBounds.top + (faceBounds.height / 2);
      final imageCenterX = imageWidth / 2;
      final imageCenterY = imageHeight / 2;

      // Calculate how far the face is from center (as percentage)
      final horizontalOffset = ((faceCenterX - imageCenterX).abs() / imageWidth) * 100;
      final verticalOffset = ((faceCenterY - imageCenterY).abs() / imageHeight) * 100;

      // Face should be within 30% of center horizontally and 35% vertically
      if (horizontalOffset > 30 || verticalOffset > 35) {
        setState(() {
          _faceOk = false;
          _faceErrorKey = 'face_not_centered';
          _faceChecking = false;
        });
        return;
      }

      // Check head rotation angles (if available)
      final headEulerAngleY = face.headEulerAngleY; // Left/Right rotation
      final headEulerAngleZ = face.headEulerAngleZ; // Tilt

      // Face should be relatively straight (not too much rotation)
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

      // Check if eyes are open (if classification is available)
      final leftEyeOpenProb = face.leftEyeOpenProbability;
      final rightEyeOpenProb = face.rightEyeOpenProbability;

      if (leftEyeOpenProb != null && rightEyeOpenProb != null) {
        // At least one eye should be reasonably open
        if (leftEyeOpenProb < 0.3 && rightEyeOpenProb < 0.3) {
          setState(() {
            _faceOk = false;
            _faceErrorKey = 'face_eyes_closed';
            _faceChecking = false;
          });
          return;
        }
      }

      // All checks passed - this is a valid face photo
      setState(() {
        _faceOk = true;
        _faceErrorKey = null;
        _faceChecking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _faceOk = false;
        _faceErrorKey = 'face_validation_error';
        _faceChecking = false;
      });
    }
  }

  // ==================== STEP 1: Personal Information ====================
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
                    prefixIcon: Icons.person_outline,
                    validator: _validateRequired,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _lastNameController,
                    label: 'last_name'.tr,
                    hint: 'hint_last_name'.tr,
                    prefixIcon: Icons.person_outline,
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
                  prefixIcon: Icons.calendar_today,
                  validator: _validateDateOfBirth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ==================== STEP 2: Contact Information ====================
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('select_your_location'.tr, style: GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                LocationTreeSelect(
                  locations: _locationData,
                  onLocationSelected: _onLocationSelected,
                  label: 'location'.tr,
                  hint: 'select_location_hint'.tr,
                  useWhiteBackground: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'email'.tr,
                  hint: 'hint_email'.tr,
                  prefixIcon: Icons.mail_outline,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                // Phone number input - only show after location is selected
                if (_selectedLocation.isNotEmpty && _countryCode != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Country flag and code prefix
                          Container(
                            margin: const EdgeInsets.only(right: 8, top: 0),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Country flag emoji based on country code
                                Text(
                                  _getCountryFlag(),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+$_countryCode',
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: ColorPages.COLOR_PRINCIPAL,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: CustomTextField(
                              controller: _phoneController,
                              hiddenLabel: true,
                              label: 'phone_number'.tr,
                              hint: _validPrefixes.isNotEmpty 
                                ? '${_validPrefixes.first}XXXXXXX'
                                : 'hint_phone'.tr,
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) => _validatePhone(value ?? ''),
                            ),
                          ),
                        ],
                      ),
                      if (_phoneError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            _phoneError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      if (_validPrefixes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            '${'valid_prefixes'.tr}: ${_validPrefixes.join(", ")}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  )
                else
                  // Show hint to select location first
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'select_location_to_enter_phone'.tr,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                CustomTextField(
                  controller: _addressController,
                  label: 'address'.tr,
                  hint: 'hint_address'.tr,
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 3,
                  validator: _validateRequired,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==================== STEP 3: Blood Information ====================
  Widget _buildBloodStep() {
    return Form(
      key: _bloodFormKey,
      child: Column(
        children: [
          CustomDropdown<String>(
            label: 'blood_type'.tr,
            hint: 'hint_blood_type'.tr,
            value: _selectedBloodType,
            items: _bloodTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (value) => setState(() => _selectedBloodType = value),
            validator: _validateRequired,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPages.COLOR_BLUE.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: ColorPages.COLOR_BLUE),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'benevol_donor_info'.tr,
                    style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 4: Account Information (Password REQUIRED for volunteers) ====================
  Widget _buildAccountStep() {
    return Form(
      key: _accountFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'volunteer_password_required'.tr,
                    style: const TextStyle(fontSize: 13.5, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'password'.tr,
            hint: 'hint_password'.tr,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'confirm_password'.tr,
            hint: 'hint_confirm_password'.tr,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: _validateConfirmPassword,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: Text('accept_terms'.tr),
            value: _acceptTerms,
            onChanged: (bool? value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ==================== Navigation & Validation ====================
  void _validateAndNavigateToStep(int step) {
    if (step < _currentStep) {
      setState(() => _currentStep = step);
      return;
    }

    if (step == _currentStep + 1) {
      _onStepContinue();
    }
  }

  Future<void> _onStepContinue() async {
    switch (_currentStep) {
      case 0: // Photo step
        if (_photo == null || !_faceOk || _faceChecking) {
          Get.snackbar('error'.tr, 'photo_validation_required'.tr, snackPosition: SnackPosition.BOTTOM);
          return;
        }
        break;
      case 1: // Personal info
        if (!_personalFormKey.currentState!.validate()) return;
        break;
      case 2: // Contact info
        if (!_contactFormKey.currentState!.validate()) return;
        if (_selectedLocation.isEmpty) {
          Get.snackbar('error'.tr, 'location_required'.tr, snackPosition: SnackPosition.BOTTOM);
          return;
        }
        // Validate phone number is entered
        if (_countryCode == null || _phoneController.text.trim().isEmpty) {
          Get.snackbar('error'.tr, 'phone_required'.tr, snackPosition: SnackPosition.BOTTOM);
          return;
        }
        break;
      case 3: // Blood info
        if (!_bloodFormKey.currentState!.validate()) return;
        // If this is a regular donor (isDonor=true), this is the last step
        if (widget.isDonor) {
          await _submitRegistration();
          return;
        }
        break;
      case 4: // Account info (final step for benevol donors only)
        if (!_accountFormKey.currentState!.validate()) return;
        if (!_acceptTerms) {
          Get.snackbar('error'.tr, 'terms_acceptance_required'.tr, snackPosition: SnackPosition.BOTTOM);
          return;
        }
        await _submitRegistration();
        return;
    }

    // Determine max step based on user type
    final maxStep = widget.isDonor ? 3 : 4;
    if (_currentStep < maxStep) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  // ==================== Validation Methods ====================
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
    
    // Check if it's only digits (no spaces, dashes, etc.)
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'phone_only_digits'.tr;
    }
    
    // Basic length check
    if (value.length < 7) {
      return 'phone_too_short'.tr;
    }
    
    // If we have valid prefixes from location selection, validate prefix
    if (_validPrefixes.isNotEmpty) {
      if (!_hasValidPrefix(value)) {
        return 'invalid_phone_prefix'.tr;
      }
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
      return true; // If no prefixes defined, don't validate prefix
    }
    for (String prefix in _validPrefixes) {
      if (phoneNumber.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesVolunteerFlag(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('volonteer_blood_donor_profil') ||
        normalized.contains('volunteer_blood_donor_profil');
  }

  bool _hasVolunteerProfile(dynamic profiles) {
    if (profiles is List) {
      for (final entry in profiles) {
        if (entry is Map) {
          final candidate = (entry['profil'] ?? entry['flag'] ?? '').toString();
          if (candidate.isNotEmpty && _matchesVolunteerFlag(candidate)) {
            return true;
          }
        } else if (entry is String && _matchesVolunteerFlag(entry)) {
          return true;
        }
      }
    } else if (profiles is Map) {
      for (final value in profiles.values) {
        if (value is String && _matchesVolunteerFlag(value)) {
          return true;
        }
      }
    }
    return false;
  }

  void _showRegistrationSuccessDialog({VoidCallback? onConfirm}) {
    if (!mounted) return;
    Get.dialog(
      AlertDialog(
        title: Text('success'.tr),
        content: Text('benevol_registration_success'.tr),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm?.call();
            },
            child: Text('ok'.tr),
          ),
        ],
      ),
    );
  }

  /// Resolve the country flag provided by the location payload instead of hard-coding
  String _getCountryFlag() {
    final String? selectionFlag = _selectedLocation['country_flag'];
    if (selectionFlag != null && selectionFlag.isNotEmpty) {
      return selectionFlag;
    }

    final String? countryId = _selectedLocation['country_id'] ?? _selectedLocation['id'];
    if (countryId != null && countryId.isNotEmpty) {
      final SystemCountry? directMatch = _findCountryById(countryId, _locationData);
      SystemCountry? country = directMatch;
      if (directMatch == null || directMatch.namedEntityFlag.toLowerCase() != 'country') {
        country = _findCountryForNodeId(countryId);
      }
      if (country != null) {
        final String? flag = country.countryFlag ?? country.namedEntityFlag;
        if (flag != null && flag.isNotEmpty) {
          return flag;
        }
      }
    }

    final String? nodeId = _selectedLocation['id'];
    if (nodeId != null && nodeId.isNotEmpty) {
      final SystemCountry? country = _findCountryForNodeId(nodeId);
      if (country != null && country.countryFlag != null && country.countryFlag!.isNotEmpty) {
        return country.countryFlag!;
      }
    }

    return '🌍';
  }

  SystemCountry? _findCountryById(String id, List<SystemCountry> nodes) {
    for (final SystemCountry node in nodes) {
      if (node.id == id) {
        return node;
      }
      final SystemCountry? childMatch = _findCountryById(id, node.children);
      if (childMatch != null) {
        return childMatch;
      }
    }
    return null;
  }

  SystemCountry? _findCountryForNodeId(String nodeId) {
    if (nodeId.isEmpty) return null;
    for (final SystemCountry country in _locationData) {
      if (country.id == nodeId) {
        return country;
      }
      if (_nodeContains(country, nodeId)) {
        return country;
      }
    }
    return null;
  }

  bool _nodeContains(SystemCountry node, String targetId) {
    if (node.id == targetId) {
      return true;
    }
    for (final SystemCountry child in node.children) {
      if (_nodeContains(child, targetId)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _handlePostRegistrationSuccess({Map<String, dynamic>? responseData}) async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      // Upload photo if we have sys_donor_id
      if (responseData != null && _photo != null) {
        final sysDonorId = responseData['sys_donor_id'] ?? 
                          responseData['donor_id'] ?? 
                          responseData['id'];
        
        if (sysDonorId != null) {
          print('🔄 Uploading donor photo for sys_donor_id: $sysDonorId');
          final authService = AuthService();
          final uploadResponse = widget.isDonor
              ? await authService.uploadDonorPhoto(sysDonorId.toString(), _photo!)
              : await authService.uploadVolunteerDonorPhoto(sysDonorId.toString(), _photo!);
          
          if (uploadResponse.success) {
            print('✅ Photo uploaded successfully');
          } else {
            print('⚠️ Photo upload failed: ${uploadResponse.message}');
            // Don't fail the entire registration if photo upload fails
          }
        } else {
          print('⚠️ No sys_donor_id found in response, skipping photo upload');
        }
      }

      await _authApi.getUserProfile();
    } catch (e) {
      print('Failed to refresh user profile after benevol registration: $e');
    }

    if (!mounted) {
      return;
    }

    setState(() => _loading = false);

    _showRegistrationSuccessDialog(onConfirm: () {
      context.go('/rbac-loading');
    });
  }

  // ==================== Submit Registration ====================
  Future<void> _submitRegistration() async {
    setState(() => _loading = true);

    try {
      final authService = AuthService();

      final accountType = (_box.read('account_type') ?? '').toString();
      final dynamic storedProfiles = _box.read('user_profils');
      final isVisitor = accountType == 'visitor';
      final bool hasVolunteerProfile = _hasVolunteerProfile(storedProfiles);
      final bool requiresOtp = isVisitor || hasVolunteerProfile;

      // Extract location IDs
      final locationId = _selectedLocation['id'];
      final String? provinceId = _selectedLocation['province_id'];
      final String? townId = _selectedLocation['town_id'];

      // Prepare registration data
      String fullPhoneNumber = _phoneController.text.trim();
      if (_countryCode != null && !fullPhoneNumber.startsWith('+')) {
        fullPhoneNumber = '+$_countryCode$fullPhoneNumber';
      }

      final registrationData = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'gender': _selectedGender,
        'date_of_birth': _dateOfBirthController.text,
        'email': _emailController.text.trim(),
        'phone_number': fullPhoneNumber,
        'address': _addressController.text.trim(),
        'ref_entity_id': locationId,
        'blood_type': _selectedBloodType,
        'registration_reason': _selectedReason,
      };

      if (provinceId != null && provinceId.isNotEmpty) {
        registrationData['province_id'] = provinceId;
      }
      if (townId != null && townId.isNotEmpty) {
        registrationData['town_id'] = townId;
      }

      if (isVisitor) {
        registrationData['password'] = _passwordController.text;
        registrationData['confirm_password'] = _confirmPasswordController.text;
      }

      if (requiresOtp) {
        final validationResult = await authService.validateUserInfo(
          UserInfoValidation(
            email: _emailController.text.trim(),
            phoneNumber: fullPhoneNumber,
            validationType: 'email',
          ),
        );

        setState(() => _loading = false);

        if (validationResult['success'] == true) {
          final String? validationKey = validationResult['data']?['validation_key'];
          if (!mounted) return;
          if (validationKey == null || validationKey.isEmpty) {
            Get.snackbar(
              'error'.tr,
              'Missing validation data from server. Please try again.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 5),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                phoneNumber: fullPhoneNumber,
                email: _emailController.text.trim(),
                userData: registrationData,
                validationKey: validationKey,
                verificationType: 'email',
                onRegistration: (data) async {
                  final response = widget.isDonor
                      ? await authService.registerDonor(data)
                      : await authService.registerBenevolDonor(data);
                  return {
                    'success': response.success,
                    'message': response.message,
                    'data': response.data,
                    'status_code': response.statusCode,
                  };
                },
                onRegistrationSuccess: (ctx, result) {
                  if (Navigator.of(ctx).canPop()) {
                    Navigator.of(ctx).pop();
                  }
                  // Extract response data for photo upload
                  final responseData = result['data'] as Map<String, dynamic>?;
                  _handlePostRegistrationSuccess(responseData: responseData);
                },
              ),
            ),
          );
          return;
        }

        final message = validationResult['message'] ?? 'validation_failed'.tr;
        Get.snackbar('error'.tr, message, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
        return;
      }

      final response = widget.isDonor ? await authService.registerDonor(registrationData) : await authService.registerBenevolDonor(registrationData);

      if (!response.success) {
        setState(() => _loading = false);
        final message = response.message ?? 'registration_error'.tr;
        Get.snackbar('error'.tr, message, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
        return;
      }

      // Pass response data for photo upload
      await _handlePostRegistrationSuccess(responseData: response.data);
    } catch (e) {
      setState(() => _loading = false);
      Get.snackbar('error'.tr, 'connection_error'.tr, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5));
    }
  }
}
