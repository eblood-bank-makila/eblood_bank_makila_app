import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../core/rbac/providers/rbac_provider.dart';
import '../../business/interactors/DeliveryController.dart';
import '../../business/model/DeliveryModels.dart';

/// Page for hospital to track incoming delivery
class HospitalDeliveryTrackingPage extends ConsumerStatefulWidget {
  final String deliveryId;

  const HospitalDeliveryTrackingPage({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<HospitalDeliveryTrackingPage> createState() =>
      _HospitalDeliveryTrackingPageState();
}

class _HospitalDeliveryTrackingPageState
    extends ConsumerState<HospitalDeliveryTrackingPage> {
  Timer? _refreshTimer;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    // Dual-flag entry guard — this page is reachable from the hospital
    // inventory AND the hospital blood-requests flows (both show
    // incoming deliveries), so either flag grants access.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final hasAccess = ref.read(rbacProvider.notifier).hasAnyMenuFlag([
        'flutter_apps_eblood_bank_hosp_home_inventory',
        'flutter_apps_eblood_bank_hosp_home_blood_requests',
      ]);
      if (!hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('access_denied'.tr)),
        );
        Navigator.of(context).maybePop();
      }
    });
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(incomingDeliveriesProvider.notifier).loadIncomingDeliveries();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  IncomingDelivery? _findDelivery() {
    final deliveries = ref.watch(incomingDeliveriesProvider);
    try {
      return deliveries.firstWhere((d) => d.id == widget.deliveryId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _findDelivery();

    if (delivery == null) {
      return Scaffold(
        appBar: AppBar(title: Text('delivery_tracking'.tr)),
        body: Center(child: Text('delivery_not_found'.tr)),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(delivery),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatusCard(delivery),
                      const SizedBox(height: 20),
                      _buildDeliveryPersonCard(delivery),
                      const SizedBox(height: 20),
                      _buildBloodBagsCard(delivery),
                      const SizedBox(height: 20),
                      if (delivery.isAtHospital) _buildConfirmButton(delivery),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(IncomingDelivery delivery) {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: ColorPages.COLOR_PRINCIPAL),
                onPressed: () => Navigator.of(context).pop(),
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${'from'.tr}: ${delivery.bloodBankName}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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

  Widget _buildStatusCard(IncomingDelivery delivery) {
    final statusColor = _getStatusColor(delivery.status);
    final statusText = _getStatusText(delivery.status);
    final statusIcon = _getStatusIcon(delivery.status);

    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            if (delivery.estimatedArrival != null) ...[
              const SizedBox(height: 8),
              Text(
                '${'eta'.tr}: ${delivery.estimatedArrival}',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPersonCard(IncomingDelivery delivery) {
    if (delivery.deliveryPersonName == null) {
      return const SizedBox.shrink();
    }

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'delivery_person'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.user, color: ColorPages.COLOR_PRINCIPAL),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.deliveryPersonName!,
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (delivery.deliveryPersonPhone != null)
                        Text(
                          delivery.deliveryPersonPhone!,
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (delivery.deliveryPersonPhone != null)
                  IconButton(
                    icon: const Icon(Iconsax.call, color: ColorPages.COLOR_PRINCIPAL),
                    onPressed: () {
                      // TODO: Call delivery person
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodBagsCard(IncomingDelivery delivery) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.health, color: ColorPages.COLOR_PRINCIPAL),
                const SizedBox(width: 8),
                Text(
                  'blood_bags'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${delivery.bloodBags.length}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...delivery.bloodBags.map((bag) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bag.bloodType,
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bag.component ?? 'whole_blood'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${bag.volume ?? 450}ml',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(IncomingDelivery delivery) {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isConfirming ? null : () => _confirmDelivery(delivery),
          icon: _isConfirming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Iconsax.tick_circle, size: 20),
          label: Text(_isConfirming ? 'confirming'.tr : 'confirm_delivery_receipt'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isConfirming = true);

      final success = await ref
          .read(incomingDeliveriesProvider.notifier)
          .confirmDelivery(delivery.id);

      if (mounted) {
        setState(() => _isConfirming = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('delivery_confirmed'.tr),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_confirming_delivery'.tr),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
      case 'en_route_to_blood_bank':
      case 'at_blood_bank':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_route_to_hospital':
        return 'delivery_en_route'.tr;
      case 'at_hospital':
        return 'delivery_arrived'.tr;
      case 'picked_up_from_blood_bank':
        return 'blood_picked_up'.tr;
      case 'en_route_to_blood_bank':
        return 'going_to_blood_bank'.tr;
      case 'at_blood_bank':
        return 'at_blood_bank'.tr;
      default:
        return status.tr;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_route_to_hospital':
        return Iconsax.truck_fast;
      case 'at_hospital':
        return Iconsax.tick_circle;
      case 'picked_up_from_blood_bank':
        return Iconsax.box_tick;
      case 'en_route_to_blood_bank':
      case 'at_blood_bank':
        return Iconsax.hospital;
      default:
        return Iconsax.timer_1;
    }
  }
}

