import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/widgets/AppSpinner.dart';
import '../../../business/model/blood_request/BloodRequestModel.dart';
import '../../../business/interactor/usecase/blood_request/BloodRequestUseCase.dart';
import 'BloodRequestCtrl.dart';
import 'widgets/BloodRequestCard.dart';
import 'widgets/BloodRequestEmptyState.dart';
import 'widgets/BloodRequestErrorState.dart';

class BloodRequestPage extends ConsumerStatefulWidget {
  const BloodRequestPage({super.key});

  @override
  ConsumerState<BloodRequestPage> createState() => _BloodRequestPageState();
}

class _BloodRequestPageState extends ConsumerState<BloodRequestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _pendingScrollController = ScrollController();
  final ScrollController _inProgressScrollController = ScrollController();
  final ScrollController _deliveredScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Setup scroll listeners for pagination
    _setupScrollListeners();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _setupScrollListeners() {
    _pendingScrollController.addListener(() {
      if (_pendingScrollController.position.pixels >=
          _pendingScrollController.position.maxScrollExtent - 200) {
        _loadMorePendingRequests();
      }
    });

    _inProgressScrollController.addListener(() {
      if (_inProgressScrollController.position.pixels >=
          _inProgressScrollController.position.maxScrollExtent - 200) {
        _loadMoreInProgressRequests();
      }
    });

    _deliveredScrollController.addListener(() {
      if (_deliveredScrollController.position.pixels >=
          _deliveredScrollController.position.maxScrollExtent - 200) {
        _loadMoreDeliveredRequests();
      }
    });
  }

  void _loadInitialData() {
    final controller = ref.read(bloodRequestCtrlProvider.notifier);
    controller.fetchPendingDeliveryRequests(refresh: true);
    controller.fetchInProgressDeliveryRequests(refresh: true);
    controller.fetchDeliveredRequests(refresh: true);
  }

  void _loadMorePendingRequests() {
    final state = ref.read(bloodRequestCtrlProvider);
    if (!state.isLoadingMore && 
        state.pendingCurrentPage < state.pendingTotalPages - 1) {
      ref.read(bloodRequestCtrlProvider.notifier)
          .fetchPendingDeliveryRequests(page: state.pendingCurrentPage + 1);
    }
  }

  void _loadMoreInProgressRequests() {
    final state = ref.read(bloodRequestCtrlProvider);
    if (!state.isLoadingMore && 
        state.inProgressCurrentPage < state.inProgressTotalPages - 1) {
      ref.read(bloodRequestCtrlProvider.notifier)
          .fetchInProgressDeliveryRequests(page: state.inProgressCurrentPage + 1);
    }
  }

  void _loadMoreDeliveredRequests() {
    final state = ref.read(bloodRequestCtrlProvider);
    if (!state.isLoadingMore && 
        state.deliveredCurrentPage < state.deliveredTotalPages - 1) {
      ref.read(bloodRequestCtrlProvider.notifier)
          .fetchDeliveredRequests(page: state.deliveredCurrentPage + 1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingScrollController.dispose();
    _inProgressScrollController.dispose();
    _deliveredScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bloodRequestCtrlProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Mes Demandes de Sang',
          style: TextStyle(
            color: ColorPages.COLOR_PRINCIPAL,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(bloodRequestCtrlProvider.notifier).refreshAll();
            },
            icon: const Icon(
              Icons.refresh,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorPages.COLOR_PRINCIPAL,
          unselectedLabelColor: Colors.grey,
          indicatorColor: ColorPages.COLOR_PRINCIPAL,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              text: 'En attente',
              icon: Badge(
                label: Text('${state.pendingTotalItems}'),
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                textColor: Colors.white,
                child: const Icon(Icons.schedule),
              ),
            ),
            Tab(
              text: 'En cours',
              icon: Badge(
                label: Text('${state.inProgressTotalItems}'),
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                child: const Icon(Icons.local_shipping),
              ),
            ),
            Tab(
              text: 'Livrées',
              icon: Badge(
                label: Text('${state.deliveredTotalItems}'),
                backgroundColor: Colors.green,
                textColor: Colors.white,
                child: const Icon(Icons.check_circle),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(state),
          _buildInProgressTab(state),
          _buildDeliveredTab(state),
        ],
      ),
    );
  }

  Widget _buildPendingTab(BloodRequestState state) {
    return _buildRequestList(
      requests: state.pendingRequests,
      scrollController: _pendingScrollController,
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      error: state.error,
      emptyMessage: 'Aucune demande en attente',
      emptyIcon: Icons.schedule,
    );
  }

  Widget _buildInProgressTab(BloodRequestState state) {
    return _buildRequestList(
      requests: state.inProgressRequests,
      scrollController: _inProgressScrollController,
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      error: state.error,
      emptyMessage: 'Aucune livraison en cours',
      emptyIcon: Icons.local_shipping,
    );
  }

  Widget _buildDeliveredTab(BloodRequestState state) {
    return _buildRequestList(
      requests: state.deliveredRequests,
      scrollController: _deliveredScrollController,
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      error: state.error,
      emptyMessage: 'Aucune demande livrée',
      emptyIcon: Icons.check_circle,
    );
  }

  Widget _buildRequestList({
    required List<BloodRequestModel> requests,
    required ScrollController scrollController,
    required bool isLoading,
    required bool isLoadingMore,
    required String? error,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (isLoading && requests.isEmpty) {
      return Center(
        child: AppSpinner.heartbeat(
          size: 60,
          showMessage: true,
          message: 'Chargement des demandes...',
        ),
      );
    }

    if (error != null && requests.isEmpty) {
      return BloodRequestErrorState(
        message: error,
        onRetry: () => _loadInitialData(),
      );
    }

    if (requests.isEmpty) {
      return BloodRequestEmptyState(
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(bloodRequestCtrlProvider.notifier).refreshAll();
      },
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: requests.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == requests.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppSpinner.dots(
                  size: 40,
                  showMessage: true,
                  message: 'Chargement...',
                ),
              ),
            );
          }

          return BloodRequestCard(
            request: requests[index],
            onTap: () => _showRequestDetails(requests[index]),
          );
        },
      ),
    );
  }

  void _showRequestDetails(BloodRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRequestDetailsSheet(request),
    );
  }

  Widget _buildRequestDetailsSheet(BloodRequestModel request) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BloodRequestUseCase.getStatusColor(request.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          BloodRequestUseCase.getStatusIcon(request.status),
                          color: BloodRequestUseCase.getStatusColor(request.status),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demande #${request.requestId}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ColorPages.COLOR_PRINCIPAL,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: BloodRequestUseCase.getStatusColor(request.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request.status.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Details
                  _buildDetailRow('Hôpital', request.hospitalName),
                  _buildDetailRow('Type de sang', request.bloodType),
                  _buildDetailRow('Quantité', '${request.quantity} unité${request.quantity > 1 ? 's' : ''}'),
                  _buildDetailRow('Date de demande', BloodRequestUseCase.formatDateTime(request.requestDate)),
                  
                  if (request.deliveryDate != null)
                    _buildDetailRow('Date de livraison', BloodRequestUseCase.formatDateTime(request.deliveryDate!)),
                  
                  if (request.deliveryAddress != null)
                    _buildDetailRow('Adresse de livraison', request.deliveryAddress!),
                  
                  if (request.totalAmount != null)
                    _buildDetailRow('Montant total', '\$${request.totalAmount!.toStringAsFixed(2)}'),
                  
                  if (request.paymentStatus != null)
                    _buildDetailRow('Statut de paiement', request.paymentStatus!),
                  
                  if (request.notes != null && request.notes!.isNotEmpty)
                    _buildDetailRow('Notes', request.notes!),
                  
                  // Blood bags
                  if (request.bloodBags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Poches de sang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...request.bloodBags.map((bag) => _buildBloodBagCard(bag)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodBagCard(BloodBagRequestModel bag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bloodtype,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                bag.bloodType,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const Spacer(),
              if (bag.price != null)
                Text(
                  '\$${bag.price!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bag.bankName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (bag.expiryDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Expire le ${BloodRequestUseCase.formatDate(bag.expiryDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
