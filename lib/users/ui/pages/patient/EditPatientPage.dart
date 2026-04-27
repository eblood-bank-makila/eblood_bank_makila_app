import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/widgets/GradientScaffold.dart';
import '../../../../core/rbac/services/rbac_guard.dart';
import '../../../../core/rbac/providers/rbac_provider.dart';
import '../../../../core/rbac/models/rbac_models.dart';
import '../../../business/models/patient/PatientModel.dart';
import '../../../business/service/PatientNetworkServiceImpl.dart';

class EditPatientPage extends ConsumerStatefulWidget {
  final PatientModel patient;
  const EditPatientPage({super.key, required this.patient});

  @override
  ConsumerState<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends ConsumerState<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  String? _gender;
  String? _bloodType;
  bool _submitting = false;

  late final PatientNetworkServiceImpl _service;

  @override
  void initState() {
    super.initState();
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_hosp_home_patients',
    );
    final crudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
      'flutter_apps_eblood_bank_hosp_home_patients',
    );
    _service = PatientNetworkServiceImpl(crudInfo);
    _firstNameCtrl = TextEditingController(text: widget.patient.demographics.firstName);
    _lastNameCtrl = TextEditingController(text: widget.patient.demographics.lastName);
    _dobCtrl = TextEditingController(text: widget.patient.demographics.dateOfBirth);
    _phoneCtrl = TextEditingController(text: widget.patient.contact.phonePrimary ?? '');
    _emailCtrl = TextEditingController(text: widget.patient.contact.email ?? '');
    // Normalize gender from backend format (m/f/other) to dropdown format (MALE/FEMALE/OTHER)
    _gender = _normalizeGender(widget.patient.demographics.gender);
    _bloodType = widget.patient.demographics.bloodType;
  }

  /// Normalize gender value from backend format to dropdown format
  String _normalizeGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'MALE';
    final normalized = gender.toLowerCase().trim();
    switch (normalized) {
      case 'm':
      case 'male':
        return 'MALE';
      case 'f':
      case 'female':
        return 'FEMALE';
      case 'other':
      case 'prefer_not_to_say':
        return 'OTHER';
      default:
        return 'MALE';
    }
  }

  /// Convert dropdown format back to backend format
  String _toBackendGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'm';
    switch (gender) {
      case 'MALE':
        return 'm';
      case 'FEMALE':
        return 'f';
      case 'OTHER':
        return 'other';
      default:
        return 'm';
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final payload = {
      'demographics': {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'date_of_birth': _dobCtrl.text.trim(),
        'gender': _toBackendGender(_gender), // Convert to backend format (m/f/other)
        if (_bloodType != null && _bloodType!.isNotEmpty) 'blood_type': _bloodType,
      },
      'contact': {
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone_primary': _phoneCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      }
    };

    final resp = await _service.updatePatient(widget.patient.id ?? '', payload);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('patient_updated_successfully'.tr)),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final genders = const ['MALE', 'FEMALE', 'OTHER'];
    final bloodTypes = const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'UNKNOWN'];

    return GradientScaffold(
      appBar: AppBar(
        title: Text('edit_patient'.tr),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _firstNameCtrl,
                decoration: InputDecoration(labelText: 'first_name'.tr),
                validator: (v) => v == null || v.trim().isEmpty ? 'required_field'.tr : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: InputDecoration(labelText: 'last_name'.tr),
                validator: (v) => v == null || v.trim().isEmpty ? 'required_field'.tr : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dobCtrl,
                decoration: InputDecoration(labelText: 'date_of_birth'.tr, hintText: 'YYYY-MM-DD'),
                validator: (v) => v == null || v.trim().isEmpty ? 'required_field'.tr : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'gender'.tr),
                items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null || v.isEmpty ? 'required_field'.tr : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bloodType,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'blood_type'.tr),
                items: bloodTypes.map((bt) => DropdownMenuItem(value: bt, child: Text(bt))).toList(),
                onChanged: (v) => setState(() => _bloodType = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'phone_number'.tr),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: 'email'.tr),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: ColorPages.COLOR_PRINCIPAL),
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text('save_patient'.tr),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

