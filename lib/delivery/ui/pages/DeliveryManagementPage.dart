import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../core/rbac/services/rbac_guard.dart';
import '../../business/interactors/DeliveryController.dart';
import '../../business/model/DeliveryModels.dart';

enum DeliveryFilter { all, inProgress, delivered, urgent }

class DeliveryManagementPage extends ConsumerStatefulWidget {
  const DeliveryManagementPage({super.key});

  @override
  ConsumerState<DeliveryManagementPage> createState() =>
      _DeliveryManagementPageState();
}

class _DeliveryManagementPageState
    extends ConsumerState<DeliveryManagementPage> {
  DeliveryFilter _selectedFilter =
      DeliveryFilter.inProgress; // Default to in-progress
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // RBAC entry guard.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_cust_delivery_management',
    );
    // Load deliveries on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryControllerProvider.notifier).loadDeliveries();
      ref.read(deliveryStatsControllerProvider.notifier).loadStats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade100, Colors.red.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: const EdgeInsets.all(20), child: _buildHeader()),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchAndFilter(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: _buildDeliveriesList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final inProgressCount = ref.watch(inProgressDeliveriesCountProvider);
    final deliveredCount = ref.watch(deliveredDeliveriesCountProvider);

    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
              icon: const Icon(
                Iconsax.arrow_left_2,
                color: ColorPages.COLOR_PRINCIPAL,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'delivery_title'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'delivery_header_counts'.trParams({
                    'inProgress': inProgressCount.toString(),
                    'delivered': deliveredCount.toString(),
                  }),
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.truck,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'delivery_search_hint'.tr,
                  hintStyle: GoogleFonts.ubuntu(color: Colors.grey.shade600),
                  prefixIcon: Icon(
                    Iconsax.search_normal,
                    color: Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: DeliveryFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getFilterLabel(filter)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: ColorPages.COLOR_PRINCIPAL.withValues(
                        alpha: 0.12,
                      ),
                      labelStyle: GoogleFonts.ubuntu(
                        color: isSelected
                            ? ColorPages.COLOR_PRINCIPAL
                            : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? ColorPages.COLOR_PRINCIPAL
                            : Colors.grey.shade200,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveriesList() {
    final deliveryState = ref.watch(deliveryControllerProvider);
    final filteredDeliveries = _getFilteredDeliveries();

    if (deliveryState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deliveryState.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'delivery_error_title'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                deliveryState.error!,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(deliveryControllerProvider.notifier)
                      .loadDeliveries();
                },
                child: Text('retry'.tr),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredDeliveries.isEmpty) {
      return FadeInUp(
        delay: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.truck, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'delivery_empty_title'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'delivery_empty_desc'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(deliveryControllerProvider.notifier).loadDeliveries();
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: filteredDeliveries.length,
          itemBuilder: (context, index) {
            final delivery = filteredDeliveries[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildDeliveryCard(delivery),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Delivery delivery) {
    final statusInfo = _getStatusInfo(delivery.status);
    final priorityInfo = _getPriorityInfo(delivery.priority);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: delivery.isUrgent || delivery.isEmergency
            ? Border.all(color: Colors.red.shade300, width: 2)
            : null,
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
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          delivery.hospitalName,
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (delivery.isUrgent || delivery.isEmergency) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityInfo['color'].withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              delivery.priorityLabel.toUpperCase(),
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityInfo['color'],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delivery.id,
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delivery.statusLabel,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusInfo['color'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Blood Type and Quantity
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    delivery.bloodType,
                    style: GoogleFonts.ubuntu(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'delivery_units'.trParams({
                        'count': delivery.quantity.toString(),
                      }),
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delivery.hospitalAddress,
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
              if (delivery.isInProgress) ...[
                Icon(Iconsax.clock, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  delivery.estimatedDeliveryTime,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(delivery),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Delivery delivery) {
    switch (delivery.status) {
      case DeliveryStatus.assigned:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startDelivery(delivery),
            icon: const Icon(Iconsax.play, size: 16),
            label: Text(
              'delivery_action_start'.tr,
              style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

      case DeliveryStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showLocationDialog(delivery),
                icon: const Icon(Iconsax.location, size: 16),
                label: Text(
                  'delivery_action_location'.tr,
                  style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _completeDelivery(delivery),
                icon: const Icon(Iconsax.tick_circle, size: 16),
                label: Text(
                  'delivery_action_complete'.tr,
                  style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case DeliveryStatus.delivered:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.tick_circle, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                'delivery_completed_label'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _getFilterLabel(DeliveryFilter filter) {
    switch (filter) {
      case DeliveryFilter.all:
        return 'delivery_filter_all'.tr;
      case DeliveryFilter.inProgress:
        return 'delivery_filter_in_progress'.tr;
      case DeliveryFilter.delivered:
        return 'delivery_filter_delivered'.tr;
      case DeliveryFilter.urgent:
        return 'delivery_filter_urgent'.tr;
    }
  }

  Map<String, dynamic> _getStatusInfo(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return {'label': 'delivery_status_pending'.tr, 'color': Colors.grey};
      case DeliveryStatus.assigned:
        return {'label': 'delivery_status_assigned'.tr, 'color': Colors.blue};
      case DeliveryStatus.inProgress:
        return {
          'label': 'delivery_status_in_progress'.tr,
          'color': Colors.orange,
        };
      case DeliveryStatus.delivered:
        return {'label': 'delivery_status_delivered'.tr, 'color': Colors.green};
      case DeliveryStatus.cancelled:
        return {'label': 'delivery_status_cancelled'.tr, 'color': Colors.red};
    }
  }

  Map<String, dynamic> _getPriorityInfo(DeliveryPriority priority) {
    switch (priority) {
      case DeliveryPriority.normal:
        return {'label': 'delivery_priority_normal'.tr, 'color': Colors.blue};
      case DeliveryPriority.urgent:
        return {'label': 'delivery_priority_urgent'.tr, 'color': Colors.orange};
      case DeliveryPriority.emergency:
        return {'label': 'delivery_priority_emergency'.tr, 'color': Colors.red};
    }
  }

  List<Delivery> _getFilteredDeliveries() {
    final deliveryState = ref.watch(deliveryControllerProvider);
    List<Delivery> deliveries = deliveryState.deliveries;

    // If no data from API, use mock data for testing
    if (deliveries.isEmpty) {
      deliveries = _getMockDeliveries();
    }

    // Apply filter - Focus on in-progress and delivered as requested
    switch (_selectedFilter) {
      case DeliveryFilter.inProgress:
        deliveries = deliveries
            .where((d) => d.status == DeliveryStatus.inProgress)
            .toList();
        break;
      case DeliveryFilter.delivered:
        deliveries = deliveries
            .where((d) => d.status == DeliveryStatus.delivered)
            .toList();
        break;
      case DeliveryFilter.urgent:
        deliveries = deliveries
            .where((d) => d.isUrgent || d.isEmergency)
            .toList();
        break;
      case DeliveryFilter.all:
        // Show only in-progress and delivered as requested
        deliveries = deliveries
            .where(
              (d) =>
                  d.status == DeliveryStatus.inProgress ||
                  d.status == DeliveryStatus.delivered ||
                  d.status == DeliveryStatus.assigned,
            )
            .toList();
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      deliveries = deliveries.where((d) {
        final hospitalName = d.hospitalName.toLowerCase();
        final bloodType = d.bloodType.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return hospitalName.contains(query) || bloodType.contains(query);
      }).toList();
    }

    // Sort by priority and date
    deliveries.sort((a, b) {
      // First by priority (emergency > urgent > normal)
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;

      // Then by date (newest first)
      return b.requestDate.compareTo(a.requestDate);
    });

    return deliveries;
  }

  List<Delivery> _getMockDeliveries() {
    return [
      Delivery(
        id: 'DEL-001',
        requestId: 'REQ-001',
        hospitalName: 'Hôpital Central',
        hospitalAddress: '123 Avenue de la Paix, Kinshasa',
        bloodType: 'O+',
        quantity: 3,
        status: DeliveryStatus.inProgress,
        priority: DeliveryPriority.urgent,
        deliveryPersonId: 'DP-001',
        deliveryPersonName: 'Jean Mukendi',
        requestDate: DateTime.now().subtract(const Duration(hours: 2)),
        assignedDate: DateTime.now().subtract(const Duration(hours: 1)),
        pickupDate: DateTime.now().subtract(const Duration(minutes: 30)),
        contactPhone: '+243 123 456 789',
        contactPerson: 'Dr. Marie Kabila',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Delivery(
        id: 'DEL-002',
        requestId: 'REQ-002',
        hospitalName: 'Clinique Saint-Joseph',
        hospitalAddress: '456 Boulevard du 30 Juin, Kinshasa',
        bloodType: 'A-',
        quantity: 2,
        status: DeliveryStatus.delivered,
        priority: DeliveryPriority.normal,
        deliveryPersonId: 'DP-001',
        deliveryPersonName: 'Jean Mukendi',
        requestDate: DateTime.now().subtract(const Duration(hours: 5)),
        assignedDate: DateTime.now().subtract(const Duration(hours: 4)),
        pickupDate: DateTime.now().subtract(const Duration(hours: 3)),
        deliveredDate: DateTime.now().subtract(const Duration(hours: 2)),
        contactPhone: '+243 987 654 321',
        contactPerson: 'Infirmière Claire',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Delivery(
        id: 'DEL-003',
        requestId: 'REQ-003',
        hospitalName: 'Hôpital Universitaire',
        hospitalAddress: '789 Avenue Kasavubu, Kinshasa',
        bloodType: 'B+',
        quantity: 1,
        status: DeliveryStatus.assigned,
        priority: DeliveryPriority.emergency,
        deliveryPersonId: 'DP-001',
        deliveryPersonName: 'Jean Mukendi',
        requestDate: DateTime.now().subtract(const Duration(minutes: 30)),
        assignedDate: DateTime.now().subtract(const Duration(minutes: 15)),
        contactPhone: '+243 555 123 456',
        contactPerson: 'Dr. Paul Tshisekedi',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Delivery(
        id: 'DEL-004',
        requestId: 'REQ-004',
        hospitalName: 'Centre Médical Moderne',
        hospitalAddress: '321 Avenue de l\'Université, Kinshasa',
        bloodType: 'AB-',
        quantity: 4,
        status: DeliveryStatus.inProgress,
        priority: DeliveryPriority.normal,
        deliveryPersonId: 'DP-001',
        deliveryPersonName: 'Jean Mukendi',
        requestDate: DateTime.now().subtract(const Duration(hours: 1)),
        assignedDate: DateTime.now().subtract(const Duration(minutes: 45)),
        pickupDate: DateTime.now().subtract(const Duration(minutes: 20)),
        contactPhone: '+243 777 888 999',
        contactPerson: 'Dr. Fatima Ngozi',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Delivery(
        id: 'DEL-005',
        requestId: 'REQ-005',
        hospitalName: 'Hôpital Pédiatrique',
        hospitalAddress: '654 Rue de la Santé, Kinshasa',
        bloodType: 'O-',
        quantity: 2,
        status: DeliveryStatus.delivered,
        priority: DeliveryPriority.urgent,
        deliveryPersonId: 'DP-001',
        deliveryPersonName: 'Jean Mukendi',
        requestDate: DateTime.now().subtract(const Duration(days: 1)),
        assignedDate: DateTime.now().subtract(const Duration(hours: 22)),
        pickupDate: DateTime.now().subtract(const Duration(hours: 21)),
        deliveredDate: DateTime.now().subtract(const Duration(hours: 20)),
        contactPhone: '+243 444 555 666',
        contactPerson: 'Dr. Emmanuel Kabongo',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 20)),
      ),
    ];
  }

  Future<void> _startDelivery(Delivery delivery) async {
    final success = await ref
        .read(deliveryControllerProvider.notifier)
        .startDelivery(delivery.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('delivery_start_success'.trParams({'id': delivery.id})),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('delivery_start_error'.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeDelivery(Delivery delivery) async {
    final success = await ref
        .read(deliveryControllerProvider.notifier)
        .completeDelivery(delivery.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'delivery_complete_success'.trParams({'id': delivery.id}),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('delivery_complete_error'.tr),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLocationDialog(Delivery delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delivery_location_title'.tr),
        content: Text('delivery_location_not_implemented'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }
}
