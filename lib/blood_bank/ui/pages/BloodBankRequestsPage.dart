import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import '../../../apps/config/api/dio_client.dart' show getAuthToken;
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../../core/rbac/providers/rbac_provider.dart';
import '../../../core/rbac/services/rbac_guard.dart';
import '../../data/models/blood_request_model.dart';
import '../../providers/blood_request_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../services/websocket_service.dart';
import '../../services/blood_request_export_service.dart';
import 'BloodRequestDetailPage.dart';


Color? _hexToColor(String? hex) {
  if (hex == null) return null;
  var v = hex.trim();
  if (v.isEmpty) return null;
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  if (v.length != 8) return null;
  final intVal = int.tryParse(v, radix: 16);
  if (intVal == null) return null;
  return Color(intVal);
}

enum RequestFilter {
  all,
  pending,
  completed,
  failed,
  urgent,
}

class BloodBankRequestsPage extends ConsumerStatefulWidget {
  const BloodBankRequestsPage({super.key});

  @override
  ConsumerState<BloodBankRequestsPage> createState() => _BloodBankRequestsPageState();
}

class _BloodBankRequestsPageState extends ConsumerState<BloodBankRequestsPage> {
  RequestFilter _selectedFilter = RequestFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _hasFlag(String flag) =>
      ref.read(rbacProvider.notifier).hasMenuFlag(flag);

  @override
  void initState() {
    super.initState();
    // RBAC entry guard on the top-level application flag.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_blood_bank_requests_app',
    );

    // Fetch blood requests on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bloodRequestProvider.notifier).fetchBloodRequests(refresh: true);
      _initializeWebSocket();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(bloodRequestProvider.notifier).loadMore();
      }
    });
  }

  /// Initialize WebSocket connection for real-time updates
  Future<void> _initializeWebSocket() async {
    try {
      final storage = GetStorage();
      final socketHash = storage.read('socket_hash') as String?;

      if (socketHash == null || socketHash.isEmpty) {
        debugPrint('⚠️ No socket hash found, skipping WebSocket connection');
        return;
      }

      // Use the same token retrieval as the Dio interceptor (single source of truth)
      final authToken = await getAuthToken();

      if (authToken == null || authToken.isEmpty) {
        debugPrint('⚠️ No auth token found, WebSocket may fail to authenticate');
      }

      final webSocketService = ref.read(bloodRequestWebSocketServiceProvider);
      final connected = await webSocketService.connect(socketHash, authToken: authToken);

      if (connected) {
        debugPrint('✅ WebSocket connected successfully');

        // Listen for blood request updates
        ref.listen(bloodRequestUpdatesProvider, (previous, next) {
          next.when(
            data: (bloodRequest) {
              debugPrint('🩸 Received blood request update: ${bloodRequest.identifier}');
              // Update the blood request in the list
              ref.read(bloodRequestProvider.notifier).updateBloodRequest(bloodRequest);

              // Show snackbar notification
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Blood request ${bloodRequest.identifier} updated'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            loading: () {},
            error: (error, stack) {
              debugPrint('❌ Error receiving blood request update: $error');
            },
          );
        });
      } else {
        debugPrint('❌ Failed to connect to WebSocket');
      }
    } catch (e) {
      debugPrint('❌ Error initializing WebSocket: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bloodRequestProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(state),

            // Search and Filter
            _buildSearchAndFilter(),

            // Requests List
            Expanded(
              child: _buildRequestsList(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BloodRequestState state) {
    final connectionState = ref.watch(webSocketConnectionStateProvider);

    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'blood_requests'.tr,
                        style: GoogleFonts.ubuntu(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // WebSocket connection indicator
                      connectionState.when(
                        data: (state) {
                          if (state == WebSocketConnectionState.connected) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'live'.tr,
                                    style: GoogleFonts.ubuntu(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  /*
                  Text(
                    ' ${state.totalItems} ${'requests'.tr.toLowerCase()}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  */
                  Text(
                    '${state.totalItems} ${'requests'.tr.toLowerCase()}',
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Export button — only shown when the user has the export sub_menu.
            if (_hasFlag('flutter_apps_eblood_bank_bb_requests_export'))
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.document_download,
                    color: ColorPages.COLOR_PRINCIPAL,
                    size: 24,
                  ),
                ),
                tooltip: 'export'.tr,
                onSelected: (value) => _handleExport(value, state),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        const Icon(Iconsax.document, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          'export_pdf'.tr,
                          style: GoogleFonts.ubuntu(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        const Icon(Iconsax.document_text, size: 20, color: Colors.green),
                        const SizedBox(width: 12),
                        Text(
                          'export_csv'.tr,
                          style: GoogleFonts.ubuntu(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      ref.read(bloodRequestProvider.notifier).setSearchQuery(value.isEmpty ? null : value);
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'search_clinical_indication'.tr,
                  hintStyle: GoogleFonts.ubuntu(
                    color: Colors.grey.shade600,
                  ),
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
                children: RequestFilter.values.map((filter) {
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
                        _applyFilter(filter);
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      labelStyle: GoogleFonts.ubuntu(
                        color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.transparent,
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

  void _applyFilter(RequestFilter filter) {
    final controller = ref.read(bloodRequestProvider.notifier);

    switch (filter) {
      case RequestFilter.all:
        controller.setStatusFilter(null);
        controller.setUrgencyFilter(null);
        break;
      case RequestFilter.pending:
        controller.setStatusFilter('pending');
        controller.setUrgencyFilter(null);
        break;
      case RequestFilter.completed:
        controller.setStatusFilter('completed');
        controller.setUrgencyFilter(null);
        break;
      case RequestFilter.failed:
        controller.setStatusFilter('failed');
        controller.setUrgencyFilter(null);
        break;
      case RequestFilter.urgent:
        controller.setStatusFilter(null);
        controller.setUrgencyFilter('urgent');
        break;
    }
  }

  Widget _buildRequestsList(BloodRequestState state) {
    if (state.isLoading && state.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ColorPages.COLOR_PRINCIPAL,
            ),
            const SizedBox(height: 16),
            Text(
              'loading_blood_requests'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (state.error != null && state.requests.isEmpty) {
      return Center(
        child: FadeIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.danger,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(bloodRequestProvider.notifier).fetchBloodRequests(refresh: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.requests.isEmpty) {
      return Center(
        child: FadeIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.document_text,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune demande trouvée',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'blood_requests_appear_here'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(bloodRequestProvider.notifier).fetchBloodRequests(refresh: true);
      },
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: state.requests.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.requests.length) {
            // Loading more indicator
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
            );
          }

          return FadeInUp(
            delay: Duration(milliseconds: 50 * index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildRequestCard(state.requests[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BloodRequestModel request) {
    final statusInfo = _getStatusInfo(request.status);
    final isUrgent = request.isUrgent;
    final createdDate = request.createdDateTime;
    final formattedDate = createdDate != null
        ? DateFormat('dd MMM yyyy', Localizations.localeOf(context).toLanguageTag()).format(createdDate)
        : 'unknown_date'.tr;

    final canDetail = _hasFlag('flutter_apps_eblood_bank_bb_requests_detail');

    return InkWell(
      onTap: () {
        if (!canDetail) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('access_denied'.tr)),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BloodRequestDetailPage(
              requestId: request.id,
              initialRequest: request,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUrgent ? Border.all(color: Colors.red.shade300, width: 2) : null,
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
                        Expanded(
                          child: Text(
                            request.deliveryContact?.name ?? '—',
                            style: GoogleFonts.ubuntu(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'urgent'.tr.toUpperCase(),
                              style: GoogleFonts.ubuntu(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.identifier,
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusInfo['label'],
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
                    request.patientBloodTypeDisplay,
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
                      '${request.effectiveUnitsRequested} unités demandées',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demandé le $formattedDate',
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
          const SizedBox(height: 12),

          // Requested Blood Bags (ops_blood_bags_requested)
          if (request.opsBloodBagsRequested.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'requested_blood_bags'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: request.opsBloodBagsRequested.map((bag) {
                      final bgColor = _hexToColor(bag.statusBgColorHex);
                      final textColor = _hexToColor(bag.statusTextColorHex);
                      final details = [
                        bag.identifier,
                        if (bag.rhesusFactor != null && bag.rhesusFactor!.isNotEmpty) bag.rhesusFactor!,
                        if (bag.volume != null && bag.volume!.isNotEmpty) bag.volume!,
                        if (bag.statusLabel != null && bag.statusLabel!.isNotEmpty) bag.statusLabel!,
                        if (bag.amount != null) '${bag.currencySymbol ?? ''} ${bag.amount!.toStringAsFixed(2)}',
                      ].where((e) => e.toString().trim().isNotEmpty).join(' • ');
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgColor ?? Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: bgColor == null ? Border.all(color: Colors.grey.shade200) : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: Text(
                          details,
                          style: GoogleFonts.ubuntu(fontSize: 12, color: textColor ?? Colors.grey.shade800),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],


          // Clinical Indication
          if ((request.clinicalIndication ?? '').isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Indication clinique',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.clinicalIndication ?? '',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  /// Handle export action
  Future<void> _handleExport(String format, BloodRequestState state) async {
    if (state.isLoading || state.requests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.requests.isEmpty
              ? 'no_requests_to_export'.tr
              : 'loading'.tr,
            style: GoogleFonts.ubuntu(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'generating_file'.trParams({'type': format.toUpperCase()}),
                  style: GoogleFonts.ubuntu(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );

      File file;
      if (format == 'pdf') {
        file = await BloodRequestExportService.exportToPdf(
          requests: state.requests,
          title: '${'blood_requests'.tr} - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
        );
      } else {
        file = await BloodRequestExportService.exportToCsv(
          requests: state.requests,
        );
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success dialog with options
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Iconsax.tick_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'export_success'.tr,
                  style: GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'file_generated_success'.trParams({'type': format.toUpperCase()}),
                  style: GoogleFonts.ubuntu(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'requests_exported_count'.trParams({'count': state.requests.length.toString()}),
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'close'.tr,
                  style: GoogleFonts.ubuntu(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await OpenFilex.open(file.path);
                },
                icon: const Icon(Iconsax.eye, size: 18),
                label: Text('open'.tr, style: GoogleFonts.ubuntu()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPages.COLOR_PRINCIPAL,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: '${'blood_requests'.tr} - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    subject: 'export_subject'.tr,
                  );
                },
                icon: const Icon(Iconsax.share, size: 18),
                label: Text('share'.tr, style: GoogleFonts.ubuntu()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'export_error'.tr}: $e',
              style: GoogleFonts.ubuntu(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFilterLabel(RequestFilter filter) {
    switch (filter) {
      case RequestFilter.all:
        return 'filter_all'.tr;
      case RequestFilter.pending:
        return 'filter_pending'.tr;
      case RequestFilter.completed:
        return 'filter_completed'.tr;
      case RequestFilter.failed:
        return 'filter_failed'.tr;
      case RequestFilter.urgent:
        return 'filter_urgent'.tr;
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'requested':
      case 'processing':
        return {'label': 'status_pending'.tr, 'color': Colors.orange};
      case 'completed':
      case 'approved':
        return {'label': 'status_completed'.tr, 'color': Colors.green};
      case 'failed':
      case 'cancelled':
      case 'declined':
      case 'rejected':
      case 'expired':
      case 'timeout':
        return {'label': 'status_failed'.tr, 'color': Colors.red};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }
}
