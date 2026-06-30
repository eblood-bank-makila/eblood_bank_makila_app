import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/rbac/services/rbac_guard.dart';
import '../../../core/rbac/providers/rbac_provider.dart';
import '../../../core/rbac/services/rbac_url_helper.dart';
import '../../../core/rbac/enums/collection_crud_info_flag.dart';
import '../../data/models/blood_request_model.dart';
import '../../providers/blood_request_provider.dart';


Color? _hexToColor(String? hex) {
  if (hex == null) return null;
  var v = hex.trim();
  if (v.isEmpty) return null;
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  if (v.length != 8) return null;
  final intVal = int.tryParse(v, radix: 16);
  return intVal == null ? null : Color(intVal);
}

/// Blood Request Detail Page - Shows full details of a blood request
class BloodRequestDetailPage extends ConsumerStatefulWidget {
  final String requestId;
  final BloodRequestModel? initialRequest;

  const BloodRequestDetailPage({
    Key? key,
    required this.requestId,
    this.initialRequest,
  }) : super(key: key);

  @override
  ConsumerState<BloodRequestDetailPage> createState() => _BloodRequestDetailPageState();
}

class _BloodRequestDetailPageState extends ConsumerState<BloodRequestDetailPage> {
  BloodRequestModel? _request;
  bool _isLoading = false;
  bool _isConfirmingPickup = false;
  String? _error;
  late final bool _canConfirmPickup;

  @override
  void initState() {
    super.initState();
    // RBAC entry guard.
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_bb_requests_detail',
    );
    final crudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
      'flutter_apps_eblood_bank_bb_requests_detail',
    );
    _canConfirmPickup = RbacUrlHelper().hasRbacUrl(
      CollectionCrudInfoFlag.updateProcessingUrl,
      'confirm_pickup_url',
      crudInfo,
    );
    _request = widget.initialRequest;
    if (_request == null) {
      _fetchRequestDetails();
    }
  }

  Future<void> _fetchRequestDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(bloodRequestServiceProvider);
      final request = await service.getBloodRequestById(widget.requestId);
      setState(() {
        _request = request;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _request != null
                  ? _buildDetailContent()
                  : _buildEmptyState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorPages.COLOR_PRINCIPAL),
          ),
          const SizedBox(height: 16),
          Text(
            'loading_request_details'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'error_loading_request'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'unknown_error'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchRequestDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'no_request_found'.tr,
        style: GoogleFonts.ubuntu(
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    final request = _request!;
    final statusInfo = _getStatusInfo(request.status);
    final createdDate = request.createdDateTime;
    final deliveryDate = request.deliveryDateTime;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'request_details'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorPages.COLOR_PRINCIPAL,
                    ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: _buildStatusBadge(request.status, statusInfo),
                ),
                const SizedBox(height: 16),

                // Request ID Card
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: _buildInfoCard(
                    icon: Icons.fingerprint_rounded,
                    title: 'request_id'.tr,
                    value: request.identifier,
                    copyable: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Patient Information
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildSectionCard(
                    title: 'patient_information'.tr,
                    icon: Icons.person_rounded,
                    children: [
                      _buildDetailRow('blood_type'.tr, request.patientBloodTypeDisplay),
                      _buildDetailRow('urgency_level'.tr, request.urgencyLevel.toUpperCase()),
                      _buildDetailRow('request_type'.tr, request.requestType),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Blood Components
                FadeInDown(
                  duration: const Duration(milliseconds: 700),
                  child: _buildSectionCard(
                    title: 'blood_components'.tr,
                    icon: Icons.water_drop_rounded,
                    children: request.requestedComponents.map((component) {
                      return _buildComponentRow(component);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Requested Blood Bags (ops_blood_bags_requested)
                if (request.opsBloodBagsRequested.isNotEmpty)
                  FadeInDown(
                    duration: const Duration(milliseconds: 750),
                    child: _buildSectionCard(
                      title: 'requested_blood_bags'.tr,
                      icon: Icons.inventory_2_rounded,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: request.opsBloodBagsRequested.map((bag) {
                            final bgColor = _hexToColor(bag.statusBgColorHex);
                            final textColor = _hexToColor(bag.statusTextColorHex);
                            final details = [
                              bag.identifier,
                              if (bag.rhesusFactor?.isNotEmpty == true) bag.rhesusFactor!,
                              if (bag.volume?.isNotEmpty == true) bag.volume!,
                              if (bag.statusLabel?.isNotEmpty == true) bag.statusLabel!,
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

                // Delivery Information
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: _buildSectionCard(
                    title: 'delivery_information'.tr,
                    icon: Icons.local_shipping_rounded,
                    children: [
                      _buildDetailRow('hospital_name'.tr, request.deliveryContact?.name ?? '—'),
                      _buildDetailRow('contact_phone'.tr, request.deliveryContact?.phone ?? '—'),
                      if (request.deliveryContact?.email != null)
                        _buildDetailRow('contact_email'.tr, request.deliveryContact?.email ?? ''),
                      if (request.deliveryContact?.address != null)
                        _buildDetailRow('address'.tr, request.deliveryContact?.address ?? ''),
                      if (deliveryDate != null)
                        _buildDetailRow(
                          'delivery_time'.tr,
                          DateFormat('dd MMM yyyy HH:mm', Localizations.localeOf(context).toLanguageTag()).format(deliveryDate),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Clinical Indication
                if ((request.clinicalIndication ?? '').isNotEmpty)
                  FadeInDown(
                    duration: const Duration(milliseconds: 900),
                    child: _buildSectionCard(
                      title: 'clinical_indication'.tr,
                      icon: Icons.medical_information_rounded,
                      children: [
                        Text(
                          request.clinicalIndication ?? '',
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Confirm Pickup Button
                if (_canConfirmPickup && _shouldShowConfirmPickupButton(request.status))
                  FadeInDown(
                    duration: const Duration(milliseconds: 1000),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: _buildConfirmPickupButton(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Check if confirm pickup button should be shown
  bool _shouldShowConfirmPickupButton(String status) {
    final normalizedStatus = status.toLowerCase().replaceAll('_', '').replaceAll('-', '');
    return normalizedStatus == 'pendingpickupfrombloodbank' ||
           normalizedStatus == 'paymentconfirmed' ||
           normalizedStatus == 'approved' ||
           normalizedStatus == 'fulfilled';
  }

  /// Build confirm pickup button
  Widget _buildConfirmPickupButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isConfirmingPickup ? null : _handleConfirmPickup,
        icon: _isConfirmingPickup
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_circle_rounded, size: 24),
        label: Text(
          _isConfirmingPickup ? 'confirming_pickup'.tr : 'confirm_pickup'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPages.COLOR_PRINCIPAL,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// Handle confirm pickup action
  Future<void> _handleConfirmPickup() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'confirm_pickup_title'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'confirm_pickup_message'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'cancel'.tr,
              style: GoogleFonts.ubuntu(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'confirm'.tr,
              style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isConfirmingPickup = true;
    });

    try {
      final controller = ref.read(bloodRequestProvider.notifier);
      final updatedRequest = await controller.confirmPickup(widget.requestId);

      setState(() {
        _request = updatedRequest;
        _isConfirmingPickup = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'pickup_confirmed_message'.tr,
                    style: GoogleFonts.ubuntu(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConfirmingPickup = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${'error_confirming_pickup'.tr}: ${e.toString()}',
                    style: GoogleFonts.ubuntu(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status, Map<String, dynamic> statusInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusInfo['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusInfo['icon'],
            color: statusInfo['color'],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'status'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusInfo['label'],
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusInfo['color'],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool copyable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 20,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('copied_to_clipboard'.tr),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                icon,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentRow(BloodRequestComponent component) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.water_drop_rounded,
            color: ColorPages.COLOR_PRINCIPAL,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.bloodProductType,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${component.quantity} ${component.volume ?? 'units'.tr}',
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
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'requested':
      case 'processing':
        return {
          'label': 'status_pending'.tr,
          'color': Colors.orange,
          'icon': Icons.pending_rounded,
        };
      case 'completed':
      case 'approved':
        return {
          'label': 'status_approved'.tr,
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
        };
      case 'failed':
      case 'cancelled':
      case 'declined':
      case 'rejected':
      case 'expired':
      case 'timeout':
        return {
          'label': 'status_failed'.tr,
          'color': Colors.red,
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'label': status,
          'color': Colors.grey,
          'icon': Icons.info_rounded,
        };
    }
  }
}
