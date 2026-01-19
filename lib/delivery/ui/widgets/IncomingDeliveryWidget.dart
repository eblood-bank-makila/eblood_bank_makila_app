import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../business/interactors/DeliveryController.dart';
import '../../business/model/DeliveryModels.dart';
import '../pages/HospitalDeliveryTrackingPage.dart';

/// Widget showing incoming delivery for hospital (floating card on home screen)
class IncomingDeliveryWidget extends ConsumerStatefulWidget {
  const IncomingDeliveryWidget({super.key});

  @override
  ConsumerState<IncomingDeliveryWidget> createState() =>
      _IncomingDeliveryWidgetState();
}

class _IncomingDeliveryWidgetState extends ConsumerState<IncomingDeliveryWidget> {
  @override
  void initState() {
    super.initState();
    // Load incoming deliveries
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(incomingDeliveriesProvider.notifier).loadIncomingDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomingDeliveries = ref.watch(incomingDeliveriesProvider);
    
    if (incomingDeliveries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show the first incoming delivery
    final delivery = incomingDeliveries.first;

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
            // Header with status
            _buildHeader(delivery),
            // Delivery info
            _buildDeliveryInfo(delivery),
            // Action button
            _buildActionButton(delivery),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(IncomingDelivery delivery) {
    final statusColor = _getStatusColor(delivery.status);
    final statusText = _getStatusText(delivery.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.truck_fast,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'incoming_delivery'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (delivery.estimatedArrival != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'eta'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  delivery.estimatedArrival!,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(IncomingDelivery delivery) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Blood bank info
          _buildInfoRow(
            icon: Iconsax.hospital,
            label: 'from'.tr,
            value: delivery.bloodBankName,
          ),
          const SizedBox(height: 12),
          // Delivery person info
          if (delivery.deliveryPersonName != null)
            _buildInfoRow(
              icon: Iconsax.user,
              label: 'delivery_person'.tr,
              value: delivery.deliveryPersonName!,
              trailing: delivery.deliveryPersonPhone != null
                  ? IconButton(
                      icon: const Icon(Iconsax.call, size: 20),
                      color: ColorPages.COLOR_PRINCIPAL,
                      onPressed: () {
                        // TODO: Call delivery person
                      },
                    )
                  : null,
            ),
          const SizedBox(height: 12),
          // Blood bags info
          _buildBloodBagsInfo(delivery.bloodBags),
        ],
      ),
    );
  }

  Widget _buildBloodBagsInfo(List<BloodBagInfo> bloodBags) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Iconsax.health, color: ColorPages.COLOR_PRINCIPAL, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${bloodBags.length} ${'blood_bags'.tr}',
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          // Show blood types
          Wrap(
            spacing: 4,
            children: bloodBags.map((bag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                bag.bloodType,
                style: GoogleFonts.ubuntu(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
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
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildActionButton(IncomingDelivery delivery) {
    final bool canConfirm = delivery.status == 'at_hospital';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          // Track button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HospitalDeliveryTrackingPage(
                      deliveryId: delivery.id,
                    ),
                  ),
                );
              },
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
          const SizedBox(width: 12),
          // Confirm button (only when delivery person is at hospital)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canConfirm ? () => _confirmDelivery(delivery) : null,
              icon: const Icon(Iconsax.tick_circle, size: 18),
              label: Text('confirm_receipt'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: canConfirm ? Colors.green : Colors.grey.shade300,
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
      ),
    );
  }

  Future<void> _confirmDelivery(IncomingDelivery delivery) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delivery'.tr),
        content: Text('confirm_delivery_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(incomingDeliveriesProvider.notifier)
          .confirmDelivery(delivery.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delivery_confirmed'.tr),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_route_to_hospital':
        return Colors.blue;
      case 'at_hospital':
        return Colors.green;
      case 'picked_up_from_blood_bank':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_route_to_hospital':
        return 'en_route'.tr;
      case 'at_hospital':
        return 'arrived'.tr;
      case 'picked_up_from_blood_bank':
        return 'picked_up'.tr;
      default:
        return status.tr;
    }
  }
}

