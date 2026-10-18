import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/core/services/location_access.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Shown in place of a "nearby" list when the phone's position is unknown.
/// The button fixes the location state; [onRetry] reloads the list as soon as
/// the permission is granted, including when the user comes back from
/// Android settings.
class LocationNeededCard extends StatefulWidget {
  const LocationNeededCard({super.key, required this.onRetry, this.access});

  final Future<void> Function() onRetry;

  /// Injected by tests; the real Geolocator calls otherwise.
  final LocationAccess? access;

  @override
  State<LocationNeededCard> createState() => _LocationNeededCardState();
}

class _LocationNeededCardState extends State<LocationNeededCard> with WidgetsBindingObserver {
  late final LocationAccess _access = widget.access ?? LocationAccess();
  LocationAccessStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAndRetryIfGranted();
  }

  Future<void> _refresh() async {
    final status = await _access.status();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _refreshAndRetryIfGranted() async {
    final before = _status;
    await _refresh();
    if (before != LocationAccessStatus.granted && _status == LocationAccessStatus.granted) {
      await widget.onRetry();
    }
  }

  Future<void> _onPressed() async {
    if (_status == LocationAccessStatus.granted) {
      // Permission is fine but no fix came back (GPS slow indoors): try again.
      await widget.onRetry();
      return;
    }
    final status = await _access.fix();
    if (!mounted) return;
    setState(() => _status = status);
    if (status == LocationAccessStatus.granted) await widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Iconsax.location_slash, size: 40, color: ColorPages.COLOR_PRINCIPAL),
          ),
          const SizedBox(height: 16),
          Text(
            'location_access_needed_title'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'location_access_needed_message'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.grey.shade600),
          ),
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(
              LocationAccess.statusLabelKey(status).tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.orange.shade800),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: status == null ? null : _onPressed,
            icon: Icon(
              status == LocationAccessStatus.granted ? Iconsax.refresh : Iconsax.location,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              status == LocationAccessStatus.granted ? 'retry'.tr : 'location_access_enable'.tr,
              style: GoogleFonts.ubuntu(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }
}
