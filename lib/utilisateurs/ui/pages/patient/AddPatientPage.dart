import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/widgets/GradientScaffold.dart';
import '../../../business/service/PatientNetworkServiceImpl.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _gender;
  String? _bloodType;

  final _service = PatientNetworkServiceImpl();
  bool _submitting = false;

  Future<void> _submit() async {
    try {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final payload = {
      'demographics': {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'date_of_birth': _dobCtrl.text.trim(),
        'gender': _gender ?? 'MALE',
        if (_bloodType != null && _bloodType!.isNotEmpty) 'blood_type': _bloodType,
      },
      'contact': {
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone_primary': _phoneCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      }
    };

    final resp = await _service.createPatient(payload);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (resp.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('patient_created_successfully'.tr)),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp.message ?? 'Error')),
      );
    }
    } catch (e) {
      debugPrint('Error creating patient: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final genders = const ['MALE', 'FEMALE', 'OTHER'];
    final bloodTypes = const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'UNKNOWN'];

    return GradientScaffold(
      appBar: AppBar(
        title: Text('add_patient'.tr),
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
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'date_of_birth'.tr,
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final now = DateTime.now();
                  final initial = DateTime(now.year - 25, now.month, now.day);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1900, 1, 1),
                    lastDate: now,
                    helpText: 'date_of_birth'.tr,
                  );
                  if (picked != null) {
                    final y = picked.year.toString().padLeft(4, '0');
                    final m = picked.month.toString().padLeft(2, '0');
                    final d = picked.day.toString().padLeft(2, '0');
                    setState(() {
                      _dobCtrl.text = '$y-$m-$d';
                    });
                  }
                },
                validator: (v) => v == null || v.trim().isEmpty ? 'required_field'.tr : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'gender'.tr),
                items: genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null || v.isEmpty ? 'required_field'.tr : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bloodType,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'blood_type'.tr),
                items: bloodTypes
                    .map((bt) => DropdownMenuItem(value: bt, child: Text(bt)))
                    .toList(),
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

