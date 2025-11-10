import 'package:eblood_bank_mak_app/utilisateurs/ui/widgets/PatientSelectorDialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BloodRequestConfigDialog extends StatefulWidget {
  const BloodRequestConfigDialog({super.key});

  @override
  State<BloodRequestConfigDialog> createState() => _BloodRequestConfigDialogState();
}

class _BloodRequestConfigDialogState extends State<BloodRequestConfigDialog> {
  final _formKey = GlobalKey<FormState>();

  // Fields
  String _requestFor = 'patient'; // 'patient' | 'storage'
  String? _patientId;
  String? _requestType; // TRAUMA, ANEMIA_SEVERE, ONCOLOGY, SURGICAL_BLEEDING, OBSTETRIC, STORAGE
  String? _urgencyLevel; // ROUTINE, PRIORITY, URGENT, CRITICAL, EMERGENCY
  final TextEditingController _reasonCtrl = TextEditingController();


  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Widget _buildPatientSelector() {
    if (_requestFor != 'patient') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('select_patient'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final selectedId = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const PatientSelectorDialog(),
                  );
                  if (selectedId != null && selectedId.isNotEmpty) {
                    setState(() => _patientId = selectedId);
                  }
                },
                child: Text(_patientId == null ? 'select_patient'.tr : _patientId!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('configure_blood_request'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Request for
                Text('request_for'.tr),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _requestFor,
                  items: [
                    DropdownMenuItem(value: 'patient', child: Text('patient'.tr)),
                    DropdownMenuItem(value: 'storage', child: Text('storage'.tr)),
                  ],
                  onChanged: (v) => setState(() => _requestFor = v ?? 'patient'),
                ),

                const SizedBox(height: 12),

                // Patient selection if needed
                _buildPatientSelector(),

                const SizedBox(height: 12),

                // Request type
                Text('request_type'.tr),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _requestType,
                  items: const [
                    DropdownMenuItem(value: 'TRAUMA', child: Text('TRAUMA')),
                    DropdownMenuItem(value: 'ANEMIA_SEVERE', child: Text('ANEMIA_SEVERE')),
                    DropdownMenuItem(value: 'ONCOLOGY', child: Text('ONCOLOGY')),
                    DropdownMenuItem(value: 'SURGICAL_BLEEDING', child: Text('SURGICAL_BLEEDING')),
                    DropdownMenuItem(value: 'OBSTETRIC', child: Text('OBSTETRIC')),
                    DropdownMenuItem(value: 'STORAGE', child: Text('STORAGE')),
                  ],
                  onChanged: (v) => setState(() => _requestType = v),
                ),

                const SizedBox(height: 12),

                // Urgency level
                Text('urgency_level'.tr),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _urgencyLevel,
                  items: const [
                    DropdownMenuItem(value: 'ROUTINE', child: Text('ROUTINE')),
                    DropdownMenuItem(value: 'PRIORITY', child: Text('PRIORITY')),
                    DropdownMenuItem(value: 'URGENT', child: Text('URGENT')),
                    DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL')),
                    DropdownMenuItem(value: 'EMERGENCY', child: Text('EMERGENCY')),
                  ],
                  onChanged: (v) => setState(() => _urgencyLevel = v),
                ),

                const SizedBox(height: 12),

                // Reason
                Text('request_reason'.tr),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'request_reason'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return 'field_required'.tr;
                    }
                    if (_requestFor == 'patient' && (_patientId == null || _patientId!.isEmpty)) {
                      return 'please_select_patient'.tr;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() != true) return;
                        Navigator.of(context).pop(<String, String?>{
                          'request_for': _requestFor,
                          'patient_id': _requestFor == 'patient' ? _patientId : null,
                          'request_type': _requestType,
                          'urgency_level': _urgencyLevel,
                          'request_reason': _reasonCtrl.text.trim(),
                        });
                      },
                      child: Text('continue'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

