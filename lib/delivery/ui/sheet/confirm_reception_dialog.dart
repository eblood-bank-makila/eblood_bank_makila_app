import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../blood_bank/providers/ewallet_provider.dart';
import '../../business/interactors/DeliveryController.dart';

/// The hospital's reception confirm, shared by the incoming-delivery card and
/// the delivery sheet.
Future<void> confirmReception(
  BuildContext context,
  WidgetRef ref, {
  required String deliveryId,
  required String bloodRequestId,
}) async {
  // The reception confirm is code-gated: the courier presents the
  // verification code at the door, the receiving structure types it here.
  // Backend-side it triggers the seller wallet settlement.
  if (bloodRequestId.isEmpty) {
    // The code is checked against the blood request: without its id nothing could verify it.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('confirm_missing_request'.tr),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
    return;
  }
  final codeController = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('confirm_delivery'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('confirm_delivery_message'.tr),
          const SizedBox(height: 16),
          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '______',
              labelText: 'Code de confirmation du livreur',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, codeController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text('confirm'.tr),
        ),
      ],
    ),
  );

  if (code == null) return;
  if (code.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le code présenté par le livreur'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  final success = await ref
      .read(incomingDeliveriesProvider.notifier)
      .confirmDelivery(
        deliveryId,
        bloodRequestId: bloodRequestId,
        verificationCode: code,
      );

  if (success && context.mounted) {
    // Settlement just ran on the backend — refresh so a BB/CNTS user
    // opening the wallet next sees the release credit without a manual
    // refresh.
    ref.invalidate(ewalletProvider);
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'delivery_confirmed'.tr
            : 'Code invalide ou confirmation impossible'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
