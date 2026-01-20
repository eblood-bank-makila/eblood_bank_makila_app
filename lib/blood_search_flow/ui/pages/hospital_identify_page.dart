/// Hospital Identification Page
/// Allows users to identify hospital via QR, gallery, or manual code

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/search_flow_provider.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../widgets/search_flow_app_bar.dart';

enum IdentificationMethod { qrScan, gallery, manualCode }

class HospitalIdentifyPage extends ConsumerStatefulWidget {
  final String? option; // 'view_address' or 'delivery'
  
  const HospitalIdentifyPage({super.key, this.option});

  @override
  ConsumerState<HospitalIdentifyPage> createState() => _HospitalIdentifyPageState();
}

class _HospitalIdentifyPageState extends ConsumerState<HospitalIdentifyPage> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  
  IdentificationMethod _selectedMethod = IdentificationMethod.manualCode;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchFlowProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: 'identify_hospital'.tr.isEmpty ? 'Identify Hospital' : 'identify_hospital'.tr,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'how_identify_hospital'.tr.isEmpty 
                  ? 'How would you like to identify the hospital?' 
                  : 'how_identify_hospital'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'select_method_below'.tr.isEmpty
                  ? 'Select a method below to continue'
                  : 'select_method_below'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 32),

            // Method selection cards
            _MethodCard(
              icon: Iconsax.scan_barcode,
              title: 'scan_qr_code'.tr.isEmpty ? 'Scan QR Code' : 'scan_qr_code'.tr,
              subtitle: 'scan_hospital_qr_subtitle'.tr.isEmpty 
                  ? 'Use your camera to scan the hospital QR code' 
                  : 'scan_hospital_qr_subtitle'.tr,
              isSelected: _selectedMethod == IdentificationMethod.qrScan,
              onTap: () => setState(() => _selectedMethod = IdentificationMethod.qrScan),
            ),

            const SizedBox(height: 12),

            _MethodCard(
              icon: Iconsax.gallery,
              title: 'import_from_gallery'.tr.isEmpty ? 'Import from Gallery' : 'import_from_gallery'.tr,
              subtitle: 'select_qr_image'.tr.isEmpty 
                  ? 'Select a QR code image from your gallery' 
                  : 'select_qr_image'.tr,
              isSelected: _selectedMethod == IdentificationMethod.gallery,
              onTap: () => setState(() => _selectedMethod = IdentificationMethod.gallery),
            ),

            const SizedBox(height: 12),

            _MethodCard(
              icon: Iconsax.keyboard,
              title: 'enter_code_manually'.tr.isEmpty ? 'Enter Code Manually' : 'enter_code_manually'.tr,
              subtitle: 'enter_8_digit_code'.tr.isEmpty 
                  ? 'Enter the 8-digit hospital code' 
                  : 'enter_8_digit_code'.tr,
              isSelected: _selectedMethod == IdentificationMethod.manualCode,
              onTap: () {
                setState(() => _selectedMethod = IdentificationMethod.manualCode);
                _codeFocusNode.requestFocus();
              },
            ),

            const SizedBox(height: 32),

            // Method content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildMethodContent(),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.warning_2, size: 20, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Identified hospital preview
            if (state.identifiedHospital != null) ...[
              _HospitalPreviewCard(hospital: state.identifiedHospital!),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
              onPressed: _isLoading ? null : _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'continue'.tr.isEmpty ? 'Continue' : 'continue'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodContent() {
    switch (_selectedMethod) {
      case IdentificationMethod.qrScan:
        return _buildQrScanContent();
      case IdentificationMethod.gallery:
        return _buildGalleryContent();
      case IdentificationMethod.manualCode:
        return _buildManualCodeContent();
    }
  }

  Widget _buildQrScanContent() {
    return Container(
      key: const ValueKey('qr_scan'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Iconsax.scan_barcode,
              size: 40,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ready_to_scan'.tr.isEmpty ? 'Ready to Scan' : 'ready_to_scan'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'point_camera_at_qr'.tr.isEmpty
                ? 'Point your camera at the hospital QR code'
                : 'point_camera_at_qr'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openQrScanner,
              icon: const Icon(Iconsax.camera, size: 20),
              label: Text(
                'open_camera'.tr.isEmpty ? 'Open Camera' : 'open_camera'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPages.COLOR_PRINCIPAL,
                side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent() {
    return Container(
      key: const ValueKey('gallery'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Iconsax.gallery,
              size: 40,
              color: Colors.purple.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'select_qr_image_title'.tr.isEmpty ? 'Select QR Image' : 'select_qr_image_title'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'choose_image_with_qr'.tr.isEmpty
                ? 'Choose an image containing the hospital QR code'
                : 'choose_image_with_qr'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openGallery,
              icon: const Icon(Iconsax.image, size: 20),
              label: Text(
                'select_image'.tr.isEmpty ? 'Select Image' : 'select_image'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade400,
                side: BorderSide(color: Colors.purple.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualCodeContent() {
    return Container(
      key: const ValueKey('manual'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'hospital_code'.tr.isEmpty ? 'Hospital Code' : 'hospital_code'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            focusNode: _codeFocusNode,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(8),
              UpperCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              hintText: 'XXXXXXXX',
              hintStyle: GoogleFonts.ubuntu(
                color: Colors.grey.shade400,
                letterSpacing: 4,
              ),
              prefixIcon: Icon(Iconsax.code, color: Colors.grey.shade500),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'enter_8_digit_code_hint'.tr.isEmpty
                ? 'Enter the 8-character code found on the hospital\'s documents or signage'
                : 'enter_8_digit_code_hint'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openQrScanner() async {
    final result = await context.push<String>('/blood-search/qr-scanner');
    if (result != null && result.isNotEmpty) {
      await _identifyHospital(result);
    }
  }

  Future<void> _openGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // TODO: Implement QR code extraction from image
        // For now, show a message
        setState(() {
          _errorMessage = 'qr_extraction_not_implemented'.tr.isEmpty
              ? 'QR code extraction from images coming soon'
              : 'qr_extraction_not_implemented'.tr;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'gallery_access_error'.tr.isEmpty
            ? 'Could not access gallery. Please check permissions.'
            : 'gallery_access_error'.tr;
      });
    }
  }

  Future<void> _identifyHospital(String code) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(searchFlowProvider.notifier).identifyHospitalByCode(code);
      
      final state = ref.read(searchFlowProvider);
      if (state.identifiedHospital == null) {
        setState(() {
          _errorMessage = 'hospital_not_found'.tr.isEmpty
              ? 'Hospital not found. Please check the code and try again.'
              : 'hospital_not_found'.tr;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onContinue() async {
    final state = ref.read(searchFlowProvider);
    
    // If hospital already identified, proceed
    if (state.identifiedHospital != null) {
      _proceedToNextStep();
      return;
    }
    
    // Try to identify with manual code
    if (_selectedMethod == IdentificationMethod.manualCode) {
      final code = _codeController.text.trim();
      if (code.length < 8) {
        setState(() {
          _errorMessage = 'code_too_short'.tr.isEmpty
              ? 'Please enter a valid 8-character code'
              : 'code_too_short'.tr;
        });
        return;
      }
      
      await _identifyHospital(code);
      
      // If identification successful, proceed
      final updatedState = ref.read(searchFlowProvider);
      if (updatedState.identifiedHospital != null) {
        _proceedToNextStep();
      }
    } else if (_selectedMethod == IdentificationMethod.qrScan) {
      await _openQrScanner();
    } else {
      await _openGallery();
    }
  }

  void _proceedToNextStep() {
    // Check if user is authenticated
    final canAccess = ref.read(canAccessProtectedRoutesProvider);
    
    canAccess.when(
      data: (isAuthenticated) {
        if (isAuthenticated) {
          // User is fully authenticated, go to payment
          context.push('/blood-search/payment', extra: {'option': widget.option});
        } else {
          // User needs to register/verify
          context.push('/blood-search/visitor-phone');
        }
      },
      loading: () {},
      error: (_, __) {
        // Default to visitor registration
        context.push('/blood-search/visitor-phone');
      },
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ColorPages.COLOR_PRINCIPAL.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? ColorPages.COLOR_PRINCIPAL.withOpacity(0.1) 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ubuntu(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Iconsax.tick_circle5,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _HospitalPreviewCard extends StatelessWidget {
  final IdentifiedHospital hospital;

  const _HospitalPreviewCard({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.hospital,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hospital.address ?? 'Address not available',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.tick_circle5,
            color: Colors.green.shade600,
            size: 24,
          ),
        ],
      ),
    );
  }
}

/// Upper case text formatter for code input
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
