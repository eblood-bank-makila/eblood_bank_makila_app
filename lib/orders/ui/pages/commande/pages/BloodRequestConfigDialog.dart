import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/utilisateurs/ui/widgets/PatientSelectorDialog.dart';
import 'package:eblood_bank_mak_app/core/rbac/models/rbac_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class BloodRequestConfigDialog extends StatefulWidget {
  final List<RbacCollectionCrudItem> patientCrudInfo;
  const BloodRequestConfigDialog({super.key, required this.patientCrudInfo});

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

  // Build section label with icon
  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ColorPages.COLOR_PRINCIPAL),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Build request for selector (Patient or Storage)
  Widget _buildRequestForSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            icon: Iconsax.user,
            label: 'patient'.tr,
            isSelected: _requestFor == 'patient',
            onTap: () => setState(() => _requestFor = 'patient'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            icon: Iconsax.box,
            label: 'storage'.tr,
            isSelected: _requestFor == 'storage',
            onTap: () => setState(() => _requestFor = 'storage'),
          ),
        ),
      ],
    );
  }

  // Build option card
  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build patient selector
  Widget _buildPatientSelector() {
    if (_requestFor != 'patient') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionLabel('select_patient'.tr, Iconsax.user_octagon),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final selectedId = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => PatientSelectorDialog(crudInfo: widget.patientCrudInfo),
            );
            if (selectedId != null && selectedId.isNotEmpty) {
              setState(() => _patientId = selectedId);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _patientId != null ? ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _patientId != null ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
                width: _patientId != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.user_tick,
                  color: _patientId != null ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _patientId ?? 'select_patient'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 15,
                      fontWeight: _patientId != null ? FontWeight.w600 : FontWeight.normal,
                      color: _patientId != null ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade600,
                    ),
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build request type chips
  Widget _buildRequestTypeChips() {
    final types = [
      {'value': 'TRAUMA', 'icon': Iconsax.danger, 'label': 'Trauma'},
      {'value': 'ANEMIA_SEVERE', 'icon': Iconsax.health, 'label': 'Anémie Sévère'},
      {'value': 'ONCOLOGY', 'icon': Iconsax.hospital, 'label': 'Oncologie'},
      {'value': 'SURGICAL_BLEEDING', 'icon': Iconsax.scissor, 'label': 'Chirurgie'},
      {'value': 'OBSTETRIC', 'icon': Iconsax.woman, 'label': 'Obstétrique'},
      {'value': 'STORAGE', 'icon': Iconsax.box, 'label': 'Stockage'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _requestType == type['value'];
        return InkWell(
          onTap: () => setState(() => _requestType = type['value'] as String),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type['icon'] as IconData,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  type['label'] as String,
                  style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Build urgency level chips
  Widget _buildUrgencyLevelChips() {
    final levels = [
      {'value': 'ROUTINE', 'color': Colors.green, 'label': 'Routine'},
      {'value': 'PRIORITY', 'color': Colors.blue, 'label': 'Priorité'},
      {'value': 'URGENT', 'color': Colors.orange, 'label': 'Urgent'},
      {'value': 'CRITICAL', 'color': Colors.red, 'label': 'Critique'},
      {'value': 'EMERGENCY', 'color': Colors.red.shade900, 'label': 'Urgence'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final isSelected = _urgencyLevel == level['value'];
        final color = level['color'] as Color;
        return InkWell(
          onTap: () => setState(() => _urgencyLevel = level['value'] as String),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              level['label'] as String,
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Gradient Header
            Container(
              margin: const EdgeInsets.all(16),
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
                      Iconsax.clipboard_text,
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
                          'configure_blood_request'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Remplissez les détails de votre demande',
                          style: GoogleFonts.ubuntu(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Request For Section
                      _buildSectionLabel('request_for'.tr, Iconsax.category),
                      const SizedBox(height: 12),
                      _buildRequestForSelector(),

                      // Patient Selector
                      _buildPatientSelector(),

                      // Request Type Section
                      const SizedBox(height: 20),
                      _buildSectionLabel('request_type'.tr, Iconsax.health),
                      const SizedBox(height: 12),
                      _buildRequestTypeChips(),

                      // Urgency Level Section
                      const SizedBox(height: 20),
                      _buildSectionLabel('urgency_level'.tr, Iconsax.flash_1),
                      const SizedBox(height: 12),
                      _buildUrgencyLevelChips(),

                      // Reason Section
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildSectionLabel('request_reason'.tr, Iconsax.message_text),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Optionnel',
                              style: GoogleFonts.ubuntu(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Décrivez la raison de votre demande...',
                          hintStyle: GoogleFonts.ubuntu(color: Colors.grey.shade400),
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
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (v) {
                          if (_requestFor == 'patient' && (_patientId == null || _patientId!.isEmpty)) {
                            return 'please_select_patient'.tr;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
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
                                  fontSize: 15,
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
                              onPressed: () {
                                if (_formKey.currentState?.validate() != true) return;
                                Navigator.of(context).pop(<String, String?>{
                                  'request_for': _requestFor,
                                  'patient_id': _requestFor == 'patient' ? _patientId : null,
                                  'request_type': _requestType,
                                  'urgency_level': _urgencyLevel,
                                  'request_reason': _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'continue'.tr,
                                    style: GoogleFonts.ubuntu(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Iconsax.arrow_right_3, size: 20, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

