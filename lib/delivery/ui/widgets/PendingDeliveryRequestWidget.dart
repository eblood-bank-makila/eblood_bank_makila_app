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

/// Floating widget that shows pending delivery requests (Yango-style)
class PendingDeliveryRequestWidget extends ConsumerStatefulWidget {
  final VoidCallback? onAccepted;
  final VoidCallback? onRejected;

  const PendingDeliveryRequestWidget({
    super.key,
    this.onAccepted,
    this.onRejected,
  });

  @override
  ConsumerState<PendingDeliveryRequestWidget> createState() =>
      _PendingDeliveryRequestWidgetState();
}

class _PendingDeliveryRequestWidgetState
    extends ConsumerState<PendingDeliveryRequestWidget>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Trigger rebuild to update countdown
      if (mounted) setState(() {});
      // Remove expired requests
      ref.read(pendingDeliveryRequestProvider.notifier).removeExpiredRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendingDeliveryRequestProvider);
    final pendingRequest = state.firstPendingRequest;

    if (pendingRequest == null || pendingRequest.isExpired) {
      return const SizedBox.shrink();
    }

    return SlideInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with countdown
            _buildHeader(pendingRequest),
            // Request details
            _buildRequestDetails(pendingRequest),
            // Action buttons
            _buildActionButtons(pendingRequest, state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PendingDeliveryRequest request) {
    final isEmergency = request.isEmergency;
    final remainingTime = request.remainingTimeFormatted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEmergency ? Colors.red : ColorPages.COLOR_PRINCIPAL,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Icon(
                  isEmergency ? Iconsax.warning_2 : Iconsax.truck_fast,
                  color: Colors.white,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmergency ? 'emergency_delivery'.tr : 'new_delivery_request'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'accept_before_timeout'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Countdown timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              remainingTime,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails(PendingDeliveryRequest request) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Blood bank (pickup)
          _buildLocationRow(
            icon: Iconsax.hospital,
            iconColor: Colors.blue,
            title: request.bloodBankName,
            subtitle: request.bloodBankAddress,
            label: 'pickup'.tr,
          ),
          const SizedBox(height: 12),
          // Dotted line
          Row(
            children: [
              const SizedBox(width: 12),
              Column(
                children: List.generate(
                  3,
                  (index) => Container(
                    width: 2,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hospital (destination)
          _buildLocationRow(
            icon: Iconsax.building,
            iconColor: ColorPages.COLOR_PRINCIPAL,
            title: request.hospitalName,
            subtitle: request.hospitalAddress,
            label: 'destination'.tr,
          ),
          const SizedBox(height: 16),
          // Blood bags info
          if (request.bloodBags.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.drop, color: ColorPages.COLOR_PRINCIPAL, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.bloodBags.map((b) => '${b.fullBloodType} (${b.quantity})').join(', '),
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Distance and ETA
          Row(
            children: [
              if (request.distanceKm != null) ...[
                _buildInfoChip(
                  icon: Iconsax.location,
                  text: '${request.distanceKm!.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 12),
              ],
              if (request.estimatedMinutes != null)
                _buildInfoChip(
                  icon: Iconsax.timer_1,
                  text: '~${request.estimatedMinutes} min',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.ubuntu(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PendingDeliveryRequest request, PendingDeliveryRequestState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Reject button
          Expanded(
            child: OutlinedButton(
              onPressed: state.isRejecting || state.isAccepting
                  ? null
                  : () => _handleReject(request.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isRejecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'reject'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Accept button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: state.isAccepting || state.isRejecting
                  ? null
                  : () => _handleAccept(request.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: state.isAccepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.tick_circle, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'accept_delivery'.tr,
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(String deliveryId) async {
    final success = await ref
        .read(pendingDeliveryRequestProvider.notifier)
        .acceptDelivery(deliveryId);

    if (success && mounted) {
      widget.onAccepted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('delivery_accepted'.tr),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReject(String deliveryId) async {
    final success = await ref
        .read(pendingDeliveryRequestProvider.notifier)
        .rejectDelivery(deliveryId);

    if (success && mounted) {
      widget.onRejected?.call();
    }
  }
}
