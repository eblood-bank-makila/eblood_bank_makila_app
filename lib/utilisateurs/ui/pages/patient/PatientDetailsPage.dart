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
import 'EditPatientPage.dart';

class PatientDetailsPage extends ConsumerStatefulWidget {
  final String patientId;
  const PatientDetailsPage({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends ConsumerState<PatientDetailsPage> {
  late final PatientNetworkServiceImpl _service;
  bool _loading = true;
  PatientModel? _patient;
  String? _error;

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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final resp = await _service.getPatientDetails(widget.patientId);
    if (!mounted) return;
    if (resp.success && resp.data is Map<String, dynamic>) {
      setState(() {
        _patient = PatientModel.fromJson(Map<String, dynamic>.from(resp.data as Map));
        _loading = false;
      });
    } else {
      setState(() {
        _error = resp.message ?? 'Error';
        _loading = false;
      });
    }
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text('patient_details'.tr),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        actions: [
          if (_patient != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditPatientPage(patient: _patient!),
                  ),
                );
                if (updated == true) {
                  _load();
                }
              },
            )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: Text('retry'.tr),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text([
                          _patient!.demographics.firstName,
                          _patient!.demographics.middleName,
                          _patient!.demographics.lastName,
                        ].whereType<String>().where((e) => e.isNotEmpty).join(' ')),
                        subtitle: Text([
                          _patient!.demographics.gender,
                          _patient!.demographics.bloodType,
                        ].whereType<String>().where((e) => e.isNotEmpty).join(' • ')),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('demographics'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _row('first_name'.tr, _patient!.demographics.firstName),
                      _row('last_name'.tr, _patient!.demographics.lastName),
                      _row('date_of_birth'.tr, _patient!.demographics.dateOfBirth),
                      _row('gender'.tr, _patient!.demographics.gender),
                      _row('blood_type'.tr, _patient!.demographics.bloodType),
                      const SizedBox(height: 12),
                      Text('contact_info'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _row('phone_number'.tr, _patient!.contact.phonePrimary),
                      _row('email'.tr, _patient!.contact.email),
                    ],
                  ),
                ),
    );
  }
}

