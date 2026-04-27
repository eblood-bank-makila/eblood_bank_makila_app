import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../qr_code/qrcode_page.dart';
import 'QrCodeActionCtrl.dart';

enum QrCodeActionType {
  deliveryValidation,
  passwordRequest,
  stockVerification,
  requestValidation,
}

class QrCodeActionPage extends ConsumerStatefulWidget {
  final QrCodeActionType actionType;

  const QrCodeActionPage({
    super.key,
    required this.actionType,
  });

  @override
  ConsumerState<QrCodeActionPage> createState() => _QrCodeActionPageState();
}

class _QrCodeActionPageState extends ConsumerState<QrCodeActionPage> {
  String? scannedQrCode;

  String get _title {
    switch (widget.actionType) {
      case QrCodeActionType.deliveryValidation:
        return 'confirm_delivery'.tr;
      case QrCodeActionType.passwordRequest:
        return 'request_password'.tr;
      case QrCodeActionType.stockVerification:
        return 'verify_blood_stock'.tr;
      case QrCodeActionType.requestValidation:
        return 'validate_request'.tr;
    }
  }

  String get _description {
    switch (widget.actionType) {
      case QrCodeActionType.deliveryValidation:
        return 'scan_qr_to_confirm'.tr;
      case QrCodeActionType.passwordRequest:
        return 'scan_qr_to_request_password'.tr;
      case QrCodeActionType.stockVerification:
        return 'scan_qr_to_verify_stock'.tr;
      case QrCodeActionType.requestValidation:
        return 'scan_qr_to_validate_request'.tr;
    }
  }

  String get _buttonText {
    switch (widget.actionType) {
      case QrCodeActionType.deliveryValidation:
        return 'confirm_delivery'.tr;
      case QrCodeActionType.passwordRequest:
        return 'request_password'.tr;
      case QrCodeActionType.stockVerification:
        return 'verify_blood_stock'.tr;
      case QrCodeActionType.requestValidation:
        return 'validate_request'.tr;
    }
  }

  Color get _actionColor {
    switch (widget.actionType) {
      case QrCodeActionType.deliveryValidation:
        return Colors.green;
      case QrCodeActionType.passwordRequest:
        return Colors.orange;
      case QrCodeActionType.stockVerification:
        return Colors.blue;
      case QrCodeActionType.requestValidation:
        return Colors.purple;
    }
  }

  IconData get _actionIcon {
    switch (widget.actionType) {
      case QrCodeActionType.deliveryValidation:
        return Icons.check_circle;
      case QrCodeActionType.passwordRequest:
        return Icons.lock;
      case QrCodeActionType.stockVerification:
        return Icons.inventory;
      case QrCodeActionType.requestValidation:
        return Icons.verified;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrCodeActionCtrlProvider);
    final controller = ref.read(qrCodeActionCtrlProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'scan_qr'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Scanned QR Code display
            if (scannedQrCode != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'qr_code_scanned'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scannedQrCode!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Scan button
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : _scanQrCode,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: Text(
                scannedQrCode == null ? 'scan_qr'.tr : 'scan_another_qr'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action button
            if (scannedQrCode != null)
              ElevatedButton.icon(
                onPressed: state.isLoading ? null : () => _executeAction(controller),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(_actionIcon, color: Colors.white),
                label: Text(
                  state.isLoading ? 'processing_in_progress'.tr : _buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _actionColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

            const Spacer(),

            // Error display
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanQrCode() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QrcodePage(),
        ),
      );
      if (result != null && result.isNotEmpty) {
        setState(() {
          scannedQrCode = result;
        });
        // Reset any previous error
        ref.read(qrCodeActionCtrlProvider.notifier).reset();
      }
    } catch (e) {
      _showErrorSnackBar('scan_error_details'.trParams({'error': e.toString()}));
    }
  }

  Future<void> _executeAction(QrCodeActionCtrl controller) async {
    if (scannedQrCode == null) return;

    final actionType = widget.actionType == QrCodeActionType.deliveryValidation 
        ? 'delivery_validation' 
        : 'password';

    final result = await controller.executeQrCodeAction(actionType, scannedQrCode!);
    
    if (result != null && result.success) {
      _showSuccessDialog(result.message);
    } else {
      // Error is already handled in the controller and displayed in UI
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_actionIcon, color: _actionColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'success'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'qr_code'.tr}: ${_maskQrCode(scannedQrCode ?? 'not_available_short'.tr)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog only
              // Reset the scanned QR code to allow scanning again
              setState(() {
                scannedQrCode = null;
              });
            },
            child: Text(
              'scan_another'.tr,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'finish'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _maskQrCode(String qrCode) {
    if (qrCode.isEmpty || qrCode == 'not_available_short'.tr) return qrCode;

    if (qrCode.length <= 8) {
      // For short codes, show first 2 and last 2 characters
      return '${qrCode.substring(0, 2)}****${qrCode.substring(qrCode.length - 2)}';
    } else {
      // For longer codes, show first 4 and last 4 characters
      return '${qrCode.substring(0, 4)}****${qrCode.substring(qrCode.length - 4)}';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
