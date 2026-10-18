import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/core/services/location_access.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Profile "Localisation" row: shows whether the app can read the phone's
/// position and, on tap, opens whatever fixes it (location switch, permission
/// prompt or the app's settings page). Re-reads the state when the user comes
/// back from Android settings.
class LocationAccessTile extends StatefulWidget {
  const LocationAccessTile({super.key, this.access});

  /// Injected by tests; the real Geolocator calls otherwise.
  final LocationAccess? access;

  @override
  State<LocationAccessTile> createState() => _LocationAccessTileState();
}

class _LocationAccessTileState extends State<LocationAccessTile> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await _access.status();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _onTap() async {
    final status = await _access.fix();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final granted = status == LocationAccessStatus.granted;
    final statusColor = granted ? Colors.green.shade700 : Colors.orange.shade800;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.2), width: 1),
      ),
      // Transparent Material so the ripple paints above the tinted box.
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: _onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              granted || status == null ? Iconsax.location : Iconsax.location_slash,
              size: 20,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          title: Text(
            'location_access_title'.tr,
            style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          subtitle: status == null
              ? null
              : Text(
                  LocationAccess.statusLabelKey(status).tr,
                  style: GoogleFonts.ubuntu(fontSize: 13, color: statusColor),
                ),
          trailing: Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
