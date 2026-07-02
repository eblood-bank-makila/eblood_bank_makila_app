import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../core/rbac/services/rbac_guard.dart';
import '../../business/interactors/DeliveryController.dart';
import '../../business/model/DeliveryModels.dart';

/// Page for tracking and managing active delivery
class ActiveDeliveryTrackingPage extends ConsumerStatefulWidget {
  final String deliveryId;

  const ActiveDeliveryTrackingPage({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<ActiveDeliveryTrackingPage> createState() =>
      _ActiveDeliveryTrackingPageState();
}

class _ActiveDeliveryTrackingPageState
    extends ConsumerState<ActiveDeliveryTrackingPage> {
  Timer? _locationTimer;
  bool _isUpdatingPhase = false;

  @override
  void initState() {
    super.initState();
    // RBAC entry guard.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_delivery_active_tracking',
    );
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationTracking() {
    // Update location every 30 seconds. Also refresh the active delivery so
    // the seller's handover confirmation unblocks the pickup button without
    // the courier leaving the page.
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateLocation();
      ref.read(pendingDeliveryRequestProvider.notifier).loadActiveDelivery();
    });
    // Initial update
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await ref.read(pendingDeliveryRequestProvider.notifier).updateLocation(
            position.latitude,
            position.longitude,
            accuracy: position.accuracy,
          );
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDelivery = ref.watch(activeDeliveryProvider);

    if (activeDelivery == null) {
      return Scaffold(
        appBar: AppBar(title: Text('delivery_tracking'.tr)),
        body: Center(child: Text('no_active_delivery'.tr)),
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
              Colors.red.shade100,
              Colors.red.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(activeDelivery),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Progress timeline
                      _buildProgressTimeline(activeDelivery),
                      const SizedBox(height: 24),
                      // Current destination card
                      _buildCurrentDestinationCard(activeDelivery),
                      const SizedBox(height: 24),
                      // Delivery verification code (courier shows it to the
                      // hospital at handover — hospital types it to confirm)
                      if (activeDelivery.deliveryVerificationCode != null &&
                          !activeDelivery.isDelivered) ...[
                        _buildVerificationCodeCard(activeDelivery),
                        const SizedBox(height: 24),
                      ],
                      // Action button
                      _buildActionButton(activeDelivery),
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

  Widget _buildHeader(ActiveDelivery delivery) {
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
                    'delivery_tracking'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '#${delivery.id.substring(0, 8).toUpperCase()}',
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

  Widget _buildProgressTimeline(ActiveDelivery delivery) {
    final phases = [
      {'key': 'en_route_to_blood_bank', 'label': 'en_route_to_blood_bank'.tr, 'icon': Iconsax.truck_fast},
      {'key': 'at_blood_bank', 'label': 'at_blood_bank'.tr, 'icon': Iconsax.hospital},
      {'key': 'picked_up_from_blood_bank', 'label': 'picked_up'.tr, 'icon': Iconsax.box_tick},
      {'key': 'en_route_to_hospital', 'label': 'en_route_to_hospital'.tr, 'icon': Iconsax.truck_fast},
      {'key': 'at_hospital', 'label': 'at_hospital'.tr, 'icon': Iconsax.building},
    ];

    final currentIndex = phases.indexWhere((p) => p['key'] == delivery.deliveryPhase);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'delivery_progress'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ...phases.asMap().entries.map((entry) {
              final index = entry.key;
              final phase = entry.value;
              final isCompleted = index < currentIndex;
              final isCurrent = index == currentIndex;
              final isLast = index == phases.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? ColorPages.COLOR_PRINCIPAL
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          phase['icon'] as IconData,
                          color: isCompleted || isCurrent ? Colors.white : Colors.grey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          phase['label'] as String,
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCompleted || isCurrent ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Icon(Iconsax.tick_circle, color: Colors.green, size: 20),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'current'.tr,
                            style: GoogleFonts.ubuntu(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ColorPages.COLOR_PRINCIPAL,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 17),
                      width: 2,
                      height: 24,
                      color: isCompleted ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade200,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDestinationCard(ActiveDelivery delivery) {
    final isGoingToBloodBank = delivery.isEnRouteToBloodBank || delivery.deliveryPhase == 'awaiting_acceptance';
    final String destinationName;
    final String destinationAddress;
    final String? destinationPhone;

    if (isGoingToBloodBank) {
      destinationName = delivery.bloodBank.name;
      destinationAddress = delivery.bloodBank.address;
      destinationPhone = delivery.bloodBank.phoneNumber;
    } else {
      destinationName = delivery.hospital.name;
      destinationAddress = delivery.hospital.address;
      destinationPhone = delivery.hospital.phoneNumber;
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
            Row(
              children: [
                Icon(
                  isGoingToBloodBank ? Iconsax.hospital : Iconsax.building,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
                const SizedBox(width: 8),
                Text(
                  isGoingToBloodBank ? 'pickup_location'.tr : 'delivery_location'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              destinationName,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              destinationAddress,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (destinationPhone != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Iconsax.call, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    destinationPhone,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card showing the delivery verification code. The courier presents
  /// this code to the hospital staff at handover; the hospital enters it
  /// in its confirm-delivery dialog to close the delivery (and trigger
  /// seller wallet settlement backend-side).
  Widget _buildVerificationCodeCard(ActiveDelivery delivery) {
    final code = delivery.deliveryVerificationCode!;
    final highlight = delivery.isAtHospital;
    return FadeInUp(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: highlight ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? Colors.green.shade400 : Colors.grey.shade200,
            width: highlight ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.shield_tick,
                    color: highlight ? Colors.green.shade700 : ColorPages.COLOR_PRINCIPAL,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  'Code de confirmation de livraison',
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              code,
              style: GoogleFonts.ubuntu(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: highlight ? Colors.green.shade700 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'À communiquer au personnel de l\'hôpital à la remise des poches',
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ActiveDelivery delivery) {
    String buttonText;
    String nextPhase;
    IconData buttonIcon;

    switch (delivery.deliveryPhase) {
      case 'en_route_to_blood_bank':
        buttonText = 'arrived_at_blood_bank'.tr;
        nextPhase = 'at_blood_bank';
        buttonIcon = Iconsax.hospital;
        break;
      case 'at_blood_bank':
        // The pickup is gated backend-side on the SELLER's handover
        // confirmation — until it lands, the button shows a waiting state.
        if (delivery.isPickupConfirmedBySeller) {
          buttonText = 'confirm_pickup'.tr;
          nextPhase = 'picked_up_from_blood_bank';
          buttonIcon = Iconsax.box_tick;
        } else {
          buttonText = 'En attente de la remise par la structure...';
          nextPhase = '';
          buttonIcon = Iconsax.timer_1;
        }
        break;
      case 'picked_up_from_blood_bank':
        buttonText = 'start_delivery'.tr;
        nextPhase = 'en_route_to_hospital';
        buttonIcon = Iconsax.truck_fast;
        break;
      case 'en_route_to_hospital':
        buttonText = 'arrived_at_hospital'.tr;
        nextPhase = 'at_hospital';
        buttonIcon = Iconsax.building;
        break;
      case 'at_hospital':
        buttonText = 'waiting_for_confirmation'.tr;
        nextPhase = '';
        buttonIcon = Iconsax.timer_1;
        break;
      default:
        buttonText = 'update_status'.tr;
        nextPhase = '';
        buttonIcon = Iconsax.refresh;
    }

    final bool canUpdate = nextPhase.isNotEmpty && !_isUpdatingPhase;

    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canUpdate ? () => _updatePhase(nextPhase) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPages.COLOR_PRINCIPAL,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isUpdatingPhase
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(buttonIcon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _updatePhase(String phase) async {
    setState(() => _isUpdatingPhase = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = LocationInfo(
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
      );

      final success = await ref
          .read(pendingDeliveryRequestProvider.notifier)
          .updatePhase(phase, location: location);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('status_updated'.tr),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_updating_status'.tr),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPhase = false);
      }
    }
  }
}
