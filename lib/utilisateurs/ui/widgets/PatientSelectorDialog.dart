import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/PatientNetworkServiceImpl.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/patient/AddPatientPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class PatientSelectorDialog extends StatefulWidget {
  const PatientSelectorDialog({super.key});

  @override
  State<PatientSelectorDialog> createState() => _PatientSelectorDialogState();
}

class _PatientSelectorDialogState extends State<PatientSelectorDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final _patientService = PatientNetworkServiceImpl();

  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

          // Header with gradient
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorPages.COLOR_PRINCIPAL,
                  Colors.red.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.user_search,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'select_patient'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _results.isEmpty && !_loading
                            ? 'Aucun patient trouvé'
                            : '${_results.length} ${_results.length == 1 ? 'patient' : 'patients'}',
                        style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search bar and add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.ubuntu(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'search_patients'.tr,
                      hintStyle: GoogleFonts.ubuntu(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      prefixIcon: Icon(Iconsax.search_normal_1, color: Colors.grey.shade600),
                      suffixIcon: _loading
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ColorPages.COLOR_PRINCIPAL,
                                ),
                              ),
                            )
                          : _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Iconsax.close_circle, color: Colors.grey.shade600),
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
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorPages.COLOR_PRINCIPAL,
                        Colors.red.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final created = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddPatientPage()),
                      );
                      if (created == true) {
                        _loadAllPatients();
                      }
                    },
                    icon: const Icon(Iconsax.user_add, color: Colors.white),
                    tooltip: 'add_new_patient'.tr,
                  ),
                ),
              ],
            ),
          ),

          // Patient list
          Expanded(
            child: _loading && _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: ColorPages.COLOR_PRINCIPAL),
                        const SizedBox(height: 16),
                        Text(
                          'Chargement des patients...',
                          style: GoogleFonts.ubuntu(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: FadeInUp(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Iconsax.user_search,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'no_patients_found'.tr,
                                style: GoogleFonts.ubuntu(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Essayez une autre recherche',
                                style: GoogleFonts.ubuntu(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
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

                          return FadeInUp(
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            child: InkWell(
                              onTap: () => setState(() => _selectedPatientId = id),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? ColorPages.COLOR_PRINCIPAL
                                        : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: [
                                                  ColorPages.COLOR_PRINCIPAL,
                                                  Colors.red.shade700,
                                                ],
                                              )
                                            : null,
                                        color: isSelected ? null : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Iconsax.user,
                                        color: isSelected ? Colors.white : Colors.grey.shade600,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Patient info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName.isNotEmpty ? fullName : (item['name']?.toString() ?? id),
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? ColorPages.COLOR_PRINCIPAL
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (id.isNotEmpty)
                                            Text(
                                              id,
                                              style: GoogleFonts.ubuntu(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          if (bloodType.isNotEmpty || gender.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  if (bloodType.isNotEmpty) ...[
                                                    Icon(
                                                      Iconsax.health,
                                                      size: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      bloodType,
                                                      style: GoogleFonts.ubuntu(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                  if (bloodType.isNotEmpty && gender.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: Text(
                                                        '•',
                                                        style: TextStyle(color: Colors.grey.shade400),
                                                      ),
                                                    ),
                                                  if (gender.isNotEmpty)
                                                    Text(
                                                      gender,
                                                      style: GoogleFonts.ubuntu(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Selection indicator
                                    Icon(
                                      isSelected ? Iconsax.tick_circle5 : Iconsax.record_circle,
                                      color: isSelected
                                          ? ColorPages.COLOR_PRINCIPAL
                                          : Colors.grey.shade400,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPages.COLOR_PRINCIPAL,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'continue'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Iconsax.tick_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
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

