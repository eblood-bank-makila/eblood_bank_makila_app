import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;

import '../../../../apps/config/theme/ColorPages.dart';
import '../../../business/model/blood_request/BloodRequestModel.dart';
import '../../../business/model/delivery/DeliveryPositionModel.dart';
import 'DeliveryPositionCtrl.dart';

class DeliveryMapPage extends ConsumerStatefulWidget {
  final BloodRequestModel request;

  const DeliveryMapPage({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  ConsumerState<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends ConsumerState<DeliveryMapPage> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPositionAndUpdateMap();
    });
  }

  Future<void> _fetchPositionAndUpdateMap() async {
    final controller = ref.read(deliveryPositionCtrlProvider.notifier);
    await controller.fetchPositionFromRequest(widget.request);
    _updateMapWithPositionData();
  }

  void _updateMapWithPositionData() {
    final state = ref.read(deliveryPositionCtrlProvider);
    if (!state.hasValidPosition) return;

    final info = state.positionInfo!;
    _markers.clear();
    _polylines.clear();

    // Hospital marker (destination)
    final hospitalLatLng = LatLng(info.hospital.latitude, info.hospital.longitude);
    _markers.add(Marker(
      point: hospitalLatLng,
      width: 60.0,
      height: 60.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Iconsax.hospital,
          color: Colors.white,
          size: 28,
        ),
      ),
    ));

    // Delivery person marker (current position)
    final deliveryLatLng = LatLng(info.coolBox.latitude, info.coolBox.longitude);
    _markers.add(Marker(
      point: deliveryLatLng,
      width: 60.0,
      height: 60.0,
      child: Container(
        decoration: BoxDecoration(
          color: ColorPages.COLOR_PRINCIPAL,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Iconsax.truck,
          color: Colors.white,
          size: 28,
        ),
      ),
    ));

    // Center map between both points
    final bounds = LatLngBounds.fromPoints([hospitalLatLng, deliveryLatLng]);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));

    // Load route between points
    _loadRoute(deliveryLatLng, hospitalLatLng);

    setState(() {});
  }

  Future<void> _loadRoute(LatLng start, LatLng end) async {
    setState(() => _isLoadingRoute = true);

    try {
      final route = await _getRoute(start, end);
      if (route.isNotEmpty) {
        _polylines.add(Polyline(
          points: route,
          strokeWidth: 4.0,
          color: ColorPages.COLOR_PRINCIPAL,
        ));
      }
    } catch (e) {
      print('Error loading route: $e');
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  Future<List<LatLng>> _getRoute(LatLng start, LatLng end) async {
    final response = await http.get(
      Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson',
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-4.4419, 15.2663), // Kinshasa default
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.eblood.makila',
              ),
              if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
              if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
            ],
          ),

          // Header
          _buildHeader(),

          // Bottom info panel
          _buildBottomPanel(),

          // Loading indicator for route
          if (_isLoadingRoute)
            Positioned(
              top: 120,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(ColorPages.COLOR_PRINCIPAL),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chargement de l\'itinéraire...',
                      style: GoogleFonts.ubuntu(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Refresh button
          FloatingActionButton(
            heroTag: "refresh",
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _fetchPositionAndUpdateMap,
            child: Icon(
              Iconsax.refresh,
              color: ColorPages.COLOR_PRINCIPAL,
            ),
          ),
          const SizedBox(height: 8),
          // Center map button
          FloatingActionButton(
            heroTag: "center",
            mini: true,
            backgroundColor: ColorPages.COLOR_PRINCIPAL,
            onPressed: () {
              if (_markers.length >= 2) {
                final bounds = LatLngBounds.fromPoints([
                  _markers[0].point,
                  _markers[1].point,
                ]);
                _mapController.fitCamera(
                  CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
                );
              }
            },
            child: const Icon(
              Iconsax.location,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Position de livraison',
                    style: GoogleFonts.ubuntu(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Demande #${widget.request.requestId}',
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
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(deliveryPositionCtrlProvider);
        
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: state.isLoading
                  ? _buildLoadingContent()
                  : state.hasValidPosition
                      ? _buildPositionContent(state)
                      : _buildErrorContent(state.error ?? 'Position non disponible'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingContent() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(ColorPages.COLOR_PRINCIPAL),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Chargement de la position...',
          style: GoogleFonts.ubuntu(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionContent(DeliveryPositionState state) {
    final info = state.positionInfo!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delivery person info
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
                Iconsax.user,
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
                    'Livreur',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    info.deliveryPerson,
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorPages.COLOR_PRINCIPAL,
                    ),
                  ),
                ],
              ),
            ),
            // Distance badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(state.distanceColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(state.distanceColor).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                state.formattedDistance,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(state.distanceColor),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Status message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(state.distanceColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.routing,
                color: Color(state.distanceColor),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                state.distanceStatus,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Color(state.distanceColor),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(String error) {
    return Row(
      children: [
        Icon(
          Iconsax.warning_2,
          color: Colors.orange.shade600,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            error,
            style: GoogleFonts.ubuntu(
              fontSize: 16,
              color: Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
