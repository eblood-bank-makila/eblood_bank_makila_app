import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../business/interactors/DeliveryController.dart';
import '../../business/model/DeliveryModels.dart';
import '../sheet/active_delivery_sheet_controller.dart';
import '../sheet/delivery_sheet.dart';

/// Floating cards on the SELLER structure's home (blood bank selling to a
/// hospital, or CNTS selling to a blood bank), one per outgoing delivery:
/// « Suivre » opens the delivery sheet, and once a courier accepted, the
/// structure confirms the physical handover of the bags. The courier cannot
/// report the pickup until this confirmation lands backend-side.
class OutgoingDeliveryWidget extends ConsumerStatefulWidget {
  const OutgoingDeliveryWidget({super.key});

  @override
  ConsumerState<OutgoingDeliveryWidget> createState() =>
      _OutgoingDeliveryWidgetState();
}

class _OutgoingDeliveryWidgetState
    extends ConsumerState<OutgoingDeliveryWidget> {
  String? _confirmingId; // delivery whose handover is being confirmed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(outgoingDeliveriesProvider.notifier).loadOutgoingDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final outgoingDeliveries = ref.watch(outgoingDeliveriesProvider);
    if (outgoingDeliveries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handovers waiting on this structure first.
    final deliveries = [
      ...outgoingDeliveries.where((d) => d.canConfirmPickup),
      ...outgoingDeliveries.where((d) => !d.canConfirmPickup),
    ];

    // Floating over the page: many deliveries scroll (and are clipped to this box)
    // instead of painting over it; the padding keeps the top card's shadow inside.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8),
        child: FadeInUp(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final delivery in deliveries) _buildCard(delivery)],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(OutgoingDelivery delivery) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(delivery),
          _buildInfo(delivery),
          _buildActions(delivery),
        ],
      ),
    );
  }

  Widget _buildHeader(OutgoingDelivery delivery) {
    final handover = delivery.canConfirmPickup;
    final color = handover ? Colors.orange : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              handover ? Iconsax.box_time : Iconsax.truck_fast,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  handover
                      ? 'Remise au livreur'
                      : pillKey(DeliverySheetRole.seller, delivery.deliveryPhase, noCourier: delivery.awaitingCourier).tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (handover) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Un livreur vient récupérer des poches de sang',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(OutgoingDelivery delivery) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!delivery.awaitingCourier)
            _buildInfoRow(
              icon: Iconsax.user,
              label: 'Livreur',
              value: delivery.deliveryPersonName!,
            ),
          if (delivery.destinationName.isNotEmpty) ...[
            if (!delivery.awaitingCourier) const SizedBox(height: 12),
            _buildInfoRow(
              icon: Iconsax.hospital,
              label: 'Destination',
              value: delivery.destinationName,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.ubuntu(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(OutgoingDelivery delivery) {
    final busy = _confirmingId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () => unawaited(ActiveDeliverySheetController.instance
                  .open(Navigator.of(context, rootNavigator: true), delivery.id, DeliverySheetRole.seller)),
              icon: const Icon(Iconsax.location, size: 18),
              label: Text('track'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorPages.COLOR_PRINCIPAL,
                side: const BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (delivery.canConfirmPickup) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: busy ? null : () => _confirmPickup(delivery),
                icon: _confirmingId == delivery.id
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.tick_circle, size: 18),
                label: const Text('Confirmer la remise des poches'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmPickup(OutgoingDelivery delivery) async {
    final confirmed = await askHandoverConfirmation(context, delivery);

    if (confirmed != true) return;

    setState(() => _confirmingId = delivery.id);
    final error = await ref
        .read(outgoingDeliveriesProvider.notifier)
        .confirmPickup(delivery.id);
    if (!mounted) return;
    setState(() => _confirmingId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Remise confirmée — le livreur peut repartir'),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// « Confirmez-vous avoir remis les poches au livreur … ? », shared by the home
/// card and the request detail page.
Future<bool?> askHandoverConfirmation(BuildContext context, OutgoingDelivery delivery) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmer la remise'),
      content: Text(
        'Confirmez-vous avoir remis les poches de sang au livreur'
        '${delivery.deliveryPersonName != null ? ' ${delivery.deliveryPersonName}' : ''} ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Confirmer'),
        ),
      ],
    ),
  );
}
