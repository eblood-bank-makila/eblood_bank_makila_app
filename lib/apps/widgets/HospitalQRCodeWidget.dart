/// Hospital QR Code Widget
/// Displays QR code for hospital/health structure identifier

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme/ColorPages.dart';
import '../../services/HealthStructureService.dart';

class HospitalQRCodeWidget extends ConsumerStatefulWidget {
  final bool showInDialog;

  const HospitalQRCodeWidget({
    super.key,
    this.showInDialog = false,
  });

  @override
  ConsumerState<HospitalQRCodeWidget> createState() => _HospitalQRCodeWidgetState();
}

class _HospitalQRCodeWidgetState extends ConsumerState<HospitalQRCodeWidget> {
  bool _isLoading = true;
  bool _isSharing = false;
  String? _identifier;
  String? _healthStructureName;
  String? _errorMessage;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadHealthStructure();
  }

  Future<void> _loadHealthStructure() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final healthStructureService = ref.read(healthStructureServiceProvider);
      final result = await healthStructureService.getMyHealthStructure();

      if (result != null) {
        setState(() {
          _identifier = result['identifier'];
          _healthStructureName = result['name'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'health_structure_not_found'.tr.isEmpty 
              ? 'Health structure not found' 
              : 'health_structure_not_found'.tr;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'failed_load_qr'.tr.isEmpty 
            ? 'Failed to load QR code' 
            : 'failed_load_qr'.tr;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showInDialog) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: _buildContent(),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.scan_barcode,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hospital_qr_code'.tr.isEmpty ? 'Hospital QR Code' : 'hospital_qr_code'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (_healthStructureName != null)
                      Text(
                        _healthStructureName!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (widget.showInDialog)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // QR Code or Loading/Error
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.danger, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _loadHealthStructure,
                      icon: const Icon(Iconsax.refresh, size: 18),
                      label: Text('retry'.tr.isEmpty ? 'Retry' : 'retry'.tr),
                    ),
                  ],
                ),
              ),
            )
          else if (_identifier != null)
            Column(
              children: [
                // QR Code with RepaintBoundary for image capture
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // E-Blood Bank copyright/branding on top
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/icon.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Iconsax.drop,
                                color: ColorPages.COLOR_PRINCIPAL,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'E-Blood Bank Makila',
                              style: GoogleFonts.ubuntu(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ColorPages.COLOR_PRINCIPAL,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // QR Code
                        QrImageView(
                          data: _identifier!,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                        const SizedBox(height: 16),
                        // Hospital name at bottom
                        if (_healthStructureName != null)
                          Text(
                            _healthStructureName!,
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        // Identifier at bottom
                        Text(
                          _identifier!,
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ColorPages.COLOR_PRINCIPAL,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Identifier Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _identifier!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _copyIdentifier(_identifier!),
                        icon: const Icon(Iconsax.copy, size: 18),
                        tooltip: 'copy'.tr.isEmpty ? 'Copy' : 'copy'.tr,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Info Text
                Text(
                  'scan_qr_info'.tr.isEmpty 
                      ? 'Visitors can scan this QR code to identify your hospital' 
                      : 'scan_qr_info'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSharing ? null : () => _shareQRCode(_identifier!),
                        icon: _isSharing 
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Iconsax.share, size: 18),
                        label: Text('share'.tr.isEmpty ? 'Share' : 'share'.tr),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSharing ? null : () => _downloadQRCode(_identifier!),
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Iconsax.document_download, size: 18),
                        label: Text('download'.tr.isEmpty ? 'Download' : 'download'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPages.COLOR_PRINCIPAL,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _copyIdentifier(String identifier) {
    Clipboard.setData(ClipboardData(text: identifier));
    Get.snackbar(
      'copied'.tr.isEmpty ? 'Copied' : 'copied'.tr,
      'identifier_copied'.tr.isEmpty 
          ? 'Identifier copied to clipboard' 
          : 'identifier_copied'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Share QR code as an image with hospital name and identifier
  Future<void> _shareQRCode(String identifier) async {
    if (_isSharing) return;
    
    setState(() {
      _isSharing = true;
    });

    try {
      // Capture the QR code widget as an image
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        // Fallback to text share
        _shareAsText(identifier);
        return;
      }

      // Capture the image at 3x resolution for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        _shareAsText(identifier);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'hospital_qr_${identifier.replaceAll(RegExp(r'[^\w]'), '_')}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Share the image file with text
      final shareText = 'share_qr_text'.tr.isEmpty 
          ? '${_healthStructureName ?? 'Hospital'}\nIdentifier: $identifier\nScan this QR code to find us in E-Blood Bank app.' 
          : 'share_qr_text'.trParams({'identifier': identifier, 'name': _healthStructureName ?? ''});
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'hospital_qr_code'.tr.isEmpty ? 'Hospital QR Code' : 'hospital_qr_code'.tr,
      );

    } catch (e) {
      print('Error sharing QR code as image: $e');
      // Fallback to text share
      _shareAsText(identifier);
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  /// Fallback to share as text if image capture fails
  void _shareAsText(String identifier) {
    Share.share(
      'share_qr_text'.tr.isEmpty 
          ? '${_healthStructureName ?? 'Hospital'}\nIdentifier: $identifier\nEnter this code to find us in E-Blood Bank app.' 
          : 'share_qr_text'.trParams({'identifier': identifier}),
      subject: 'hospital_qr_code'.tr.isEmpty ? 'Hospital QR Code' : 'hospital_qr_code'.tr,
    );
  }

  /// Download QR code to gallery
  Future<void> _downloadQRCode(String identifier) async {
    if (_isSharing) return;
    
    setState(() {
      _isSharing = true;
    });

    try {
      // Capture the QR code widget as an image
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        Get.snackbar(
          'error'.tr.isEmpty ? 'Error' : 'error'.tr,
          'qr_capture_failed'.tr.isEmpty 
              ? 'Failed to capture QR code' 
              : 'qr_capture_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      // Capture the image at 3x resolution for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        Get.snackbar(
          'error'.tr.isEmpty ? 'Error' : 'error'.tr,
          'qr_capture_failed'.tr.isEmpty 
              ? 'Failed to capture QR code' 
              : 'qr_capture_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Save to downloads/pictures directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'hospital_qr_${identifier.replaceAll(RegExp(r'[^\w]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      Get.snackbar(
        'success'.tr.isEmpty ? 'Success' : 'success'.tr,
        'qr_saved'.tr.isEmpty 
            ? 'QR code saved to: ${file.path}' 
            : 'qr_saved'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

    } catch (e) {
      print('Error downloading QR code: $e');
      Get.snackbar(
        'error'.tr.isEmpty ? 'Error' : 'error'.tr,
        'qr_download_failed'.tr.isEmpty 
            ? 'Failed to download QR code' 
            : 'qr_download_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }
}
