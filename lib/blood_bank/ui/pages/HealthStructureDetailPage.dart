import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import '../../../apps/config/theme/ColorPages.dart';
import '../../data/models/HealthStructureModel.dart';

class HealthStructureDetailPage extends StatefulWidget {
  final HealthStructureModel structure;

  const HealthStructureDetailPage({
    super.key,
    required this.structure,
  });

  @override
  State<HealthStructureDetailPage> createState() => _HealthStructureDetailPageState();
}

class _HealthStructureDetailPageState extends State<HealthStructureDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool _isLoadingMap = false;
  String? _distanceText;
  String? _durationText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoadingMap = true;
    });

    try {
      // Get structure location
      final structurePosition = LatLng(
        widget.structure.latitude ?? -4.4419,
        widget.structure.longitude ?? 15.2663,
      );

      // Add structure marker
      _markers.add(Marker(
        point: structurePosition,
        width: 60.0,
        height: 60.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorPages.COLOR_PRINCIPAL,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _getStructureIcon(),
            color: Colors.white,
            size: 28.0,
          ),
        ),
      ));

      // Try to get user location
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var status = await Permission.location.request();
          if (status.isGranted) {
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 10,
              ),
            );

            _currentPosition = LatLng(position.latitude, position.longitude);

            // Add user marker
            _markers.add(Marker(
              point: _currentPosition!,
              width: 50.0,
              height: 50.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade600,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.location,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),
            ));

            // Calculate distance
            double distanceInMeters = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              structurePosition.latitude,
              structurePosition.longitude,
            );

            // Check if distance seems unreasonable (likely wrong coordinates)
            bool isUnreasonableDistance = distanceInMeters > 500000; // > 500 km
            
            setState(() {
              if (isUnreasonableDistance) {
                // Show warning instead of large distance
                _distanceText = 'invalid_coordinates'.tr;
                _durationText = null;
              } else {
                _distanceText = distanceInMeters < 1000
                    ? '${distanceInMeters.toInt()} m'
                    : '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
              }
            });

            // Get route only if distance is reasonable
            if (!isUnreasonableDistance) {
              try {
                List<LatLng> route = await _getRoute(_currentPosition!, structurePosition);
                if (route.isNotEmpty) {
                  _polylines.add(Polyline(
                    points: route,
                    strokeWidth: 4.0,
                    color: ColorPages.COLOR_PRINCIPAL,
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ));

                  // Estimate duration (assuming average speed of 40 km/h in city)
                  double durationHours = (distanceInMeters / 1000) / 40;
                  int durationMinutes = (durationHours * 60).round();
                  setState(() {
                    _durationText = durationMinutes < 60
                        ? '$durationMinutes ${'minutes_short'.tr}'
                        : '${(durationMinutes / 60).toStringAsFixed(1)} ${'hours_short'.tr}';
                  });
                }
              } catch (e) {
                // Route failed, add straight line (only if distance is reasonable)
                if (distanceInMeters < 100000) { // < 100 km
                  _polylines.add(Polyline(
                    points: [_currentPosition!, structurePosition],
                    strokeWidth: 2.0,
                    color: Colors.grey.shade400,
                  ));
                }
              }
            }

            // Center map to show both markers
            _mapController.move(structurePosition, 14.0);
          }
        }
      } catch (e) {
        // Location permission denied or error, just show structure
        _mapController.move(structurePosition, 15.0);
      }

      setState(() {
        _isLoadingMap = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  Future<List<LatLng>> _getRoute(LatLng start, LatLng end) async {
    final response = await http.get(
      Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<LatLng> route = [];
      if (data['routes'].isNotEmpty) {
        var coordinates = data['routes'][0]['geometry']['coordinates'];
        for (var coord in coordinates) {
          route.add(LatLng(coord[1], coord[0]));
        }
      }
      return route;
    } else {
      throw Exception('Failed to load route');
    }
  }

  IconData _getStructureIcon() {
    switch (widget.structure.healthStructureTypeFlag) {
      case EHealthStructureType.generalHospital:
      case EHealthStructureType.universityHospital:
        return Iconsax.hospital;
      case EHealthStructureType.clinic:
        return Iconsax.building_3;
      case EHealthStructureType.bloodBank:
        return Iconsax.health;
      case EHealthStructureType.healthCenter:
      case EHealthStructureType.healthCareCenter:
        return Iconsax.building;
      case EHealthStructureType.pharmacy:
        return Iconsax.health;
      case EHealthStructureType.emergencyCenter:
        return Iconsax.warning_2;
      case EHealthStructureType.maternity:
        return Iconsax.woman;
      case EHealthStructureType.medicalLab:
        return Iconsax.microscope;
      default:
        return Iconsax.building_4;
    }
  }

  Color _getStructureColor() {
    switch (widget.structure.healthStructureTypeFlag) {
      case EHealthStructureType.emergencyCenter:
        return Colors.red;
      case EHealthStructureType.bloodBank:
        return Colors.red.shade700;
      default:
        return ColorPages.COLOR_PRINCIPAL;
    }
  }

  bool _isCoordinatesInWrongRegion() {
    // Check if coordinates are likely in Africa (rough bounds)
    // Africa latitude: approximately -35 to 37 (north)
    // Africa longitude: approximately -17 to 52 (east)
    final lat = widget.structure.latitude;
    final lon = widget.structure.longitude;
    
    if (lat == null || lon == null) return false;
    
    // These coordinates (37.421998, -122.084) are in California, USA
    // African structures should have longitude between -17 and 52 (east)
    // and latitude between -35 and 37 (north)
    bool isInAfrica = lat >= -35 && lat <= 37 && lon >= -17 && lon <= 52;
    
    return !isInAfrica;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Image/Map Preview
          _buildSliverAppBar(),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Main Info Card
                _buildMainInfoCard(),

                // Tabs
                _buildTabSection(),
              ],
            ),
          ),
        ],
      ),
      // Floating Action Buttons
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorPages.COLOR_PRINCIPAL,
      leading: FadeInLeft(
        delay: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Iconsax.arrow_left_2, color: ColorPages.COLOR_PRINCIPAL),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Map Background
            if (_markers.isNotEmpty && !_isLoadingMap)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.structure.latitude ?? -4.4419,
                    widget.structure.longitude ?? 15.2663,
                  ),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleatet.flutter_map.example',
                  ),
                  MarkerLayer(markers: _markers),
                  PolylineLayer(polylines: _polylines),
                ],
              )
            else
              Container(
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
                child: Center(
                  child: Icon(
                    _getStructureIcon(),
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Distance & Duration Badge (if available)
            if (_distanceText != null)
              Positioned(
                top: 100,
                right: 20,
                child: FadeInRight(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _distanceText == 'invalid_coordinates'.tr
                          ? Colors.orange.shade50.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: _distanceText == 'invalid_coordinates'.tr
                          ? Border.all(color: Colors.orange, width: 1.5)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _distanceText == 'invalid_coordinates'.tr
                                  ? Iconsax.warning_2
                                  : Iconsax.routing,
                              size: 16,
                              color: _distanceText == 'invalid_coordinates'.tr
                                  ? Colors.orange
                                  : ColorPages.COLOR_PRINCIPAL,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _distanceText!,
                              style: GoogleFonts.ubuntu(
                                fontSize: _distanceText == 'invalid_coordinates'.tr ? 12 : 16,
                                fontWeight: FontWeight.bold,
                                color: _distanceText == 'invalid_coordinates'.tr
                                    ? Colors.orange.shade800
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (_durationText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _durationText!,
                            style: GoogleFonts.ubuntu(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Structure Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStructureColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStructureIcon(),
                    color: _getStructureColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.structure.name,
                        style: GoogleFonts.ubuntu(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.structure.healthStructureTypeFlag.label,
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color: _getStructureColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Status Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusBadge(
                  icon: Iconsax.status,
                  label: widget.structure.isActivated ? 'active'.tr : 'inactive'.tr,
                  color: widget.structure.isActivated ? Colors.green : Colors.grey,
                ),
                if (widget.structure.isVerified)
                  _buildStatusBadge(
                    icon: Iconsax.verify,
                    label: 'verified'.tr,
                    color: Colors.blue,
                  ),
                if (widget.structure.hasEmergencyServices)
                  _buildStatusBadge(
                    icon: Iconsax.warning_2,
                    label: 'emergency_24_7'.tr,
                    color: Colors.red,
                  ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Quick Info
            Text(
              'contact_information'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            if (widget.structure.address != null)
              _buildContactInfo(
                icon: Iconsax.location,
                label: 'address'.tr,
                value: widget.structure.address!,
                onTap: _openInMaps,
              ),

            if (widget.structure.phoneNumber != null)
              _buildContactInfo(
                icon: Iconsax.call,
                label: 'phone'.tr,
                value: widget.structure.phoneNumber!,
                onTap: () => _makePhoneCall(widget.structure.phoneNumber!),
              ),

            if (widget.structure.email != null)
              _buildContactInfo(
                icon: Iconsax.sms,
                label: 'email'.tr,
                value: widget.structure.email!,
                onTap: () => _sendEmail(widget.structure.email!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: ColorPages.COLOR_PRINCIPAL,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.ubuntu(
                  fontSize: 14,
                ),
                indicatorColor: ColorPages.COLOR_PRINCIPAL,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: Icon(Iconsax.info_circle),
                    text: 'details'.tr,
                  ),
                  Tab(
                    icon: Icon(Iconsax.map),
                    text: 'location'.tr,
                  ),
                ],
              ),
            ),

            // Tab View
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildMapTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
            title: 'identifier'.tr,
            icon: Iconsax.code_circle,
            content: widget.structure.identifier,
          ),
          
          if (widget.structure.latitude != null && widget.structure.longitude != null)
            _buildDetailSection(
              title: 'gps_coordinates'.tr,
              icon: Iconsax.location,
              content: "${'latitude'.tr}: ${widget.structure.latitude!.toStringAsFixed(6)}\n${'longitude'.tr}: ${widget.structure.longitude!.toStringAsFixed(6)}${_isCoordinatesInWrongRegion() ? '\n${'coordinates_out_of_region_warning'.tr}' : ''}",
            ),

          _buildDetailSection(
            title: 'structure_type'.tr,
            icon: Iconsax.category,
            content: widget.structure.healthStructureTypeFlag.label,
          ),

          if (widget.structure.altitude != null)
            _buildDetailSection(
              title: 'altitude'.tr,
              icon: Iconsax.trend_up,
              content: '${widget.structure.altitude!.toStringAsFixed(0)} m',
            ),

          // Additional Info Section
          const SizedBox(height: 16),
          Text(
            'structure_status'.tr,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoRow(
            label: 'activation_status'.tr,
            value: widget.structure.isActivated ? 'active'.tr : 'inactive'.tr,
            valueColor: widget.structure.isActivated ? Colors.green : Colors.grey,
          ),

          _buildInfoRow(
            label: 'verification'.tr,
            value: widget.structure.isVerified ? 'verified'.tr : 'not_verified'.tr,
            valueColor: widget.structure.isVerified ? Colors.blue : Colors.orange,
          ),

          _buildInfoRow(
            label: 'emergency_services'.tr,
            value: widget.structure.hasEmergencyServices ? 'available'.tr : 'not_available'.tr,
            valueColor: widget.structure.hasEmergencyServices ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: ColorPages.COLOR_PRINCIPAL,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (valueColor ?? Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.ubuntu(
                fontSize: 13,
                color: valueColor ?? Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    if (_isLoadingMap) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ColorPages.COLOR_PRINCIPAL,
            ),
            const SizedBox(height: 16),
            Text(
              'map_loading'.tr,
              style: GoogleFonts.ubuntu(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_markers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.map,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'map_unavailable'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'gps_coords_missing'.tr,
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(
            widget.structure.latitude ?? -4.4419,
            widget.structure.longitude ?? 15.2663,
          ),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.fleatet.flutter_map.example',
          ),
          MarkerLayer(markers: _markers),
          PolylineLayer(polylines: _polylines),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Navigate Button
        if (_currentPosition != null && widget.structure.latitude != null)
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: FloatingActionButton.extended(
              heroTag: 'navigate',
              onPressed: _openInMaps,
              backgroundColor: ColorPages.COLOR_PRINCIPAL,
              icon: const Icon(Iconsax.routing_2, color: Colors.white),
              label: Text(
                'directions'.tr,
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Call Button
        if (widget.structure.phoneNumber != null)
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: FloatingActionButton(
              heroTag: 'call',
              mini: true,
              onPressed: () => _makePhoneCall(widget.structure.phoneNumber!),
              backgroundColor: Colors.green,
              child: const Icon(Iconsax.call, color: Colors.white, size: 20),
            ),
          ),
      ],
    );
  }

  // Action Methods
  Future<void> _openInMaps() async {
    if (widget.structure.latitude == null || widget.structure.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'gps_coords_unavailable'.tr,
            style: GoogleFonts.ubuntu(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final lat = widget.structure.latitude!;
    final lon = widget.structure.longitude!;
    
    // Try Google Maps first, then Apple Maps
    final googleUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    final appleUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lon');

    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'open_maps_app_failed'.tr,
            style: GoogleFonts.ubuntu(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de passer l\'appel',
            style: GoogleFonts.ubuntu(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    final subject = Uri.encodeComponent('information_request'.tr);
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=$subject',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch email';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'email_send_failed'.tr,
            style: GoogleFonts.ubuntu(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
