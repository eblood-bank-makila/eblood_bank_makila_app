/// Blood Type Input Page
/// Allows users to select the blood type they're searching for

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/search_flow_provider.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../widgets/search_flow_app_bar.dart';
import '../widgets/search_flow_progress_indicator.dart';

class BloodTypeInputPage extends ConsumerStatefulWidget {
  const BloodTypeInputPage({super.key});

  @override
  ConsumerState<BloodTypeInputPage> createState() => _BloodTypeInputPageState();
}

class _BloodTypeInputPageState extends ConsumerState<BloodTypeInputPage> {
  String? _selectedBloodType;
  String? _selectedRhFactor;
  bool _isSearching = false;

  final List<String> _bloodTypes = ['A', 'B', 'AB', 'O'];
  final List<String> _rhFactors = ['+', '-'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchFlowProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: 'select_blood_type'.tr.isEmpty ? 'Select Blood Type' : 'select_blood_type'.tr,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          // Progress indicator
          SearchFlowProgressIndicator(
            currentStep: 2,
            totalSteps: 4,
            stepLabels: [
              'step_city'.tr,
              'step_blood_type'.tr,
              'step_results'.tr,
              'step_confirm'.tr,
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'which_blood_type'.tr.isEmpty 
                        ? 'Which blood type do you need?' 
                        : 'which_blood_type'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'select_blood_group_subtitle'.tr.isEmpty
                        ? 'Select the blood group and Rh factor'
                        : 'select_blood_group_subtitle'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Blood Type Selection
                  Text(
                    'blood_group'.tr.isEmpty ? 'Blood Group' : 'blood_group'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: _bloodTypes.map((type) {
                      final isSelected = _selectedBloodType == type;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: type != _bloodTypes.last ? 8 : 0,
                          ),
                          child: _BloodTypeButton(
                            label: type,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedBloodType = type),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Rh Factor Selection
                  Text(
                    'rh_factor'.tr.isEmpty ? 'Rh Factor' : 'rh_factor'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: _rhFactors.map((rh) {
                      final isSelected = _selectedRhFactor == rh;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: rh != _rhFactors.last ? 12 : 0,
                          ),
                          child: _RhFactorButton(
                            label: rh == '+' ? 'Positive (+)' : 'Negative (-)',
                            value: rh,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedRhFactor = rh),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 48),

                  // Selected Blood Type Preview
                  if (_selectedBloodType != null && _selectedRhFactor != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                            Colors.red.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'searching_for'.tr.isEmpty ? 'Searching for:' : 'searching_for'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_selectedBloodType$_selectedRhFactor',
                            style: GoogleFonts.ubuntu(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: ColorPages.COLOR_PRINCIPAL,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (state.selectedCity != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.location,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  state.selectedCity!.name,
                                  style: GoogleFonts.ubuntu(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.all(16),
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
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_canContinue && !_isSearching) ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isSearching
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'searching'.tr.isEmpty ? 'Searching...' : 'searching'.tr,
                              style: GoogleFonts.ubuntu(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.search_normal_1, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'search'.tr.isEmpty ? 'Search' : 'search'.tr,
                              style: GoogleFonts.ubuntu(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canContinue => _selectedBloodType != null && _selectedRhFactor != null;

  void _onContinue() async {
    if (!_canContinue || _isSearching) return;

    setState(() => _isSearching = true);

    final bloodType = '$_selectedBloodType$_selectedRhFactor';
    
    try {
      await ref.read(searchFlowProvider.notifier).searchBloodProducts(bloodType);
      
      if (mounted) {
        context.push('/blood-search/results');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }
}

class _BloodTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BloodTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RhFactorButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _RhFactorButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.ubuntu(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : ColorPages.COLOR_PRINCIPAL,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value == '+' ? 'Positive' : 'Negative',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
