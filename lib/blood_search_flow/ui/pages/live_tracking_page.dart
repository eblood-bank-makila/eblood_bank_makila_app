/// Live Tracking Page
/// Real-time delivery tracking

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/search_flow_provider.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../widgets/search_flow_app_bar.dart';

class LiveTrackingPage extends ConsumerStatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Start periodic refresh
    _startTracking();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    // Initial fetch
    ref.read(searchFlowProvider.notifier).startDeliveryTracking();
    
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(searchFlowProvider.notifier).refreshDeliveryTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchFlowProvider);
    final tracking = state.deliveryTracking;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: SearchFlowAppBar(
        title: 'live_tracking'.tr.isEmpty ? 'Live Tracking' : 'live_tracking'.tr,
        onBack: () => context.go('/blood-search'),
        showClose: true,
      ),
      body: tracking == null
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map placeholder
                  _MapPlaceholder(tracking: tracking),

                  const SizedBox(height: 24),

                  // Delivery status card
                  _DeliveryStatusCard(tracking: tracking),

                  const SizedBox(height: 24),

                  // Timeline
                  _DeliveryTimeline(tracking: tracking),

                  const SizedBox(height: 24),

                  // Driver info
                  if (tracking.driverName != null) ...[
                    _DriverInfoCard(tracking: tracking),
                    const SizedBox(height: 24),
                  ],

                  // Order details
                  _OrderDetailsCard(state: state),

                  const SizedBox(height: 32),

                  // Contact support button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _contactSupport,
                      icon: const Icon(Iconsax.message_question, size: 20),
                      label: Text(
                        'contact_support'.tr.isEmpty ? 'Contact Support' : 'contact_support'.tr,
                        style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'loading_tracking'.tr.isEmpty 
                ? 'Loading tracking information...' 
                : 'loading_tracking'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    // TODO: Implement support contact
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'support_coming_soon'.tr.isEmpty 
              ? 'Support feature coming soon' 
              : 'support_coming_soon'.tr,
          style: GoogleFonts.ubuntu(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final DeliveryTrackingInfo tracking;

  const _MapPlaceholder({required this.tracking});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Placeholder background
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.map,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'map_view'.tr.isEmpty ? 'Map View' : 'map_view'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // ETA badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.clock, size: 16, color: ColorPages.COLOR_PRINCIPAL),
                  const SizedBox(width: 6),
                  Text(
                    tracking.estimatedArrival ?? '--:--',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Refresh button
          Positioned(
            bottom: 12,
            right: 12,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Iconsax.refresh,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryStatusCard extends StatelessWidget {
  final DeliveryTrackingInfo tracking;

  const _DeliveryStatusCard({required this.tracking});

  @override
  Widget build(BuildContext context) {
    final status = tracking.status;
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusInfo.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusInfo.icon,
              color: statusInfo.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusInfo.title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusInfo.subtitle,
                  style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Animated status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusInfo.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusInfo(
          icon: Iconsax.clock,
          color: Colors.orange,
          title: 'order_pending'.tr.isEmpty ? 'Order Pending' : 'order_pending'.tr,
          subtitle: 'waiting_for_confirmation'.tr.isEmpty 
              ? 'Waiting for confirmation' 
              : 'waiting_for_confirmation'.tr,
        );
      case 'confirmed':
        return _StatusInfo(
          icon: Iconsax.tick_circle,
          color: Colors.blue,
          title: 'order_confirmed'.tr.isEmpty ? 'Order Confirmed' : 'order_confirmed'.tr,
          subtitle: 'preparing_for_dispatch'.tr.isEmpty 
              ? 'Preparing for dispatch' 
              : 'preparing_for_dispatch'.tr,
        );
      case 'in_transit':
        return _StatusInfo(
          icon: Iconsax.truck_fast,
          color: ColorPages.COLOR_PRINCIPAL,
          title: 'in_transit'.tr.isEmpty ? 'In Transit' : 'in_transit'.tr,
          subtitle: 'on_the_way'.tr.isEmpty 
              ? 'Your delivery is on the way' 
              : 'on_the_way'.tr,
        );
      case 'delivered':
        return _StatusInfo(
          icon: Iconsax.box_tick,
          color: Colors.green,
          title: 'delivered'.tr.isEmpty ? 'Delivered' : 'delivered'.tr,
          subtitle: 'successfully_delivered'.tr.isEmpty 
              ? 'Successfully delivered' 
              : 'successfully_delivered'.tr,
        );
      default:
        return _StatusInfo(
          icon: Iconsax.info_circle,
          color: Colors.grey,
          title: status,
          subtitle: '',
        );
    }
  }
}

class _StatusInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  _StatusInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _DeliveryTimeline extends StatelessWidget {
  final DeliveryTrackingInfo tracking;

  const _DeliveryTimeline({required this.tracking});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        title: 'order_placed'.tr.isEmpty ? 'Order Placed' : 'order_placed'.tr,
        time: tracking.orderTime,
        isCompleted: true,
      ),
      _TimelineStep(
        title: 'order_confirmed'.tr.isEmpty ? 'Confirmed' : 'order_confirmed'.tr,
        time: tracking.confirmedTime,
        isCompleted: tracking.status != 'pending',
      ),
      _TimelineStep(
        title: 'picked_up'.tr.isEmpty ? 'Picked Up' : 'picked_up'.tr,
        time: tracking.pickedUpTime,
        isCompleted: tracking.status == 'in_transit' || tracking.status == 'delivered',
      ),
      _TimelineStep(
        title: 'delivered'.tr.isEmpty ? 'Delivered' : 'delivered'.tr,
        time: tracking.deliveredTime,
        isCompleted: tracking.status == 'delivered',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'delivery_progress'.tr.isEmpty ? 'Delivery Progress' : 'delivery_progress'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: step.isCompleted 
                            ? ColorPages.COLOR_PRINCIPAL 
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: step.isCompleted
                          ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 16)
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: step.isCompleted 
                            ? ColorPages.COLOR_PRINCIPAL 
                            : Colors.grey.shade200,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            fontWeight: step.isCompleted ? FontWeight.w600 : FontWeight.normal,
                            color: step.isCompleted 
                                ? Colors.grey.shade800 
                                : Colors.grey.shade500,
                          ),
                        ),
                        if (step.time != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            step.formattedTime ?? '',
                            style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final DateTime? time;
  final bool isCompleted;

  _TimelineStep({
    required this.title,
    this.time,
    required this.isCompleted,
  });
  
  String? get formattedTime {
    if (time == null) return null;
    return '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
  }
}

class _DriverInfoCard extends StatelessWidget {
  final DeliveryTrackingInfo tracking;

  const _DriverInfoCard({required this.tracking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.user, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tracking.driverName!,
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'delivery_driver'.tr.isEmpty ? 'Delivery Driver' : 'delivery_driver'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (tracking.driverPhone != null) ...[
            Material(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  // Call driver
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Iconsax.call,
                    color: Colors.green.shade600,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderDetailsCard extends StatelessWidget {
  final SearchFlowState state;

  const _OrderDetailsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_details'.tr.isEmpty ? 'Order Details' : 'order_details'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'blood_type'.tr.isEmpty ? 'Blood Type' : 'blood_type'.tr,
            value: state.searchedBloodType ?? '--',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'from_hospital'.tr.isEmpty ? 'From Hospital' : 'from_hospital'.tr,
            value: state.identifiedHospital?.name ?? '--',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'order_id'.tr.isEmpty ? 'Order ID' : 'order_id'.tr,
            value: state.paymentResult?.transactionId ?? '--',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
