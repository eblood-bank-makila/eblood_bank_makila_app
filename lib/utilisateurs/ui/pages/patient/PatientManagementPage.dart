import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/widgets/GradientScaffold.dart';
import '../../../business/service/PatientNetworkServiceImpl.dart';
import '../../../business/models/patient/PatientModel.dart';
import 'AddPatientPage.dart';
import 'PatientDetailsPage.dart';

class PatientManagementPage extends StatefulWidget {
  const PatientManagementPage({super.key});

  @override
  State<PatientManagementPage> createState() => _PatientManagementPageState();
}

class _PatientManagementPageState extends State<PatientManagementPage> {
  final _service = PatientNetworkServiceImpl();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  List<PatientModel> _patients = const [];
  int _page = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients({String? query, bool reset = true}) async {
    setState(() => _loading = true);
    final resp = await _service.getPatients(page: reset ? 0 : _page, limit: _limit, searchQuery: query);
    if (mounted) {
      if (resp.success) {
        final parsed = PatientModel.listFromResponse(resp.data);
        setState(() {
          _patients = parsed;
          _page = reset ? 0 : _page;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (resp.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.message!)));
        }
      }
    }
  }

  Future<void> _onAddPatient() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPatientPage()),
    );
    if (result == true) {
      _fetchPatients(reset: true);
    }
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('no_patients_found'.tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _patients.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = _patients[index];
        final name = [p.demographics.firstName, p.demographics.middleName, p.demographics.lastName]
            .where((e) => e != null && e.toString().isNotEmpty)
            .join(' ');
        final subtitleParts = <String>[];
        if (p.demographics.gender.isNotEmpty) subtitleParts.add(p.demographics.gender);
        if (p.demographics.bloodType != null && p.demographics.bloodType!.isNotEmpty) subtitleParts.add(p.demographics.bloodType!);
        if (p.contact.phonePrimary != null && p.contact.phonePrimary!.isNotEmpty) subtitleParts.add(p.contact.phonePrimary!);

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(name.isNotEmpty ? name : 'patient_details'.tr),
          subtitle: Text(subtitleParts.join(' • ')),
          onTap: () {
            if (p.id == null || p.id!.isEmpty) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PatientDetailsPage(patientId: p.id!)),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text('patient_management'.tr),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchPatients(reset: true),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'search_patients'.tr,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (value) => _fetchPatients(query: value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _fetchPatients(reset: true);
                  },
                )
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        onPressed: _onAddPatient,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

