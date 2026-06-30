import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../apps/config/theme/ColorPages.dart';
import '../../../../../core/rbac/services/rbac_guard.dart';
import '../../../../../core/rbac/providers/rbac_provider.dart';
import '../../../../../core/rbac/services/rbac_url_helper.dart';
import '../../../../../core/rbac/enums/collection_crud_info_flag.dart';
import '../../../../../core/rbac/models/rbac_models.dart';
import '../../../../business/service/UserDevicesNetworkServiceImpl.dart';

class ProfileUserDevicesPage extends ConsumerStatefulWidget {
  const ProfileUserDevicesPage({super.key});

  @override
  ConsumerState<ProfileUserDevicesPage> createState() =>
      _ProfileUserDevicesPageState();
}

class _ProfileUserDevicesPageState
    extends ConsumerState<ProfileUserDevicesPage> {
  late final UserDevicesNetworkServiceImpl _service;
  late final List<RbacCollectionCrudItem> _crudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  bool get _canUpdate => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.updateProcessingUrl, 'main', _crudInfo);
  bool get _canDelete => _urlHelper.hasRbacUrl(CollectionCrudInfoFlag.deleteProcessingUrl, 'main', _crudInfo);

  @override
  void initState() {
    super.initState();
    guardPageEntry(
        ref, context, 'flutter_apps_eblood_bank_profile_user_devices');
    _crudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
      'flutter_apps_eblood_bank_profile_user_devices',
    );
    _service = UserDevicesNetworkServiceImpl(_crudInfo);
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final resp = await _service.listDevices(allData: true);
      if (!mounted) return;
      if (resp.success) {
        final data = resp.data;
        List<dynamic> items;
        if (data is Map && data['data'] is List) {
          items = data['data'] as List;
        } else if (data is List) {
          items = data;
        } else {
          items = const [];
        }
        setState(() {
          _devices = items.whereType<Map<String, dynamic>>().toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = resp.message ?? 'error_loading_data'.tr;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchDevices();
  }

  // --- Device data helpers ---

  Map<String, dynamic> _getDeviceInfo(Map<String, dynamic> device) {
    final deviceInfoOuter = device['deviceInfo'];
    if (deviceInfoOuter is Map<String, dynamic>) {
      final inner = deviceInfoOuter['device_info'];
      if (inner is Map<String, dynamic>) return inner;
      return deviceInfoOuter;
    }
    return const {};
  }

  String _getUserAgent(Map<String, dynamic> device) {
    final deviceInfoOuter = device['deviceInfo'];
    if (deviceInfoOuter is Map<String, dynamic>) {
      return deviceInfoOuter['user_agent']?.toString() ?? '';
    }
    return '';
  }

  String _getDeviceName(Map<String, dynamic> device) {
    final info = _getDeviceInfo(device);
    final deviceName = info['device_name']?.toString() ?? '';
    final model = info['model']?.toString() ?? '';
    final manufacturer = info['manufacturer']?.toString() ?? '';
    if (deviceName.isNotEmpty) return deviceName;
    if (manufacturer.isNotEmpty && model.isNotEmpty) {
      return '$manufacturer $model';
    }
    if (model.isNotEmpty) return model;
    return 'unknown_device'.tr;
  }

  String _getOsInfo(Map<String, dynamic> device) {
    final info = _getDeviceInfo(device);
    final osName = info['os_name']?.toString() ?? '';
    final osVersion = info['os_version']?.toString() ?? '';
    if (osName.isNotEmpty && osVersion.isNotEmpty) return '$osName $osVersion';
    if (osName.isNotEmpty) return osName;
    return '';
  }

  String _getPlatformType(Map<String, dynamic> device) {
    final info = _getDeviceInfo(device);
    return (info['platform_type']?.toString() ?? '').toLowerCase();
  }

  String _getIpAddress(Map<String, dynamic> device) {
    final info = _getDeviceInfo(device);
    return info['ip_address']?.toString() ?? '';
  }

  String _getStatus(Map<String, dynamic> device) {
    return (device['status']?.toString() ?? 'pending_validation').toLowerCase();
  }

  String _getDeviceId(Map<String, dynamic> device) {
    return device['_id']?.toString() ?? '';
  }

  String _getLastActive(Map<String, dynamic> device) {
    return device['updated_at']?.toString() ?? '';
  }

  IconData _deviceIcon(String platformType) {
    switch (platformType) {
      case 'mobile':
      case 'android':
      case 'ios':
        return Iconsax.mobile;
      case 'desktop':
      case 'windows':
      case 'macos':
      case 'linux':
        return Iconsax.monitor;
      case 'web':
        return Iconsax.global;
      default:
        return Iconsax.cpu;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'allowed':
        return Colors.green;
      case 'pending_validation':
        return Colors.amber.shade700;
      case 'locked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'allowed':
        return 'allowed'.tr;
      case 'pending_validation':
        return 'pending_validation'.tr;
      case 'locked':
        return 'locked'.tr;
      default:
        return status;
    }
  }

  // --- Actions ---

  Future<void> _onValidateDevice(Map<String, dynamic> device) async {
    final id = _getDeviceId(device);
    try {
      final resp = await _service.validateDevice(id);
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('device_validated_successfully'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _fetchDevices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.message ?? 'operation_failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onLockUnlock(Map<String, dynamic> device) async {
    final id = _getDeviceId(device);
    final currentStatus = _getStatus(device);
    final newStatus = currentStatus == 'locked' ? 'allowed' : 'locked';
    try {
      final resp = await _service.lockUnlockDevice(id, newStatus);
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('operation_success'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _fetchDevices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.message ?? 'operation_failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onDeleteDevice(Map<String, dynamic> device) async {
    final id = _getDeviceId(device);
    final name = _getDeviceName(device);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Iconsax.trash, color: Colors.red.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'delete_device'.tr,
                style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          '${'confirm_delete_device'.tr}\n\n$name',
          style: GoogleFonts.ubuntu(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr,
                style: GoogleFonts.ubuntu(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('delete'.tr, style: GoogleFonts.ubuntu()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final resp = await _service.deleteDevice(id);
      if (!mounted) return;
      if (resp.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('device_deleted_successfully'.tr),
            backgroundColor: Colors.green,
          ),
        );
        _fetchDevices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.message ?? 'operation_failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'user_devices'.tr,
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmerList();
    if (_hasError) return _buildErrorState();
    if (_devices.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24, left: 12, right: 12),
        itemCount: _devices.length,
        itemBuilder: (context, index) => _buildDeviceCard(_devices[index]),
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final status = _getStatus(device);
    final statusColor = _statusColor(status);
    final platformType = _getPlatformType(device);
    final deviceName = _getDeviceName(device);
    final osInfo = _getOsInfo(device);
    final ipAddress = _getIpAddress(device);
    final userAgent = _getUserAgent(device);
    final lastActive = _getLastActive(device);
    final deviceId = _getDeviceId(device);
    final sysUserId = device['sys_user_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _deviceIcon(platformType),
              color: statusColor,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  deviceName,
                  style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusLabel(status),
                  style: GoogleFonts.ubuntu(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (osInfo.isNotEmpty)
                  Text(
                    osInfo,
                    style: GoogleFonts.ubuntu(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 8),
                // Action buttons row
                Row(
                  children: [
                    if (status == 'pending_validation' && _canUpdate)
                      _buildActionButton(
                        icon: Iconsax.tick_circle,
                        color: Colors.green,
                        tooltip: 'validate'.tr,
                        onPressed: () => _onValidateDevice(device),
                      ),
                    if (_canUpdate)
                      _buildActionButton(
                        icon: status == 'locked'
                            ? Iconsax.unlock
                            : Iconsax.lock,
                        color: Colors.orange,
                        tooltip: status == 'locked'
                            ? 'unlock'.tr
                            : 'lock'.tr,
                        onPressed: () => _onLockUnlock(device),
                      ),
                    if (_canDelete)
                      _buildActionButton(
                        icon: Iconsax.trash,
                        color: Colors.red,
                        tooltip: 'delete'.tr,
                        onPressed: () => _onDeleteDevice(device),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Expanded details
          children: [
            const Divider(),
            const SizedBox(height: 4),
            _buildDetailRow(Iconsax.global, 'IP', ipAddress),
            _buildDetailRow(Iconsax.cpu, 'platform'.tr, platformType),
            _buildDetailRow(
                Iconsax.clock, 'last_active'.tr, _formatDate(lastActive)),
            _buildDetailRow(Iconsax.finger_scan, 'device_id'.tr, deviceId),
            if (sysUserId.isNotEmpty)
              _buildDetailRow(Iconsax.user, 'user_id'.tr, sysUserId),
            if (userAgent.isNotEmpty)
              _buildDetailRow(
                  Iconsax.document_text, 'user_agent'.tr, userAgent),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 18, color: color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 150, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 100, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 80, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.warning_2, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'error_occurred'.tr,
              style: GoogleFonts.ubuntu(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(
                  color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Iconsax.refresh),
              label: Text('retry'.tr, style: GoogleFonts.ubuntu()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: ColorPages.COLOR_PRINCIPAL,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.mobile, size: 56,
                      color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'no_devices_found'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'pull_to_refresh'.tr,
                    style: GoogleFonts.ubuntu(
                        fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
