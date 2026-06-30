import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/orders/business/model/blood_request/BloodRequestModel.dart';
import 'package:eblood_bank_mak_app/orders/ui/framework/blood_request/BloodRequestNetworkServiceImpl.dart';

class BloodBagUsageDialog extends StatefulWidget {
  final BloodRequestModel request;
  final VoidCallback? onSuccess;

  const BloodBagUsageDialog({
    super.key,
    required this.request,
    this.onSuccess,
  });

  @override
  State<BloodBagUsageDialog> createState() => _BloodBagUsageDialogState();
}

class _BloodBagUsageDialogState extends State<BloodBagUsageDialog> {
  final _notesCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  bool _submitting = false;
  final _service = BloodRequestNetworkServiceImpl(ApiConfig.BASE_URL);

  Future<void> _markUsed(BloodBagRequestModel bag) async {
    setState(() => _submitting = true);
    try {
      final IApiResponse res = await _service.markBloodBagUsed(
        bag.bloodBagId,
        patientId: _patientCtrl.text.trim().isEmpty ? null : _patientCtrl.text.trim(),
        usageNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      if (res.success) {
        setState(() => bag.isUsed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Poche ${bag.bloodBagId} marquée comme utilisée')),
        );
        widget.onSuccess?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Impossible de marquer la poche comme utilisée')),
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
      title: Text('Utilisation des poches', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional patient id and notes
            TextField(
              controller: _patientCtrl,
              decoration: const InputDecoration(
                labelText: 'ID patient (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes d\'utilisation (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.request.bloodBags.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final bag = widget.request.bloodBags[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: bag.isUsed ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        bag.isUsed ? Iconsax.tick_circle : Icons.bloodtype,
                        color: bag.isUsed ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text('Type: ${bag.bloodType}', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600)),
                    subtitle: Text('Poche #${bag.bloodBagId}${bag.price != null ? '  •  ${bag.price!.toStringAsFixed(2)}' : ''}'),
                    trailing: bag.isUsed
                        ? const Chip(label: Text('Utilisée'))
                        : ElevatedButton(
                            onPressed: _submitting ? null : () => _markUsed(bag),
                            child: _submitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Marquer comme utilisée'),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

