import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/theme/ColorPages.dart';
import '../../core/services/location_tracking_service.dart';

class LocationPermissionWarningScreen extends StatefulWidget {
  const LocationPermissionWarningScreen({super.key});

  @override
  State<LocationPermissionWarningScreen> createState() => _LocationPermissionWarningScreenState();
}

class _LocationPermissionWarningScreenState extends State<LocationPermissionWarningScreen> {
  final LocationTrackingService _locationService = LocationTrackingService();
  bool _isLoading = false;
  String _permissionStatus = 'unknown';

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await _locationService.checkPermissionStatus();
    if (mounted) {
      setState(() {
        _permissionStatus = status;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Prompt user to enable location services
        if (mounted) {
          _showLocationServicesDialog();
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Request permission
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        // Permission granted - initialize location service and go back
        await _locationService.initialize();
        if (mounted) {
          Get.snackbar(
            'success'.tr,
            'location_permission_granted'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
          Get.back();
        }
      } else if (permission == LocationPermission.deniedForever) {
        // Permission denied forever - show dialog to open settings
        if (mounted) {
          _showOpenSettingsDialog();
        }
      } else {
        // Permission denied
        if (mounted) {
          Get.snackbar(
            'error'.tr,
            'location_permission_denied'.tr,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error, color: Colors.white),
          );
        }
      }
      
      await _checkPermissionStatus();
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          'location_permission_error'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final opened = await openAppSettings();
      if (!opened && mounted) {
        Get.snackbar(
          'error'.tr,
          'could_not_open_settings'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error opening settings: $e');
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          'could_not_open_settings'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Recheck permission after user returns from settings
        await Future.delayed(const Duration(milliseconds: 500));
        await _checkPermissionStatus();
      }
    }
  }

  void _showLocationServicesDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('location_services_disabled'.tr, 
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text('location_services_disabled_message'.tr,
          style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: GoogleFonts.ubuntu()),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
            ),
            child: Text('open_settings'.tr, 
              style: GoogleFonts.ubuntu(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('location_permission_denied_forever'.tr, 
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.w700)),
        content: Text('location_permission_denied_forever_message'.tr,
          style: GoogleFonts.ubuntu()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: GoogleFonts.ubuntu()),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
            ),
            child: Text('open_settings'.tr, 
              style: GoogleFonts.ubuntu(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.location,
                  size: 60,
                  color: ColorPages.COLOR_PRINCIPAL,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'location_permission_required'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'location_permission_description'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Benefits list
              _buildBenefitItem(
                icon: Iconsax.hospital,
                text: 'location_benefit_health_structures'.tr,
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                icon: Iconsax.routing,
                text: 'location_benefit_navigation'.tr,
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                icon: Iconsax.notification,
                text: 'location_benefit_emergency'.tr,
              ),
              const SizedBox(height: 40),
              
              // Action buttons
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                // Primary button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _permissionStatus == 'deniedForever' 
                        ? _openSettings 
                        : _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPages.COLOR_PRINCIPAL,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _permissionStatus == 'deniedForever'
                          ? 'open_settings'.tr
                          : 'enable_location'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Secondary button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      'skip_for_now'.tr,
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Status indicator
              if (_permissionStatus != 'unknown')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 16,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(),
                        style: GoogleFonts.ubuntu(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: ColorPages.COLOR_PRINCIPAL,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_permissionStatus) {
      case 'granted':
        return Colors.green;
      case 'denied':
        return Colors.orange;
      case 'deniedForever':
        return Colors.red;
      case 'servicesDisabled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_permissionStatus) {
      case 'granted':
        return Icons.check_circle;
      case 'denied':
        return Icons.warning;
      case 'deniedForever':
        return Icons.block;
      case 'servicesDisabled':
        return Icons.location_off;
      default:
        return Icons.help;
    }
  }

  String _getStatusText() {
    switch (_permissionStatus) {
      case 'granted':
        return 'location_status_granted'.tr;
      case 'denied':
        return 'location_status_denied'.tr;
      case 'deniedForever':
        return 'location_status_denied_forever'.tr;
      case 'servicesDisabled':
        return 'location_status_services_disabled'.tr;
      default:
        return 'location_status_unknown'.tr;
    }
  }
}
