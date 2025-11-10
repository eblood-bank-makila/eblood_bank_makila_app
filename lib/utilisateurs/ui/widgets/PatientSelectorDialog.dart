import 'dart:async';

import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/PatientNetworkServiceImpl.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/patient/AddPatientPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientSelectorDialog extends StatefulWidget {
  const PatientSelectorDialog({super.key});

  @override
  State<PatientSelectorDialog> createState() => _PatientSelectorDialogState();
}

class _PatientSelectorDialogState extends State<PatientSelectorDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final _patientService = PatientNetworkServiceImpl();
  final _formKey = GlobalKey<FormState>();

  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _initialLoad = false;
  String? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    // Load all patients initially
    _loadAllPatients();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllPatients() async {
    setState(() => _loading = true);
    try {
      // Fetch all patients (no search query)
      final IApiResponse res = await _patientService.getPatients(limit: 100);
      final data = res.data;
      List<Map<String, dynamic>> items = [];

      // Parse response - handle both direct list and nested structure
      if (data is Map) {
        if (data['patients'] is List) {
          items = List<Map<String, dynamic>>.from((data['patients'] as List).whereType<Map>());
        } else if (data['data'] is List) {
          items = List<Map<String, dynamic>>.from((data['data'] as List).whereType<Map>());
        }
      } else if (data is List) {
        items = List<Map<String, dynamic>>.from(data.whereType<Map>());
      }

      setState(() {
        _results = items;
        _initialLoad = true;
      });
    } catch (e) {
      debugPrint('Error loading patients: $e');
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      // If search is cleared, reload all patients
      _loadAllPatients();
    } else {
      _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
    }
  }

  Future<void> _runSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      _loadAllPatients();
      return;
    }
    setState(() => _loading = true);
    try {
      final IApiResponse res = await _patientService.searchPatients(query, limit: 20);
      final data = res.data;
      List<Map<String, dynamic>> items = [];

      // Parse response - handle both direct list and nested structure
      if (data is Map) {
        if (data['patients'] is List) {
          items = List<Map<String, dynamic>>.from((data['patients'] as List).whereType<Map>());
        } else if (data['data'] is List) {
          items = List<Map<String, dynamic>>.from((data['data'] as List).whereType<Map>());
        }
      } else if (data is List) {
        items = List<Map<String, dynamic>>.from(data.whereType<Map>());
      }

      setState(() => _results = items);
    } catch (e) {
      debugPrint('Error searching patients: $e');
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _confirmSelection() {
    if (_selectedPatientId == null || _selectedPatientId!.isEmpty) {
      Get.snackbar('warning'.tr, 'please_select_patient'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Navigator.of(context).pop<String>(_selectedPatientId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'select_patient'.tr,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Search bar and add button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'search_patients'.tr,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _loadAllPatients();
                                  },
                                )
                              : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () async {
                    final created = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddPatientPage()),
                    );
                    if (created == true) {
                      _loadAllPatients();
                    }
                  },
                  icon: const Icon(Icons.add),
                  tooltip: 'add_new_patient'.tr,
                ),
              ],
            ),
          ),

          // Patient list
          Expanded(
            child: _loading && _results.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'no_patients_found'.tr,
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final id = (item['id'] ?? item['_id'] ?? '').toString();
                          final demo = (item['demographics'] is Map) ? (item['demographics'] as Map) : null;
                          final first = (demo?['first_name'] ?? demo?['firstName'] ?? '').toString();
                          final last = (demo?['last_name'] ?? demo?['lastName'] ?? '').toString();
                          final fullName = '$first $last'.trim();
                          final bloodType = (demo?['blood_type'] ?? '').toString();
                          final gender = (demo?['gender'] ?? '').toString();

                          final isSelected = _selectedPatientId == id;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withOpacity(0.1),
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                color: isSelected ? Colors.white : Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              fullName.isNotEmpty ? fullName : (item['name']?.toString() ?? id),
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (id.isNotEmpty) Text(id, style: const TextStyle(fontSize: 12)),
                                if (bloodType.isNotEmpty || gender.isNotEmpty)
                                  Text(
                                    [if (bloodType.isNotEmpty) bloodType, if (gender.isNotEmpty) gender].join(' • '),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.blue)
                                : const Icon(Icons.circle_outlined, color: Colors.grey),
                            onTap: () => setState(() => _selectedPatientId = id),
                          );
                        },
                      ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    child: Text('continue'.tr),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

