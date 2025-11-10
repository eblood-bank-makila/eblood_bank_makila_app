import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_tracking_service.dart';
import 'package:geolocator/geolocator.dart';

/// Widget to show when location permission is needed
/// Shows a friendly prompt with option to grant permission or open settings
class LocationPermissionPrompt extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  
  const LocationPermissionPrompt({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.orange.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'location_permission_required'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'location_permission_description'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.orange.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (onPermissionDenied != null) onPermissionDenied!();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                  child: Text('skip'.tr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final service = LocationTrackingService();
                    final granted = await service.requestPermission();
                    
                    if (granted) {
                      if (onPermissionGranted != null) onPermissionGranted!();
                    } else {
                      // Check if permanently denied
                      final status = await service.checkPermissionStatus();
                      if (status == 'deniedForever') {
                        _showOpenSettingsDialog(context);
                      } else {
                        if (onPermissionDenied != null) onPermissionDenied!();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('grant_permission'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text('open_settings'.tr),
          ],
        ),
        content: Text('location_permission_denied_forever'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: Text('open_settings'.tr),
          ),
        ],
      ),
    );
  }
}

/// Inline banner version (more compact)
class LocationPermissionBanner extends StatelessWidget {
  final VoidCallback? onDismiss;
  
  const LocationPermissionBanner({
    super.key,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'enable_location'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
                Text(
                  'location_improves_experience'.tr,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final service = LocationTrackingService();
              await service.requestPermission();
              if (onDismiss != null) onDismiss!();
            },
            child: Text('enable'.tr),
          ),
        ],
      ),
    );
  }
}
