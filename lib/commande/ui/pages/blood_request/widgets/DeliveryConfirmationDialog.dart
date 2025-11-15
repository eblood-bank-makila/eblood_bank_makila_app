import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/commande/business/model/blood_request/BloodRequestModel.dart';
import 'package:eblood_bank_mak_app/commande/ui/framework/blood_request/BloodRequestNetworkServiceImpl.dart';
import 'package:eblood_bank_mak_app/qrcode/qrcode_page.dart';

class DeliveryConfirmationDialog extends StatefulWidget {
  final BloodRequestModel request;
  final VoidCallback? onSuccess;

  const DeliveryConfirmationDialog({
    super.key,
    required this.request,
    this.onSuccess,
  });

  @override
  State<DeliveryConfirmationDialog> createState() => _DeliveryConfirmationDialogState();
}

class _DeliveryConfirmationDialogState extends State<DeliveryConfirmationDialog> {
  final _codeCtrl = TextEditingController();
  String _method = 'manual'; // 'manual' | 'qr_scan'
  bool _submitting = false;

  final _service = BloodRequestNetworkServiceImpl(ApiConfig.BASE_URL);

  Future<void> _scanQr() async {
    final scanned = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrcodePage()),
    );
    if (!mounted) return;
    if (scanned is String && scanned.isNotEmpty) {
      setState(() {
        _codeCtrl.text = scanned;
        _method = 'qr_scan';
      });
    }
  }

  Future<void> _confirm() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer ou scanner le code de vérification')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final IApiResponse res = await _service.confirmDelivery(
        widget.request.id,
        code,
        _method,
      );
      if (!mounted) return;
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livraison confirmée')),
        );
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Echec de confirmation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Confirmer la livraison', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Method toggle
          Row(
            children: [
              ChoiceChip(
                label: const Text('Saisie manuelle'),
                selected: _method == 'manual',
                onSelected: (v) => setState(() => _method = 'manual'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Scan QR'),
                selected: _method == 'qr_scan',
                onSelected: (v) => setState(() => _method = 'qr_scan'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(
              labelText: 'Code de vérification',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _scanQr,
              icon: const Icon(Iconsax.scan_barcode, size: 18),
              label: const Text('Scanner un QR code'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _confirm,
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}

