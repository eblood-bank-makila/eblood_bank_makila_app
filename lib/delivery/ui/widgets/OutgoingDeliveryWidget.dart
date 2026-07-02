import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../business/interactors/DeliveryController.dart';
import '../../business/model/DeliveryModels.dart';

/// Floating card on the SELLER structure's home (blood bank selling to a
/// hospital, or CNTS selling to a blood bank): a courier accepted one of
/// their deliveries and the structure must confirm the physical handover of
/// the bags. The courier cannot report the pickup until this confirmation
/// lands backend-side.
class OutgoingDeliveryWidget extends ConsumerStatefulWidget {
  const OutgoingDeliveryWidget({super.key});

  @override
  ConsumerState<OutgoingDeliveryWidget> createState() =>
      _OutgoingDeliveryWidgetState();
}

class _OutgoingDeliveryWidgetState
    extends ConsumerState<OutgoingDeliveryWidget> {
  bool _confirming = false;

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

    // Only surface deliveries still needing the handover confirmation.
    final pending =
        outgoingDeliveries.where((d) => d.canConfirmPickup).toList();
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }

    final delivery = pending.first;

    return FadeInUp(
      child: Container(
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
            _buildConfirmButton(delivery),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(OutgoingDelivery delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.box_time,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remise au livreur',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Un livreur vient récupérer des poches de sang',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
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
          if (delivery.deliveryPersonName != null)
            _buildInfoRow(
              icon: Iconsax.user,
              label: 'Livreur',
              value: delivery.deliveryPersonName!,
            ),
          if (delivery.destinationName.isNotEmpty) ...[
            const SizedBox(height: 12),
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

  Widget _buildConfirmButton(OutgoingDelivery delivery) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _confirming ? null : () => _confirmPickup(delivery),
          icon: _confirming
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
    );
  }

  Future<void> _confirmPickup(OutgoingDelivery delivery) async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed != true) return;

    setState(() => _confirming = true);
    final error = await ref
        .read(outgoingDeliveriesProvider.notifier)
        .confirmPickup(delivery.id);
    if (!mounted) return;
    setState(() => _confirming = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Remise confirmée — le livreur peut repartir'),
        backgroundColor: error == null ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
