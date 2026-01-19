import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../business/interactors/DeliveryController.dart';
import '../pages/ActiveDeliveryTrackingPage.dart';

/// Widget showing active delivery status (minimized view on home screen)
class ActiveDeliveryWidget extends ConsumerWidget {
  const ActiveDeliveryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDelivery = ref.watch(activeDeliveryProvider);

    if (activeDelivery == null) {
      return const SizedBox.shrink();
    }

    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveDeliveryTrackingPage(
                deliveryId: activeDelivery.id,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getPhaseColor(activeDelivery.deliveryPhase).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPhaseIcon(activeDelivery.deliveryPhase),
                      color: _getPhaseColor(activeDelivery.deliveryPhase),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'active_delivery'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _getPhaseLabel(activeDelivery.deliveryPhase),
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Navigate arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.arrow_right_3,
                      color: ColorPages.COLOR_PRINCIPAL,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress indicator
              _buildProgressIndicator(activeDelivery.deliveryPhase),
              const SizedBox(height: 12),
              // Destination info
              Row(
                children: [
                  Icon(
                    activeDelivery.isEnRouteToBloodBank || activeDelivery.isAtBloodBank
                        ? Iconsax.hospital
                        : Iconsax.building,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeDelivery.isEnRouteToBloodBank || activeDelivery.isAtBloodBank
                          ? activeDelivery.bloodBank.name
                          : activeDelivery.hospital.name,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activeDelivery.estimatedArrivalMinutes != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '~${activeDelivery.estimatedArrivalMinutes!.toInt()} min',
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String phase) {
    final phases = [
      'en_route_to_blood_bank',
      'at_blood_bank',
      'picked_up_from_blood_bank',
      'en_route_to_hospital',
      'at_hospital',
    ];

    final currentIndex = phases.indexOf(phase);

    return Row(
      children: List.generate(phases.length, (index) {
        final isCompleted = index <= currentIndex;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? ColorPages.COLOR_PRINCIPAL
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < phases.length - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'en_route_to_blood_bank':
        return Colors.blue;
      case 'at_blood_bank':
        return Colors.orange;
      case 'picked_up_from_blood_bank':
        return Colors.purple;
      case 'en_route_to_hospital':
        return Colors.teal;
      case 'at_hospital':
        return Colors.green;
      case 'delivered_and_confirmed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPhaseIcon(String phase) {
    switch (phase) {
      case 'en_route_to_blood_bank':
        return Iconsax.truck_fast;
      case 'at_blood_bank':
        return Iconsax.hospital;
      case 'picked_up_from_blood_bank':
        return Iconsax.box_tick;
      case 'en_route_to_hospital':
        return Iconsax.truck_fast;
      case 'at_hospital':
        return Iconsax.building;
      case 'delivered_and_confirmed':
        return Iconsax.tick_circle;
      default:
        return Iconsax.truck;
    }
  }

  String _getPhaseLabel(String phase) {
    switch (phase) {
      case 'en_route_to_blood_bank':
        return 'en_route_to_blood_bank'.tr;
      case 'at_blood_bank':
        return 'at_blood_bank'.tr;
      case 'picked_up_from_blood_bank':
        return 'picked_up'.tr;
      case 'en_route_to_hospital':
        return 'en_route_to_hospital'.tr;
      case 'at_hospital':
        return 'at_hospital'.tr;
      case 'delivered_and_confirmed':
        return 'delivered'.tr;
      default:
        return 'in_progress'.tr;
    }
  }
}

