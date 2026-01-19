import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/widgets/AppSpinner.dart';
import '../../../business/model/blood_request/BloodRequestModel.dart';
import '../../../business/interactor/usecase/blood_request/BloodRequestUseCase.dart';
import 'BloodRequestCtrl.dart';
import 'widgets/BloodRequestCard.dart';
import 'widgets/BloodRequestEmptyState.dart';
import 'widgets/BloodRequestErrorState.dart';
import '../../../../apps/services/BloodDeliveryService.dart';
import '../../../../qrcode/qrcode_page.dart';

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
  final ScrollController _completedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Setup scroll listeners for pagination
    _setupScrollListeners();

    // Add tab change listener to reload data when switching tabs
    _tabController.addListener(_onTabChanged);

    // Load initial data for the first tab only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForCurrentTab();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Tab animation completed, load data for the new tab
      _loadDataForCurrentTab();
    }
  }

  void _loadDataForCurrentTab() {
    final controller = ref.read(bloodRequestCtrlProvider.notifier);
    final state = ref.read(bloodRequestCtrlProvider);

    debugPrint('📑 Loading data for tab: ${_tabController.index}');

    switch (_tabController.index) {
      case 0: // Pending
        if (state.pendingRequests.isEmpty || state.error != null) {
          debugPrint('   → Fetching pending requests');
          controller.fetchPendingDeliveryRequests(refresh: true);
        }
        break;
      case 1: // In Progress
        if (state.inProgressRequests.isEmpty || state.error != null) {
          debugPrint('   → Fetching in-progress requests');
          controller.fetchInProgressDeliveryRequests(refresh: true);
        }
        break;
      case 2: // Delivered
        if (state.deliveredRequests.isEmpty || state.error != null) {
          debugPrint('   → Fetching delivered requests');
          controller.fetchDeliveredRequests(refresh: true);
        }
        break;
      case 3: // Completed
        if (state.completedRequests.isEmpty || state.error != null) {
          debugPrint('   → Fetching completed requests');
          controller.fetchCompletedRequests(refresh: true);
        }
        break;
    }
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

    _completedScrollController.addListener(() {
      if (_completedScrollController.position.pixels >=
          _completedScrollController.position.maxScrollExtent - 200) {
        _loadMoreCompletedRequests();
      }
    });
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

  void _loadMoreCompletedRequests() {
    final state = ref.read(bloodRequestCtrlProvider);
    if (!state.isLoadingMore &&
        state.completedCurrentPage < state.completedTotalPages - 1) {
      ref.read(bloodRequestCtrlProvider.notifier)
          .fetchCompletedRequests(page: state.completedCurrentPage + 1);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pendingScrollController.dispose();
    _inProgressScrollController.dispose();
    _deliveredScrollController.dispose();
    _completedScrollController.dispose();
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
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'blood_requests'.tr,
          style: const TextStyle(
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
              text: 'pending'.tr,
              icon: Badge(
                label: Text('${state.pendingTotalItems}'),
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                textColor: Colors.white,
                child: const Icon(Icons.schedule),
              ),
            ),
            Tab(
              text: 'in_progress'.tr,
              icon: Badge(
                label: Text('${state.inProgressTotalItems}'),
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                child: const Icon(Icons.local_shipping),
              ),
            ),
            Tab(
              text: 'delivered'.tr,
              icon: Badge(
                label: Text('${state.deliveredTotalItems}'),
                backgroundColor: Colors.green,
                textColor: Colors.white,
                child: const Icon(Icons.check_circle),
              ),
            ),
            Tab(
              text: 'used'.tr,
              icon: Badge(
                label: Text('${state.completedTotalItems}'),
                backgroundColor: const Color(0xFF9C27B0), // Purple
                textColor: Colors.white,
                child: const Icon(Icons.check_circle_outline),
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
          _buildCompletedTab(state),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateRequestDialog(context);
        },
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'blood_request'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showCreateRequestDialog(BuildContext context) {
    // TODO: Implement create request dialog/page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('feature_coming_soon'.tr),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        duration: const Duration(seconds: 2),
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
      emptyMessage: 'no_pending_requests'.tr,
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
      emptyMessage: 'no_in_progress_deliveries'.tr,
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
      emptyMessage: 'no_delivered_requests'.tr,
      emptyIcon: Icons.check_circle,
    );
  }

  Widget _buildCompletedTab(BloodRequestState state) {
    return _buildRequestList(
      requests: state.completedRequests,
      scrollController: _completedScrollController,
      isLoading: state.isLoading,
      isLoadingMore: state.isLoadingMore,
      error: state.error,
      emptyMessage: 'no_used_bags'.tr,
      emptyIcon: Icons.check_circle_outline,
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
          message: 'loading'.tr,
        ),
      );
    }

    if (error != null && requests.isEmpty) {
      return BloodRequestErrorState(
        message: error,
        onRetry: () => _loadDataForCurrentTab(),
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
        physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even with few items
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
                  message: 'loading'.tr,
                ),
              ),
            );
          }

          return BloodRequestCard(
            request: requests[index],
            onTap: () => _showRequestDetails(requests[index]),
            onActionCompleted: () => ref.read(bloodRequestCtrlProvider.notifier).refreshAll(),
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
                          color: BloodRequestUseCase.getStatusColor(request.status).withValues(alpha: 0.1),
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
                              'request_number'.trParams({'id': request.requestId.toString()}),
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
                  _buildDetailRow('hospital'.tr, request.hospitalName),
                  _buildDetailRow('blood_type'.tr, request.bloodType),
                  _buildDetailRow('quantity'.tr, '${request.quantity} unité${request.quantity > 1 ? 's' : ''}'),
                  _buildDetailRow('request_date'.tr, BloodRequestUseCase.formatDateTime(request.requestDate)),

                  if (request.deliveryDate != null)
                    _buildDetailRow('delivery_date'.tr, BloodRequestUseCase.formatDateTime(request.deliveryDate!)),

                  if (request.deliveryAddress != null)
                    _buildDetailRow('address'.tr, request.deliveryAddress!),

                  if (request.totalAmount != null)
                    _buildDetailRow('total_to_pay'.tr, '\$${request.totalAmount!.toStringAsFixed(2)}'),

                  if (request.paymentStatus != null)
                    _buildDetailRow('status'.tr, request.paymentStatus!),

                  if (request.notes != null && request.notes!.isNotEmpty)
                    _buildDetailRow('notes'.tr, request.notes!),

                  // Blood bags
                  if (request.bloodBags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'blood_bags'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorPages.COLOR_PRINCIPAL,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...request.bloodBags.map((bag) => _buildBloodBagCard(bag)),
                  ],

                  const SizedBox(height: 16),

                  if (request.status == BloodRequestStatus.delivered)
                    _buildConfirmDeliveryButton(request),
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
              'expires_on'.trParams({'date': BloodRequestUseCase.formatDate(bag.expiryDate!)}),
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

  Widget _buildConfirmDeliveryButton(BloodRequestModel request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showConfirmDeliveryDialog(request),
          icon: const Icon(Icons.verified, color: Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          label: Text(
            'confirm_delivery'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _showConfirmDeliveryDialog(BloodRequestModel request) async {
    final codeCtrl = TextEditingController();
    String? scannedJsonDeliveryId;
    String? scannedJsonCode;

    Future<void> confirmAction(String code, {String? deliveryId}) async {
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invalid_or_empty_code'.tr), backgroundColor: Colors.red),
        );
        return;
      }

      Navigator.of(context).pop(); // close dialog

      final service = BloodDeliveryService();
      String? targetDeliveryId = deliveryId;

      // If no deliveryId, try to resolve it by listing delivered deliveries for the hospital
      if (targetDeliveryId == null || targetDeliveryId.isEmpty) {
        final found = await service.findDeliveredByCode(code);
        targetDeliveryId = found != null ? (found['id']?.toString() ?? found['_id']?.toString()) : null;
      }

      if (targetDeliveryId == null || targetDeliveryId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('delivery_not_found'.tr), backgroundColor: Colors.red),
        );
        return;
      }

      final res = await service.receiveDelivery(deliveryId: targetDeliveryId, code: code);
      if (!mounted) return;

      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('delivery_confirmed'.tr), backgroundColor: Colors.green),
        );
        // Refresh lists
        await ref.read(bloodRequestCtrlProvider.notifier).refreshAll();
        // Close bottom sheet if open
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'operation_failed'.tr), backgroundColor: Colors.red),
        );
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('confirm_delivery'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(
                  labelText: 'delivery_code'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'scan_qr_to_confirm'.tr,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push<String>(
                            MaterialPageRoute(builder: (_) => const QrcodePage()),
                          );
                          if (result != null && result.isNotEmpty) {
                            try {
                              final decoded = jsonDecode(result);
                              if (decoded is Map) {
                                final m = Map<String, dynamic>.from(decoded);
                                final dId = (m['ops_delivery_id'] ?? m['id'] ?? m['_id'])?.toString();
                                final code = (m['delivery_code'] ?? m['code'])?.toString();
                                if (code != null && code.isNotEmpty) {
                                  codeCtrl.text = code;
                                  scannedJsonCode = code;
                                  scannedJsonDeliveryId = dId;
                                  return;
                                }
                              }
                            } catch (_) {
                              // Not a JSON payload; fall back to using raw text
                            }
                            codeCtrl.text = result;
                            scannedJsonDeliveryId = null;
                            scannedJsonCode = result;
                          }
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text('scan_qr'.tr),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                final code = (scannedJsonCode ?? codeCtrl.text).trim();
                confirmAction(code, deliveryId: scannedJsonDeliveryId);
              },
              child: Text('confirm'.tr),
            ),
          ],
        );
      },
    );
  }
}
