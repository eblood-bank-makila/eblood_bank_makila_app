import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../utils/error_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme/ColorPages.dart';
import '../../blood_bank/business/service/BloodDonorApiService.dart';
import '../widgets/GradientScaffold.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/widgets/location_tree_select.dart';
import '../models/SystemCountry.dart';
import '../services/LocationService.dart';
import '../ins/id_extraction.dart';



class VolunteerRegistrationStepper extends StatefulWidget {
  final IdExtractedData? prefill;
  const VolunteerRegistrationStepper({super.key, this.prefill});

  @override
  State<VolunteerRegistrationStepper> createState() => _VolunteerRegistrationStepperState();
}

class _VolunteerRegistrationStepperState extends State<VolunteerRegistrationStepper> {
  int _step = 0;
  bool _loading = false;

  // Photo
  File? _photo;
  final _picker = ImagePicker();

  // Form controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _dob = TextEditingController();
  String? _gender; // 'm' or 'f'
  String? _bloodType; // A+/A-/...

  DateTime? _dobValue;

  // Face validation state
  bool _faceOk = false;
  bool _faceChecking = false;
  String? _faceErrorKey;

  // Location selection + phone rules
  List<SystemCountry> _locationData = [];
  bool _isLoadingLocations = false;
  String? _locationError;
  final LocationService _locationService = LocationService();
  Map<String, dynamic> _selectedLocation = {};
  String? _countryCode; // e.g. +243
  List<String> _validPrefixes = [];
  String? _phoneError;


  final _formKey = GlobalKey<FormState>();
  final _box = GetStorage();
  final _api = BloodDonorApiService();

  @override
  void initState() {
    super.initState();
    _prefillFromUser();
    _fetchLocationData();
    _applyIdPrefill(widget.prefill);
    _phone.addListener(() {
      final txt = _phone.text.trim();
      final err = _validatePhone(txt);
      if (_phoneError != err) {
        setState(() => _phoneError = err);
      }
    });
  }

  void _applyIdPrefill(IdExtractedData? d) {
    if (d == null) return;
    if ((d.firstName ?? '').isNotEmpty) _firstName.text = d.firstName!;
    if ((d.lastName ?? '').isNotEmpty) _lastName.text = d.lastName!;
    // Sex mapping
    if ((d.sex ?? '').isNotEmpty) {
      final s = d.sex!.toLowerCase();
      if (s.startsWith('m')) _gender = 'm';
      if (s.startsWith('f')) _gender = 'f';
    }
    // Address
    if ((d.address ?? '').isNotEmpty) _address.text = d.address!;
    // DOB
    if (d.dob != null) {
      _dobValue = d.dob;
      final mm = d.dob!.month.toString().padLeft(2, '0');
      final dd = d.dob!.day.toString().padLeft(2, '0');
      _dob.text = '${d.dob!.year}-$mm-$dd';
    }
    setState(() {});
  }

  void _prefillFromUser() {
    try {
      final user = _box.read('user_data');
      if (user is Map) {
        _firstName.text = (user['first_name'] ?? user['uPrenom'] ?? '').toString();
        _lastName.text = (user['last_name'] ?? user['uNom'] ?? '').toString();
        _email.text = (user['email'] ?? '').toString();
        final rawPhone = (user['phone_number'] ?? user['telephone'] ?? '').toString();
        if (rawPhone.isNotEmpty) _phone.text = rawPhone.replaceAll('+', '');
        final g = (user['gender'] ?? user['uGenre'] ?? '').toString().toLowerCase();
        if (g == 'm' || g == 'male') _gender = 'm';
        if (g == 'f' || g == 'female') _gender = 'f';
      }
    } catch (_) {}
    setState(() {});
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _dob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Gradient header with back button and title
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
                      'volunteer_register_title'.tr,
                      style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w700, color: ColorPages.COLOR_PRINCIPAL),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Content

            Expanded(
              child: Stepper(
                currentStep: _step,
                onStepContinue: _onContinue,
                onStepCancel: _onBack,
                steps: [
                  Step(title: Text('volunteer_step_photo'.tr), isActive: _step >= 0, content: _buildPhotoStep()),
                  Step(title: Text('volunteer_step_form'.tr), isActive: _step >= 1, content: _buildFormStep()),
                ],
                controlsBuilder: (context, details) {
                  final isLast = _step == 1;
                  final bool canContinue = !_loading && (_step == 0 ? (_photo != null && _faceOk && !_faceChecking) : true);
                  return Row(
                    children: [
                      ElevatedButton(
                        onPressed: canContinue ? details.onStepContinue : null,
                        style: ElevatedButton.styleFrom(backgroundColor: ColorPages.COLOR_PRINCIPAL, foregroundColor: Colors.white),
                        child: Text(isLast ? 'submit'.tr : 'continue'.tr),
                      ),
                      const SizedBox(width: 12),
                      TextButton(onPressed: _loading ? null : details.onStepCancel, child: Text('back'.tr)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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

        (_faceErrorKey != null)
            ? Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _faceErrorKey!.tr,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              )
            : const SizedBox.shrink(),
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
        _faceOk = false;
        _faceErrorKey = null;
      });
      final options = FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
      final detector = FaceDetector(options: options);
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await detector.processImage(inputImage);
      await detector.close();

      bool ok = false;
      String? errorKey;
      if (faces.isEmpty) {
        errorKey = 'face_no_face';
      } else if (faces.length > 1) {
        errorKey = 'face_multiple_faces';
      } else {
        // Enforce profile-like framing: big and centered face
        final face = faces.first;
        final rect = face.boundingBox;
        try {
          final bytes = await file.readAsBytes();
          final img = await _decodeUiImage(bytes);
          final imgW = img.width.toDouble();
          final imgH = img.height.toDouble();

          final wFrac = rect.width / imgW;
          final hFrac = rect.height / imgH;
          final cx = rect.center.dx / imgW;
          final cy = rect.center.dy / imgH;

          const minFrac = 0.28; // face must occupy >=28% in both dimensions
          final centered = ((cx - 0.5).abs() <= 0.25 && (cy - 0.5).abs() <= 0.25);

          if (wFrac < minFrac || hFrac < minFrac) {
            errorKey = 'face_too_small';
          } else if (!centered) {
            errorKey = 'face_not_centered';
          } else {
            ok = true;
          }
        } catch (_) {
          // Fallback: if we can't compute size/center, require manual retake
          errorKey = 'face_required';
        }
      }

      if (!mounted) return;
      setState(() {
        _faceOk = ok;
        _faceErrorKey = errorKey;
        _faceChecking = false;
      });

      if (!ok && errorKey != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorKey.tr)),
        );
      }
    } catch (_) {
      if (!mounted) return;
    }
  }

  // ---- Location fetching and phone validation ----
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
    } catch (e, st) {
      // Hide sensitive details in production; keep details in debug logs
      ErrorUtils.log(e, st, 'volunteer._fetchLocationData');
      setState(() {
        _locationError = ErrorUtils.isRelease
            ? '${'network_error'.tr}. ${'try_again'.tr}'
            : 'loading_data_error'.trParams({'error': e.toString()});
        _isLoadingLocations = false;
      });
    }
  }

  void _onLocationSelected(Map<String, String> location) {
    // Resolve country for the selected node and extract phone rules
    String? selectedCountryId;
    final selectedType = location['type'];

    if (selectedType == 'country') {
      selectedCountryId = location['id'];
    } else if (selectedType == 'province') {
      selectedCountryId = location['country_id'] ?? location['system_country_id'];
      if (selectedCountryId == null) {
        // Find parent country by scanning
        final provId = location['id'];
        for (final country in _locationData) {
          if (country.children.any((p) => p.id == provId)) {
            selectedCountryId = country.id;
            break;
          }
        }
      }
    } else if (selectedType == 'town') {
      selectedCountryId = location['country_id'] ?? location['system_country_id'];
      if (selectedCountryId == null) {
        final provId = location['province_id'] ?? location['parent_id'];
        if (provId != null) {
          for (final country in _locationData) {
            if (country.children.any((p) => p.id == provId)) {
              selectedCountryId = country.id;
              break;
            }
          }
        }
        if (selectedCountryId == null) {
          final townId = location['id'];
          for (final country in _locationData) {
            bool found = false;
            for (final prov in country.children) {
              if (prov.children.any((t) => t.id == townId)) {
                selectedCountryId = country.id;
                found = true;
                break;
              }
            }
            if (found) break;
          }
        }
      }
    }

    String? newCountryCode;
    List<String> newPrefixes = [];
    String? countryFlag;

    if (selectedCountryId == null && _locationData.isNotEmpty) {
      selectedCountryId = _locationData.first.id;
    }

    if (selectedCountryId != null) {
      for (final country in _locationData) {
        if (country.id == selectedCountryId) {
          if (country.countryCodes != null && country.countryCodes!.isNotEmpty) {
            final code = country.countryCodes!.first.countryCode;
            newCountryCode = code.startsWith('+') ? code : '+$code';
          }
          if (country.telephonePrefixes != null && country.telephonePrefixes!.isNotEmpty) {
            newPrefixes = country.telephonePrefixes!.map((e) => e.prefix).toList();
          }
          countryFlag = country.countryFlag;
          break;
        }
      }
    }

    setState(() {
      final oldCountryCode = _countryCode;
      _selectedLocation = Map<String, String>.from(location);
      _countryCode = newCountryCode ?? _countryCode;
      if (newPrefixes.isNotEmpty) {
        _validPrefixes = newPrefixes;
      }
      _selectedLocation['country_code'] = _countryCode;
      _selectedLocation['country_flag'] = countryFlag ?? (_selectedLocation['country_flag'] ?? '');
      if (oldCountryCode != _countryCode) {
        _phone.clear();
      }
      _phoneError = null;
    });
  }

  bool _hasValidPrefix(String phoneNumber) {
    if (_validPrefixes.isEmpty || phoneNumber.length < 2) return false;
    for (final p in _validPrefixes) {
      if (phoneNumber.startsWith(p)) return true;
    }
    return false;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'phone_required'.tr;
    if (!RegExp(r'^[0-9]+ ?').hasMatch(value)) {
      // Keep it simple: digits only
      if (!RegExp(r'^[0-9]+').hasMatch(value)) return 'phone_only_digits'.tr;
    }
    if (_validPrefixes.isNotEmpty && value.length >= 3) {
      if (!_hasValidPrefix(value)) return 'invalid_phone_prefix'.tr;
    }
    if (_hasValidPrefix(value) && value.length > 5 && value.length < 9) {
      return 'invalid_phone_length'.tr;
    }
    return null;
  }

  Widget _buildPhoneField() {
    final hint = _validPrefixes.isNotEmpty ? '${_validPrefixes.first} XXXXXXX' : 'XXXXXXXX';
    final flag = (_selectedLocation['country_flag'] ?? '').toString();
    final code = _countryCode ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'phone_number'.tr,
            prefixIcon: SizedBox(
              width: 92,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: Text('$flag $code', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            hintText: hint,
            errorText: _phoneError,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ColorPages.COLOR_BLUE, width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: _validatePhone,
        ),
        const SizedBox(height: 8),
        if (_validPrefixes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('valid_prefixes'.tr, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _validPrefixes
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ],
          ),
      ],
    );
  }



  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }



  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _input(_firstName, label: 'first_name'.tr)),
            const SizedBox(width: 12),
            Expanded(child: _input(_lastName, label: 'last_name'.tr)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dropdownGender()),
            const SizedBox(width: 12),
            Expanded(child: _dropdownBloodType()),
          ]),
          const SizedBox(height: 12),
          _dobField(),
          const SizedBox(height: 12),
          // Location selector (entity)
          LocationTreeSelect(
            label: 'your_location'.tr,
            hint: 'hint_select_location'.tr,
            locations: _locationData,
            onLocationSelected: _onLocationSelected,
            isLoading: _isLoadingLocations,
            errorText: _locationError,
            isRequired: true,
            prefixIcon: const Icon(Icons.location_on_outlined),
            showPath: true,
            selectOnlyLastChild: true,
          ),
          const SizedBox(height: 12),
          _input(_email, label: 'email'.tr, keyboardType: TextInputType.emailAddress, required: false),
          const SizedBox(height: 12),
          if (_selectedLocation.isNotEmpty && _countryCode != null) _buildPhoneField(),
          if (!(_selectedLocation.isNotEmpty && _countryCode != null))
            Text('select_valid_location_for_phone'.tr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          _input(_address, label: 'address'.tr, required: false, minLines: 2, maxLines: 3, keyboardType: TextInputType.multiline),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController c, {
    required String label,
    TextInputType? keyboardType,
    bool required = true,
    int? minLines,
    int? maxLines,
  }) {
    final isMultiline = (maxLines != null && maxLines > 1) || (minLines != null && (maxLines ?? 0) != 1);
    return TextFormField(
      controller: c,
      keyboardType: keyboardType ?? (isMultiline ? TextInputType.multiline : null),
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorPages.COLOR_BLUE, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return 'required_field'.tr;
        return null;
      },
    );
  }

  Widget _dobField() {
    return TextFormField(
      controller: _dob,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'date_of_birth'.tr,
        suffixIcon: const Icon(Icons.calendar_today),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorPages.COLOR_BLUE, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      onTap: _selectDob,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'required_field'.tr;
        final s = v.trim();
        final parsed = DateTime.tryParse(s);
        if (parsed == null) return 'invalid_date'.tr;
        final now = DateTime.now();
        final cutoff = DateTime(now.year - 18, now.month, now.day);
        if (parsed.isAfter(cutoff)) return 'must_be_18_or_older'.tr;
        return null;
      },
    );
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final initial = _dobValue ?? DateTime(now.year - 18, now.month, now.day);
    final first = DateTime(1900, 1, 1);
    final last = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : initial,
      firstDate: first,
      lastDate: last,
      helpText: 'date_of_birth'.tr,
    );
    if (picked != null) {
      setState(() {
        _dobValue = picked;
        final mm = picked.month.toString().padLeft(2, '0');
        final dd = picked.day.toString().padLeft(2, '0');
        _dob.text = '${picked.year}-$mm-$dd';
      });
    }
  }

  Widget _dropdownGender() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      items: [
        DropdownMenuItem(value: 'm', child: Text('male'.tr)),
        DropdownMenuItem(value: 'f', child: Text('female'.tr)),
      ],
      onChanged: (v) => setState(() => _gender = v),
      decoration: InputDecoration(
        labelText: 'gender'.tr,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorPages.COLOR_BLUE, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (v) => v == null ? 'required_field'.tr : null,
    );
  }

  Widget _dropdownBloodType() {
    const types = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];
    return DropdownButtonFormField<String>(
      initialValue: _bloodType,
      items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _bloodType = v),
      decoration: InputDecoration(
        labelText: 'blood_type'.tr,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorPages.COLOR_BLUE, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (v) => v == null ? 'required_field'.tr : null,
    );
  }

  void _onBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onContinue() async {
    if (_step == 0) {
      if (_photo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('photo_required'.tr)));
        }
        return;
      }
      if (!_faceOk) {
        if (mounted) {
          final key = _faceErrorKey ?? 'face_required';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr)));
        }
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // Require location selection
    if (_selectedLocation.isEmpty || _selectedLocation['id'] == null || (_selectedLocation['id'] as String).isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('select_valid_location'.tr)));
      }
      return;
    }

    // Validate phone with prefixes
    final phoneErr = _validatePhone(_phone.text.trim());
    if (phoneErr != null) {
      setState(() => _phoneError = phoneErr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr)));
      }
      return;
    }

    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final String refEntityId = (_selectedLocation['id'] ?? '').toString();
      final payload = {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'gender': (_gender ?? '').toLowerCase(),
        'blood_type': _bloodType,
        'date_of_birth': _dob.text.trim(),
        'email': _email.text.trim(),
        'phone_number': _countryCode != null ? _countryCode! + _phone.text.trim() : _phone.text.trim(),
        'address': _address.text.trim(),
        'ref_entity_id': refEntityId,
      };

      final res = await _api.registerDonor(payload);
      if (res.success) {
        final data = res.data;
        String? donorId;
        if (data is Map && data['donor_id'] != null) donorId = data['donor_id'].toString();
        if (donorId == null && data is Map && data['id'] != null) donorId = data['id'].toString();
        if (donorId != null && _photo != null) {
          await _api.uploadDonorPhoto(donorId, _photo!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('registration_successful'.tr)));
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'registration_failed'.tr)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${'error'.tr}: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

