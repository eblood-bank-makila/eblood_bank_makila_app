import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../../../../apps/config/theme/ColorPages.dart';
import '../../../../apps/widgets/ModernSpinnerWidget.dart';
import '../../../../core/rbac/services/rbac_guard.dart';
import '../../../business/model/blood_request/BloodRequestModel.dart';
import '../../../business/interactor/usecase/blood_request/BloodRequestUseCase.dart';
import '../../../business/interactor/usecase/blood_request/BloodRequestTrackingUseCase.dart';

class BloodRequestTrackingPage extends ConsumerStatefulWidget {
  final BloodRequestModel request;

  const BloodRequestTrackingPage({
    super.key,
    required this.request,
  });

  @override
  ConsumerState<BloodRequestTrackingPage> createState() => _BloodRequestTrackingPageState();
}

class _BloodRequestTrackingPageState extends ConsumerState<BloodRequestTrackingPage> {
  DeliveryTrackingStatus? _trackingStatus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    guardPageEntry(
      ref,
      context,
      'flutter_apps_eblood_bank_hosp_home_blood_requests',
    );
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trackingStatus = await BloodRequestTrackingUseCase.getDeliveryTrackingStatus(widget.request);
      setState(() {
        _trackingStatus = trackingStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '${'something_went_wrong'.tr}: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ColorPages.COLOR_PRINCIPAL,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'delivery_tracking'.tr,
        style: GoogleFonts.ubuntu(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadTrackingData,
          icon: const Icon(Iconsax.refresh),
          tooltip: 'refresh'.tr,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadTrackingData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Info Card
            _buildRequestInfoCard(),
            
            const SizedBox(height: 16),
            
            // Tracking Status Card
            if (_isLoading)
              _buildLoadingCard()
            else if (_error != null)
              _buildErrorCard()
            else if (_trackingStatus != null)
              _buildTrackingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestInfoCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.box,
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
                        'request_number'.trParams({'id': widget.request.requestId.toString()}),
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                      Text(
                        widget.request.hospitalName,
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
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Iconsax.heart,
                    label: 'blood_type'.tr,
                    value: widget.request.bloodType,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Iconsax.box,
                    label: 'quantity'.tr,
                    value: '${widget.request.quantity} unité${widget.request.quantity > 1 ? 's' : ''}',
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(32),
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
            ModernSpinnerWidget(
              type: SpinnerType.heartbeat,
              size: 50,
              color: ColorPages.COLOR_PRINCIPAL,
              showMessage: true,
              message: 'loading'.tr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
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
            Icon(
              Iconsax.warning_2,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'error'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'something_went_wrong'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTrackingData,
              icon: const Icon(Iconsax.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard() {
    if (_trackingStatus == null) return const SizedBox.shrink();
    
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
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
                  Iconsax.location,
                  color: ColorPages.COLOR_PRINCIPAL,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'gps_tracking'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_trackingStatus!.canTrack && _trackingStatus!.gpsPosition != null)
              _buildGpsInfo(_trackingStatus!.gpsPosition!)
            else
              _buildNoGpsInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsInfo(DeliveryGpsPosition position) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.location_tick,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'current_position'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${'coordinates'.tr}: ${BloodRequestTrackingUseCase.formatGpsCoordinates(position.latitude, position.longitude)}',
                style: GoogleFonts.ubuntu(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${'last_update'.tr}: ${BloodRequestUseCase.formatDateTime(position.timestamp)}',
                style: GoogleFonts.ubuntu(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoGpsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.location_slash,
            color: Colors.orange.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _trackingStatus?.message ?? 'position_unavailable'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
