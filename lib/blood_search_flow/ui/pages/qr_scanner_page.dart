/// QR Scanner Page
/// Camera-based QR code scanning for hospital identification

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../apps/config/theme/ColorPages.dart';

class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  late MobileScannerController _controller;
  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() => _hasScanned = true);
        
        // Return the scanned code
        context.pop(barcode.rawValue);
        break;
      }
    }
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  void _switchCamera() {
    _controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: Stack(
              children: [
                // Dark overlay with cutout
                CustomPaint(
                  size: Size.infinite,
                  painter: _ScannerOverlayPainter(),
                ),

                // Scan area frame
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ColorPages.COLOR_PRINCIPAL,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Corner decorations
                        ..._buildCornerDecorations(),
                      ],
                    ),
                  ),
                ),

                // Top bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        Material(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Iconsax.arrow_left_2,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        
                        // Title
                        Text(
                          'scan_qr'.tr.isEmpty ? 'Scan QR Code' : 'scan_qr'.tr,
                          style: GoogleFonts.ubuntu(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        // Placeholder for alignment
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),

                // Instructions
                Positioned(
                  bottom: 200,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'align_qr_in_frame'.tr.isEmpty
                            ? 'Align QR code within the frame'
                            : 'align_qr_in_frame'.tr,
                        style: GoogleFonts.ubuntu(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Torch button
                        _ControlButton(
                          icon: _isTorchOn ? Iconsax.flash_15 : Iconsax.flash_1,
                          label: _isTorchOn 
                              ? ('torch_on'.tr.isEmpty ? 'On' : 'torch_on'.tr)
                              : ('torch_off'.tr.isEmpty ? 'Off' : 'torch_off'.tr),
                          onTap: _toggleTorch,
                        ),
                        
                        const SizedBox(width: 40),
                        
                        // Switch camera button
                        _ControlButton(
                          icon: Iconsax.camera,
                          label: 'switch'.tr.isEmpty ? 'Switch' : 'switch'.tr,
                          onTap: _switchCamera,
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

  List<Widget> _buildCornerDecorations() {
    const cornerSize = 30.0;
    const cornerWidth = 4.0;
    
    return [
      // Top-left
      Positioned(
        top: -1,
        left: -1,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: cornerWidth),
              left: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: -1,
        right: -1,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: cornerWidth),
              right: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: -1,
        left: -1,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: cornerWidth),
              left: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: -1,
        right: -1,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: cornerWidth),
              right: BorderSide(color: ColorPages.COLOR_PRINCIPAL, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
    ];
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 280,
      height: 280,
    );

    final cutoutRRect = RRect.fromRectAndRadius(
      cutoutRect,
      const Radius.circular(20),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
