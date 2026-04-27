import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/rbac/services/rbac_guard.dart';
import '../config/theme/ColorPages.dart';
import '../widgets/GradientScaffold.dart';
import '../services/AuthService.dart';
import '../models/SystemCountry.dart';
import './id_extraction.dart';
import 'ins_request_details_page.dart';

class InsRequestStepper extends ConsumerStatefulWidget {
  const InsRequestStepper({super.key});

  @override
  ConsumerState<InsRequestStepper> createState() => _InsRequestStepperState();
}

class _InsRequestStepperState extends ConsumerState<InsRequestStepper> {
  int _step = 0;
  bool _loading = false;

  final _picker = ImagePicker();
  final _authService = AuthService();
  final _box = GetStorage();
  final _formKey = GlobalKey<FormState>();
  
  // ID card
  File? _idPhoto;
  bool _idOk = false;
  bool _idChecking = false;
  String? _idErrorKey;
  IdExtractedData? _idData;

  // Form controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _middleName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _avenue = TextEditingController();
  final _quarter = TextEditingController();
  final _houseNumber = TextEditingController();
  final _dob = TextEditingController();
  
  // Form data
  String? _gender;
  String? _selectedBloodTypeId;
  String? _selectedMaritalStatusId;
  String? _selectedTownshipId;
  DateTime? _dobValue;

  // Face photo
  File? _facePhoto;
  bool _faceOk = false;
  bool _faceChecking = false;
  String? _faceErrorKey;
  
  // Init data from backend
  List<dynamic> _bloodTypes = [];
  List<dynamic> _maritalStatuses = [];
  List<SystemCountry> _locations = [];
  bool _isLoadingInitData = false;
  String? _initDataError;
  
  // Location selection
  List<dynamic> _townships = [];

  @override
  void initState() {
    super.initState();
    // RBAC entry guard.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_home_ins_request',
    );
    _fetchInitData();
    _prefillFromUser();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _middleName.dispose();
    _email.dispose();
    _phone.dispose();
    _avenue.dispose();
    _quarter.dispose();
    _houseNumber.dispose();
    _dob.dispose();
    super.dispose();
  }

  void _prefillFromUser() {
    final user = _box.read('user_data');
    if (user is Map) {
      _firstName.text = (user['first_name'] ?? user['uPrenom'] ?? '').toString();
      _lastName.text = (user['last_name'] ?? user['uNom'] ?? '').toString();
      _email.text = (user['email'] ?? user['uEmail'] ?? '').toString();
      _phone.text = (user['phone_number'] ?? user['uTelephone'] ?? '').toString();
      
      if (user['date_of_birth'] != null) {
        try {
          _dobValue = DateTime.parse(user['date_of_birth'].toString());
          _dob.text = '${_dobValue!.day}/${_dobValue!.month}/${_dobValue!.year}';
        } catch (_) {}
      }
      
      final gender = (user['gender'] ?? user['uSexe'] ?? '').toString().toLowerCase();
      if (gender.isNotEmpty) {
        _gender = gender.startsWith('m') ? 'm' : (gender.startsWith('f') ? 'f' : null);
      }
    }
  }

  Future<void> _fetchInitData() async {
    setState(() {
      _isLoadingInitData = true;
      _initDataError = null;
    });

    try {
      final response = await _authService.fetchInsRequestInitInfo();
      
      if (response.success && response.data != null) {
        final data = response.data;
        setState(() {
          _bloodTypes = data['blood_types'] ?? [];
          _maritalStatuses = data['marital_statuses'] ?? [];
          
          // Parse locations
          if (data['locations'] is List && (data['locations'] as List).isNotEmpty) {
            final locationsList = data['locations'] as List;
            _locations = locationsList.map((e) => SystemCountry.fromJson(e as Map<String, dynamic>)).toList();
            
            // Extract townships from first location (DRC > Kinshasa > Townships)
            if (_locations.isNotEmpty && _locations[0].children != null && _locations[0].children!.isNotEmpty) {
              final province = _locations[0].children![0];
              if (province.children != null && province.children!.isNotEmpty) {
                final town = province.children![0];
                if (town.children != null) {
                  _townships = town.children!.map((t) => {
                    'id': t.id,
                    'name': t.name,
                    'children': t.children ?? [],
                  }).toList();
                }
              }
            }
          }
          
          _isLoadingInitData = false;
        });
      } else {
        setState(() {
          _initDataError = response.message ?? 'Failed to load init data';
          _isLoadingInitData = false;
        });
      }
    } catch (e) {
      setState(() {
        _initDataError = 'Error: $e';
        _isLoadingInitData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: WillPopScope(
        onWillPop: () async => !_loading,
        child: Stack(children: [ SafeArea(
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
                      onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'request_your_ins'.tr,
                      style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w700, color: ColorPages.COLOR_PRINCIPAL),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Loading or Error State
            if (_isLoadingInitData)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_initDataError != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_initDataError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchInitData,
                        child: Text('retry'.tr),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Content
              Expanded(
                child: Stepper(
                  currentStep: _step,
                  onStepContinue: _onContinue,
                  onStepCancel: _onBack,
                  steps: [
                    Step(title: Text('ins_step_id_scan'.tr), isActive: _step >= 0, content: _buildIdScanStep()),
                    Step(title: Text('ins_step_personal_info'.tr), isActive: _step >= 1, content: _buildPersonalInfoStep()),
                    Step(title: Text('ins_step_address'.tr), isActive: _step >= 2, content: _buildAddressStep()),
                    Step(title: Text('ins_step_photo'.tr), isActive: _step >= 3, content: _buildPhotoStep()),
                    Step(title: Text('ins_step_review'.tr), isActive: _step >= 4, content: _buildReviewStep()),
                  ],
                  controlsBuilder: (context, details) {
                    final canContinue = !_loading && _canProceedFromStep(_step);
                    return Row(
                      children: [
                        ElevatedButton(
                          onPressed: canContinue ? details.onStepContinue : null,
                          style: ElevatedButton.styleFrom(backgroundColor: ColorPages.COLOR_PRINCIPAL, foregroundColor: Colors.white),
                          child: _step == 4
                              ? (_loading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('submit'.tr),
                                      ],
                                    )
                                  : Text('submit'.tr))
                              : Text('continue'.tr),
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
      if (_loading)
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'submitting_ins_request'.tr,
                      style: GoogleFonts.ubuntu(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    ),
  );
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0: // ID scan
        return _idPhoto != null && _idOk && !_idChecking;
      case 1: // Personal info
        return _firstName.text.isNotEmpty && 
               _lastName.text.isNotEmpty && 
               _dob.text.isNotEmpty && 
               _gender != null &&
               _selectedBloodTypeId != null &&
               _selectedMaritalStatusId != null;
      case 2: // Address
        return _selectedTownshipId != null &&
               _quarter.text.isNotEmpty &&
               _avenue.text.isNotEmpty &&
               _houseNumber.text.isNotEmpty;
      case 3: // Photo
        return _facePhoto != null && _faceOk && !_faceChecking;
      case 4: // Review
        return true;
      default:
        return false;
    }
  }

  Widget _buildIdScanStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.badge_outlined, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text('id_scan_tip'.tr, style: const TextStyle(fontSize: 13.5, color: Colors.black87)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: _idPhoto == null
                ? Center(child: Icon(Icons.credit_card, size: 48, color: Colors.grey.shade600))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_idPhoto!, fit: BoxFit.cover),
                      if (_idChecking)
                        Container(
                          color: Colors.black.withOpacity(0.25),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickIdFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text('scan_id_card'.tr),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickIdFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text('choose_id_photo'.tr),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_idPhoto == null)
          Text('id_required'.tr, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)
        else if (!_idOk && !_idChecking && _idErrorKey != null)
          Text(_idErrorKey!.tr, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)
        else if (_idOk && !_idChecking)
          Text('id_detected_ok'.tr, style: const TextStyle(color: Colors.green), textAlign: TextAlign.center),
      ],
    );
  }

  Future<void> _pickIdFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x != null) {
      final file = File(x.path);
      setState(() {
        _idPhoto = file;
        _idOk = false;
        _idErrorKey = null;
      });
      await _validateIdCard(file);
    }
  }

  Future<void> _pickIdFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) {
      final file = File(x.path);
      setState(() {
        _idPhoto = file;
        _idOk = false;
        _idErrorKey = null;
      });
      await _validateIdCard(file);
    }
  }

  Future<void> _validateIdCard(File file) async {
    try {
      if (!mounted) return;
      setState(() => _idChecking = true);

  final inputImage = InputImage.fromFilePath(file.path);
  // Text recognition (auto script)
  final recognizer = TextRecognizer();
  final recognized = await recognizer.processImage(inputImage);
  await recognizer.close();

  final fullText = recognized.text.toUpperCase();

      bool isMrz = false;
      // Basic MRZ detection: lines of 30-44 chars with many '<'
      final lines = fullText.split(RegExp(r"\r?\n"));
      int mrzLike = 0;
      for (final l in lines) {
        final s = l.trim();
        if (s.length >= 25 && s.length <= 50) {
          final ltCount = s.split('<').length - 1;
          if (ltCount >= (s.length * 0.15)) {
            mrzLike += 1;
          }
        }
      }
      if (mrzLike >= 2) isMrz = true;

      final keywords = <String>{
        'IDENTITY', 'IDENTIFICATION', 'NATIONAL', 'CARD', 'ID',
        'CARTE', 'IDENTITÉ', 'IDENTITE', 'NATIONALE', 'REPUBLIQUE', 'RÉPUBLIQUE', 'REPUBLIQUE DEMOCRATIQUE',
        'DATE OF BIRTH', 'DATE DE NAISSANCE', 'BIRTH', 'NAISSANCE',
        'SEX', 'SEXE', 'EXPIRY', 'EXPIRATION', 'EXPIRE', 'VALIDITE', 'VALIDITÉ',
        'NUMBER', 'NUMERO', 'N°', 'Nº'
      };
      int hits = 0;
      for (final k in keywords) {
        if (fullText.contains(k)) hits++;
      }

      // Barcode scan (PDF417 preferred for IDs)
      bool hasIdBarcode = false;
      IdExtractedData? parsedFromBarcode;
      try {
        final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.pdf417, BarcodeFormat.qrCode]);
        final barcodes = await barcodeScanner.processImage(inputImage);
        await barcodeScanner.close();
        for (final b in barcodes) {
          if (b.format == BarcodeFormat.pdf417) {
            hasIdBarcode = true;
            final raw = b.rawValue ?? '';
            final data = IdExtraction.parseAAMVAFromPdf417(raw);
            if (data != null) {
              parsedFromBarcode = data;
              break;
            }
          } else if (b.format == BarcodeFormat.qrCode) {
            hasIdBarcode = true;
          }
        }
      } catch (_) {
        // ignore barcode errors; keep text-only heuristic
      }

      // Heuristic decision (text OR barcode)
      bool ok = false;
      IdExtractedData? parsed;
      if (parsedFromBarcode != null) {
        parsed = parsedFromBarcode;
        ok = true;
      }
      // Try MRZ parse if detected
      if (!ok && isMrz) {
  final m = IdExtraction.parseMRZ(recognized.text);
        if (m != null) {
          parsed = m;
          ok = true;
        }
      }
      // Try OCR heuristics
      if (!ok && (hits >= 2 && fullText.length > 40)) {
  final h = IdExtraction.parseTextHeuristics(recognized.text);
        if (h != null) {
          parsed = h;
          ok = true;
        } else if (hasIdBarcode) {
          ok = true; // accept as valid ID without extracted fields
        }
      } else if (!ok && hasIdBarcode) {
        ok = true; // accept as valid ID even if we couldn't parse fields
      }

      if (!mounted) return;
      setState(() {
        _idOk = ok;
        _idErrorKey = ok ? null : 'id_not_recognized';
        _idData = parsed;
        _idChecking = false;
      });

      if (ok && parsed != null) {
        _applyIdData(parsed);
      }

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('id_not_recognized'.tr)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _idOk = false;
        _idChecking = false;
        _idErrorKey = 'id_validation_error';
      });
    }
  }

  Widget _buildPersonalInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstName,
            decoration: InputDecoration(labelText: 'first_name'.tr, border: const OutlineInputBorder()),
            validator: (v) => v == null || v.isEmpty ? 'field_required'.tr : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastName,
            decoration: InputDecoration(labelText: 'last_name'.tr, border: const OutlineInputBorder()),
            validator: (v) => v == null || v.isEmpty ? 'field_required'.tr : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _middleName,
            decoration: InputDecoration(labelText: '${'middle_name'.tr} (${'optional'.tr})', border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: InputDecoration(labelText: '${'email'.tr} (${'optional'.tr})', border: const OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            decoration: InputDecoration(labelText: '${'phone'.tr} (${'optional'.tr})', border: const OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dob,
            decoration: InputDecoration(
              labelText: 'date_of_birth'.tr,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: _pickDateOfBirth,
            validator: (v) => v == null || v.isEmpty ? 'field_required'.tr : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(labelText: 'gender'.tr, border: const OutlineInputBorder()),
            items: [
              DropdownMenuItem(value: 'm', child: Text('male'.tr)),
              DropdownMenuItem(value: 'f', child: Text('female'.tr)),
            ],
            onChanged: (v) => setState(() => _gender = v),
            validator: (v) => v == null ? 'field_required'.tr : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedBloodTypeId,
            decoration: InputDecoration(labelText: 'blood_type'.tr, border: const OutlineInputBorder()),
            items: _bloodTypes.map((bt) {
              final id = bt['id'].toString();
              final name = bt['name'].toString();
              return DropdownMenuItem(value: id, child: Text(name));
            }).toList(),
            onChanged: (v) => setState(() => _selectedBloodTypeId = v),
            validator: (v) => v == null ? 'field_required'.tr : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedMaritalStatusId,
            decoration: InputDecoration(labelText: 'marital_status'.tr, border: const OutlineInputBorder()),
            items: _maritalStatuses.map((ms) {
              final id = ms['id'].toString();
              final name = ms['name'].toString();
              return DropdownMenuItem(value: id, child: Text(name));
            }).toList(),
            onChanged: (v) => setState(() => _selectedMaritalStatusId = v),
            validator: (v) => v == null ? 'field_required'.tr : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedTownshipId,
          decoration: InputDecoration(labelText: 'township'.tr, border: const OutlineInputBorder()),
          items: _townships.map((t) {
            final id = t['id'].toString();
            final name = t['name'].toString();
            return DropdownMenuItem(value: id, child: Text(name));
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedTownshipId = v;
              _quarter.clear();
            });
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _quarter,
          decoration: InputDecoration(labelText: 'address_quarter'.tr, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _avenue,
          decoration: InputDecoration(labelText: 'avenue'.tr, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _houseNumber,
          decoration: InputDecoration(labelText: 'house_number'.tr, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.face, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text('face_photo_tip'.tr, style: const TextStyle(fontSize: 13.5, color: Colors.black87))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: _facePhoto == null
                ? Center(child: Icon(Icons.face, size: 48, color: Colors.grey.shade600))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_facePhoto!, fit: BoxFit.cover),
                      if (_faceChecking)
                        Container(
                          color: Colors.black.withOpacity(0.25),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFaceFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text('take_photo'.tr),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFaceFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text('choose_photo'.tr),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_facePhoto == null)
          Text('face_photo_required'.tr, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)
        else if (!_faceOk && !_faceChecking && _faceErrorKey != null)
          Text(_faceErrorKey!.tr, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)
        else if (_faceOk && !_faceChecking)
          Text('face_detected_ok'.tr, style: const TextStyle(color: Colors.green), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ins_review_title'.tr, style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _reviewItem('first_name'.tr, _firstName.text),
        _reviewItem('last_name'.tr, _lastName.text),
        if (_middleName.text.isNotEmpty) _reviewItem('middle_name'.tr, _middleName.text),
        if (_email.text.isNotEmpty) _reviewItem('email'.tr, _email.text),
        if (_phone.text.isNotEmpty) _reviewItem('phone'.tr, _phone.text),
        _reviewItem('date_of_birth'.tr, _dob.text),
        _reviewItem('gender'.tr, _gender == 'm' ? 'male'.tr : 'female'.tr),
        _reviewItem('blood_type'.tr, _bloodTypes.firstWhere((bt) => bt['id'].toString() == _selectedBloodTypeId, orElse: () => <String, Object>{})['name'] ?? ''),
        _reviewItem('marital_status'.tr, _maritalStatuses.firstWhere((ms) => ms['id'].toString() == _selectedMaritalStatusId, orElse: () => <String, Object>{})['name'] ?? ''),
        _reviewItem('township'.tr, _townships.firstWhere((t) => t['id'].toString() == _selectedTownshipId, orElse: () => <String, Object>{})['name'] ?? ''),
        _reviewItem('address_quarter'.tr, _quarter.text),
        _reviewItem('avenue'.tr, _avenue.text),
        _reviewItem('house_number'.tr, _houseNumber.text),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text('ins_review_confirm'.tr, style: const TextStyle(fontSize: 13.5))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ),
          Expanded(child: Text(value, style: GoogleFonts.ubuntu())),
        ],
      ),
    );
  }

  Future<void> _pickFaceFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x != null) {
      final file = File(x.path);
      setState(() {
        _facePhoto = file;
        _faceOk = false;
        _faceErrorKey = null;
      });
      await _validateFacePhoto(file);
    }
  }

  Future<void> _pickFaceFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) {
      final file = File(x.path);
      setState(() {
        _facePhoto = file;
        _faceOk = false;
        _faceErrorKey = null;
      });
      await _validateFacePhoto(file);
    }
  }

  Future<void> _validateFacePhoto(File file) async {
    try {
      if (!mounted) return;
      setState(() => _faceChecking = true);

      final inputImage = InputImage.fromFilePath(file.path);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: false,
          enableClassification: false,
        ),
      );
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      final ok = faces.isNotEmpty;

      if (!mounted) return;
      setState(() {
        _faceOk = ok;
        _faceErrorKey = ok ? null : 'no_face_detected';
        _faceChecking = false;
      });

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('no_face_detected'.tr)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _faceOk = false;
        _faceChecking = false;
        _faceErrorKey = 'face_validation_error';
      });
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dobValue ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dobValue = picked;
        _dob.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _applyIdData(IdExtractedData d) {
    if ((d.firstName ?? '').isNotEmpty) _firstName.text = d.firstName!;
    if ((d.lastName ?? '').isNotEmpty) _lastName.text = d.lastName!;
    
    if ((d.sex ?? '').isNotEmpty) {
      final s = d.sex!.toLowerCase();
      if (s.startsWith('m')) _gender = 'm';
      if (s.startsWith('f')) _gender = 'f';
    }
    
    if ((d.address ?? '').isNotEmpty) _avenue.text = d.address!;
    
    if (d.dob != null) {
      _dobValue = d.dob;
      _dob.text = '${d.dob!.day}/${d.dob!.month}/${d.dob!.year}';
    }
    
    setState(() {});
  }

  void _onBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onContinue() {
    if (_step < 4) {
      setState(() => _step += 1);
    } else {
      _submitRequest();
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _loading = true);

    try {
      // Prepare request data
      final requestData = {
        'first_name': _firstName.text,
        'last_name': _lastName.text,
        if (_middleName.text.isNotEmpty) 'middle_name': _middleName.text,
        if (_email.text.isNotEmpty) 'email': _email.text,
        if (_phone.text.isNotEmpty) 'phone_number': _phone.text,
        'date_of_birth': _dobValue?.toIso8601String(),
        'gender': _gender,
        'ref_blood_type_id': _selectedBloodTypeId,
        'ref_marital_status_id': _selectedMaritalStatusId,
        'ref_township_entity_id': _selectedTownshipId,
        'avenue': _avenue.text,
        'house_number': _houseNumber.text,
      };

      // Submit request
      final response = await _authService.submitInsRequest(requestData);

      if (!mounted) return;

      if (response.success) {
        // Extract sys_ins_request_id
        final sysInsRequestId = response.data?['sys_ins_request_id']?.toString() ?? 
                                response.data?['ins_request_id']?.toString() ?? 
                                response.data?['id']?.toString();

        // Upload photos if we have an ID
        if (sysInsRequestId != null && _idPhoto != null && _facePhoto != null) {
          await _authService.uploadInsRequestIdPhoto(sysInsRequestId, _idPhoto!);
          await _authService.uploadInsRequestFacePhoto(sysInsRequestId, _facePhoto!);
        }

        // Keep loading spinner visible while we fetch details
        final detailsResp = await _authService.getMyInsRequest();
        if (!mounted) return;
        setState(() => _loading = false);
        if (detailsResp.success && detailsResp.data is Map) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ins_request_success'.tr)),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => InsRequestDetailsPage(
                data: Map<String, dynamic>.from(detailsResp.data as Map),
              ),
            ),
            (route) => route.isFirst,
          );
          return;
        }

        // Show success dialog
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text('success'.tr),
              ],
            ),
            content: Text('ins_request_success'.tr),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: Text('ok'.tr),
              ),
            ],
          ),
        );
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'ins_request_failed'.tr)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

