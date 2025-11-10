import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eblood_bank_mak_app/core/services/location_tracking_service.dart';
import 'package:eblood_bank_mak_app/apps/config/route/Routes.dart';

/// Service to manage location permission checks and navigation
class LocationPermissionService {
  static final LocationPermissionService _instance = LocationPermissionService._internal();
  factory LocationPermissionService() => _instance;
  LocationPermissionService._internal();

  final LocationTrackingService _locationService = LocationTrackingService();

  /// Check if location permission is granted
  Future<bool> checkPermission() async {
    return await _locationService.isPermissionGranted();
  }

  /// Check permission and navigate to warning screen if denied
  /// Returns true if permission is granted, false if user was navigated to warning screen
  Future<bool> checkAndNavigateIfNeeded({
    bool showWarningIfDenied = true,
  }) async {
    final isGranted = await checkPermission();
    
    if (!isGranted && showWarningIfDenied) {
      // Navigate to location permission warning screen
      Get.toNamed('/app/$locationPermissionWarningPage');
      return false;
    }
    
    return isGranted;
  }

  /// Get detailed permission status
  Future<String> getPermissionStatus() async {
    return await _locationService.checkPermissionStatus();
  }

  /// Check if user should be warned about location permission
  /// Returns true if permission is denied or services are disabled
  Future<bool> shouldShowWarning() async {
    final status = await getPermissionStatus();
    return status == 'denied' || 
           status == 'deniedForever' || 
           status == 'servicesDisabled';
  }

  /// Show a bottom sheet explaining why location is needed
  void showLocationInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Get.theme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'location_permission_required'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'location_permission_description'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.toNamed('/app/$locationPermissionWarningPage');
                  },
                  child: Text('enable_location'.tr),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('skip_for_now'.tr),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Initialize and check location permission on app start
  /// This should be called after user logs in or app starts
  Future<void> initializeAndCheck({
    bool navigateIfDenied = false,
  }) async {
    try {
      // Check permission status
      final status = await getPermissionStatus();
      
      debugPrint('📍 Location permission status: $status');
      
      // If permission is denied and we should navigate, do so
      if (navigateIfDenied && (status == 'denied' || status == 'deniedForever')) {
        Get.toNamed('/app/$locationPermissionWarningPage');
      }
    } catch (e) {
      debugPrint('❌ Error initializing location permission check: $e');
    }
  }
}
