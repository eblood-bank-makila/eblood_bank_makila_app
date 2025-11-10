import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';

import '../config/theme/ColorPages.dart';
import '../services/AuthService.dart';
import '../utils/error_utils.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';


class CustomerNearbyBloodBanksPage extends StatefulWidget {
  const CustomerNearbyBloodBanksPage({super.key});

  @override
  State<CustomerNearbyBloodBanksPage> createState() => _CustomerNearbyBloodBanksPageState();
}

class _CustomerNearbyBloodBanksPageState extends State<CustomerNearbyBloodBanksPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _banks = [];

  @override
  void initState() {
    super.initState();
    _loadNearbyBanks();
  }

  Future<void> _loadNearbyBanks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'location_services_disabled'.tr;
          _isLoading = false;
        });
        _showLocationServiceDialog();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'location_permission_denied'.tr;
            _isLoading = false;
          });
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'location_permission_denied_forever'.tr;
          _isLoading = false;
        });
        _showPermissionDialog(isPermanentlyDenied: true);
        return;
      }

      // Try to get current location quickly with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 20));

      final result = await _authService.getNearbyBloodBanks(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0,
        limit: 20,
      );

      if (result['success'] == true) {
        setState(() {
          _banks = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = ErrorUtils.userMessage(result['message'], fallback: 'Failed to fetch nearby blood banks');
          _isLoading = false;
        });
      }
    } on TimeoutException catch (e, st) {
      ErrorUtils.log(e, st, 'NearbyBloodBanks:location');
      setState(() {
        _errorMessage = ErrorUtils.userMessage(e, fallback: 'Location request timed out');
        _isLoading = false;
      });
    } catch (e, st) {
      ErrorUtils.log(e, st, 'NearbyBloodBanks:fetch');
      setState(() {
        _errorMessage = ErrorUtils.userMessage(e, fallback: 'Failed to fetch nearby blood banks');
        _isLoading = false;
      });
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.location_slash, color: ColorPages.COLOR_PRINCIPAL),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'location_services_disabled'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          'location_services_disabled_message'.tr,
          style: GoogleFonts.ubuntu(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr, style: GoogleFonts.ubuntu()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
            ),
            child: Text('open_settings'.tr, style: GoogleFonts.ubuntu()),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog({bool isPermanentlyDenied = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.location_slash, color: ColorPages.COLOR_PRINCIPAL),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'location_permission_required'.tr,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          isPermanentlyDenied
              ? 'location_permission_permanently_denied_message'.tr
              : 'location_permission_required_message'.tr,
          style: GoogleFonts.ubuntu(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr, style: GoogleFonts.ubuntu()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (isPermanentlyDenied) {
                await Geolocator.openAppSettings();
              } else {
                _loadNearbyBanks();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isPermanentlyDenied ? 'open_settings'.tr : 'allow_location'.tr,
              style: GoogleFonts.ubuntu(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('nearby_blood_banks'.tr),
        backgroundColor: ColorPages.COLOR_PRINCIPAL,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNearbyBanks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildError(theme)
                : _banks.isEmpty
                    ? _buildEmpty(theme)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _banks.length,
                        itemBuilder: (context, index) => _bankCard(theme, _banks[index]),
                      ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Iconsax.location_slash, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _errorMessage ?? 'Error',
            textAlign: TextAlign.center,
            style: GoogleFonts.ubuntu(fontSize: 16, color: theme.colorScheme.error),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: _loadNearbyBanks,
            icon: const Icon(Iconsax.refresh),
            label: Text('retry'.tr, style: GoogleFonts.ubuntu()),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Iconsax.building_3, size: 64, color: theme.dividerColor),
        const SizedBox(height: 12),
        Text('no_facilities_found'.tr, textAlign: TextAlign.center, style: GoogleFonts.ubuntu(fontSize: 16)),
        const SizedBox(height: 24),
        Center(
          child: OutlinedButton.icon(
            onPressed: _loadNearbyBanks,
            icon: const Icon(Iconsax.refresh),
            label: Text('retry'.tr, style: GoogleFonts.ubuntu()),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _bankCard(ThemeData theme, Map<String, dynamic> bank) {
    final name = (bank['name'] ?? bank['title'] ?? '').toString();
    final address = (bank['address'] ?? bank['location'] ?? '').toString();
    final distance = _extractDistance(bank);
    final phone = (bank['phone'] ?? bank['phone_number'] ?? bank['telephone'] ?? '').toString();
    final lat = _toDouble(bank['latitude'] ?? bank['lat']);
    final lon = _toDouble(bank['longitude'] ?? bank['lng'] ?? bank['long']);
    final website = (bank['website'] ?? bank['site'] ?? bank['url'] ?? '').toString();

    String normalizedUrl(String url) {
      if (url.isEmpty) return url;
      if (url.startsWith('http://') || url.startsWith('https://')) return url;
      return 'https://$url';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Iconsax.hospital, color: ColorPages.COLOR_PRINCIPAL),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (address.isNotEmpty)
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                if (website.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public, size: 14, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text('Website', style: theme.textTheme.bodySmall?.copyWith(color: Colors.indigo)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (phone.isNotEmpty)
              IconButton(
                tooltip: 'Call',
                onPressed: () => _callPhone(phone),
                icon: const Icon(Icons.call),
              ),
            if (lat != null && lon != null)
              IconButton(
                tooltip: 'Directions',
                onPressed: () => _openMaps(lat, lon, address),
                icon: const Icon(Icons.directions),
              ),
            IconButton(
              tooltip: 'Share',
              onPressed: () {
                final details = [name, if (address.isNotEmpty) address].join('\n');
                final suffix = distance != null ? ' • ${distance.toStringAsFixed(1)} km' : '';
                Share.share('$details$suffix');
              },
              icon: const Icon(Icons.share),
            ),
          ],
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            useSafeArea: true,
            isScrollControlled: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('${distance.toStringAsFixed(1)} km', style: theme.textTheme.bodySmall?.copyWith(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(child: Text(address, style: theme.textTheme.bodyMedium)),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: address));
                            Get.snackbar('info'.tr, 'Address copied');
                          },
                          icon: const Icon(Icons.copy, size: 18),
                        ),
                      ],
                    ),
                  ],
                  if (website.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        final url = normalizedUrl(website);
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.public),
                      label: const Text('Website'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (phone.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPages.COLOR_PRINCIPAL,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _callPhone(phone),
                          icon: const Icon(Icons.call),
                          label: Text('Call', style: GoogleFonts.ubuntu()),
                        ),
                      if (lat != null && lon != null)
                        OutlinedButton.icon(
                          onPressed: () => _openMaps(lat, lon, address),
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () {
                          final details = [name, if (address.isNotEmpty) address].join('\n');
                          final suffix = distance != null ? ' • ${distance.toStringAsFixed(1)} km' : '';
                          Share.share('$details$suffix');
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double? _extractDistance(Map<String, dynamic> bank) {
    final v = bank['distance_km'] ?? bank['distanceKm'] ?? bank['distance'] ?? bank['km'];
    return _toDouble(v);
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      return double.tryParse(v);
    }
    return null;
  }

  Future<void> _callPhone(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      await launchUrl(uri);
    } catch (e) {
      Get.snackbar('Error', ErrorUtils.userMessage(e, fallback: 'Could not start call'));
    }
  }

  Future<void> _openMaps(double lat, double lon, String address) async {
    final google = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    final apple = Uri.parse('https://maps.apple.com/?daddr=$lat,$lon');
    try {
      if (await canLaunchUrl(google)) {
        await launchUrl(google, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(apple)) {
        await launchUrl(apple, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback to address search
      if (address.isNotEmpty) {
        final search = Uri.parse('https://www.google.com/maps/search/${Uri.encodeComponent(address)}');
        await launchUrl(search, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar('Error', ErrorUtils.userMessage(e, fallback: 'Could not open maps'));
    }
  }
}

