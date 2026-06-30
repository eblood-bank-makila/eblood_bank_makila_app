import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/AppSpinner.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class DistanceWidget extends StatelessWidget {
  final LatLng start;
  final LatLng end;

  DistanceWidget({required this.start, required this.end});

  double calculateDistance() {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Remove this widget as it's causing positioning issues
    // Distance is now shown in the info panel instead
    return const SizedBox.shrink();
  }
}

class LocalisationBanquePage extends ConsumerStatefulWidget {
  final List<BanqueModele> bloodBanks;

  LocalisationBanquePage({required this.bloodBanks});

  @override
  ConsumerState<LocalisationBanquePage> createState() =>
      _LocalisationBanquePageState();
}

class _LocalisationBanquePageState
    extends ConsumerState<LocalisationBanquePage> {
  List<Marker> markers = [];
  List<Polyline> polylines = [];
  List<Widget> distanceWidgets = [];
  LatLng? currentPosition;
  final MapController mapController = MapController();
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  String _statusMessage = 'Initialisation de la carte...';

  Future<LatLng?> _getCurrentLocation() async {
    try {
      setState(() {
        _statusMessage = 'Demande d\'autorisation de localisation...';
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = 'Services de localisation désactivés';
          _hasLocationPermission = false;
        });
        _showLocationDialog('Services de localisation désactivés',
            'Veuillez activer les services de localisation dans les paramètres.');
        return null;
      }

      // Request location permission
      var status = await Permission.location.request();
      if (status.isGranted) {
        setState(() {
          _statusMessage = 'Obtention de votre position...';
          _hasLocationPermission = true;
        });

        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );

        setState(() {
          _statusMessage = 'Position obtenue avec succès';
        });

        return LatLng(position.latitude, position.longitude);
      } else {
        setState(() {
          _statusMessage = 'Permission de localisation refusée';
          _hasLocationPermission = false;
        });
        _showLocationDialog('Permission requise',
            'L\'accès à votre localisation est nécessaire pour afficher votre position sur la carte.');
        return null;
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur lors de l\'obtention de la position';
        _hasLocationPermission = false;
      });
      _showLocationDialog('Erreur de localisation',
          'Impossible d\'obtenir votre position. Veuillez réessayer.');
      return null;
    }
  }

  void _showLocationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Iconsax.location_cross,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.ubuntu(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.ubuntu(
                  color: ColorPages.COLOR_PRINCIPAL,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
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

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initialisation de la carte...';
    });

    try {
      // Get current location first
      var positionPhone = await _getCurrentLocation();
      currentPosition = positionPhone;

      // Add user position marker if location is available
      if (currentPosition != null) {
        setState(() {
          _statusMessage = 'Ajout de votre position...';
        });

        markers.add(Marker(
          point: currentPosition!,
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
      }

      // Add bank markers and routes
      setState(() {
        _statusMessage = 'Ajout des banques de sang...';
      });

      for (int i = 0; i < widget.bloodBanks.length; i++) {
        var bank = widget.bloodBanks[i];
        var bankPosition = LatLng(
          double.tryParse(bank.latitude.toString()) ?? 0.0,
          double.tryParse(bank.longitude.toString()) ?? 0.0,
        );

        // Add bank marker
        markers.add(Marker(
          point: bankPosition,
          width: 50.0,
          height: 50.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorPages.COLOR_PRINCIPAL,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Iconsax.hospital,
              color: Colors.white,
              size: 24.0,
            ),
          ),
        ));

        // Add route if user position is available
        if (currentPosition != null) {
          setState(() {
            _statusMessage = 'Calcul de l\'itinéraire vers ${bank.blood_bank_name}...';
          });

          try {
            List<LatLng> route = await getRoute(currentPosition!, bankPosition);
            if (route.isNotEmpty) {
              polylines.add(Polyline(
                points: route,
                strokeWidth: 4.0,
                color: i == 0 ? ColorPages.COLOR_PRINCIPAL : Colors.blue.shade400,
                borderStrokeWidth: 2.0,
                borderColor: Colors.white,
              ));

              // Add distance widget
              distanceWidgets.add(
                DistanceWidget(start: currentPosition!, end: bankPosition),
              );
            }
          } catch (e) {
            // If route fails, add a simple straight line
            polylines.add(Polyline(
              points: [currentPosition!, bankPosition],
              strokeWidth: 2.0,
              color: Colors.grey.shade400,
            ));
          }
        }
      }

      // Center map on user position or first bank
      if (currentPosition != null) {
        mapController.move(currentPosition!, 14.0);
      } else if (widget.bloodBanks.isNotEmpty) {
        var firstBank = widget.bloodBanks.first;
        var bankPosition = LatLng(
          double.tryParse(firstBank.latitude.toString()) ?? -4.4419,
          double.tryParse(firstBank.longitude.toString()) ?? 15.2663,
        );
        mapController.move(bankPosition, 14.0);
      }

      setState(() {
        _isLoading = false;
        _statusMessage = 'Carte chargée avec succès';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erreur lors du chargement de la carte';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map - Base layer (should be at the bottom)
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentPosition ?? const LatLng(-4.4419, 15.2663),
                initialZoom: 14.0,
                minZoom: 10.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleatet.flutter_map.example',
                ),
                MarkerLayer(markers: markers),
                PolylineLayer(polylines: polylines),
              ],
            ),
          ),

          // Modern Header with Back Button - Top layer
          _buildModernHeader(context),

          // Info Panel - Bottom layer (only when not loading)
          if (!_isLoading) _buildInfoPanel(),

          // Loading Overlay - Top layer (only when loading)
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Refresh Location Button
          FloatingActionButton(
            heroTag: "refresh",
            mini: true,
            onPressed: () => _initializeMap(),
            backgroundColor: Colors.white,
            child: Icon(
              Iconsax.refresh,
              color: ColorPages.COLOR_PRINCIPAL,
              size: 20,
            ),
          ),

          const SizedBox(height: 12),

          // My Location Button
          FloatingActionButton(
            heroTag: "location",
            onPressed: () {
              if (currentPosition != null) {
                mapController.move(currentPosition!, 16.0);
              } else {
                _initializeMap();
              }
            },
            backgroundColor: ColorPages.COLOR_PRINCIPAL,
            child: Icon(
              Iconsax.location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: FadeInDown(
          delay: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.arrow_left_2,
                    color: ColorPages.COLOR_PRINCIPAL,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Localisation des banques',
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.bloodBanks.length} banque${widget.bloodBanks.length > 1 ? 's' : ''} trouvée${widget.bloodBanks.length > 1 ? 's' : ''}',
                      style: GoogleFonts.ubuntu(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasLocationPermission
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasLocationPermission
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasLocationPermission ? Iconsax.location : Iconsax.location_cross,
                      size: 12,
                      color: _hasLocationPermission
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _hasLocationPermission ? 'GPS' : 'No GPS',
                      style: GoogleFonts.ubuntu(
                        fontSize: 10,
                        color: _hasLocationPermission
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: FadeInUp(
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSpinner.pulse(
                    size: 60,
                    showMessage: false,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chargement de la carte',
                    style: GoogleFonts.ubuntu(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ubuntu(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    if (widget.bloodBanks.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: FadeInUp(
        delay: const Duration(milliseconds: 400),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Iconsax.hospital,
                      color: ColorPages.COLOR_PRINCIPAL,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Banques de sang',
                          style: GoogleFonts.ubuntu(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          currentPosition != null
                              ? 'Itinéraires calculés depuis votre position'
                              : 'Activez la localisation pour voir les itinéraires',
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bank List
              ...widget.bloodBanks.take(3).map((bank) => _buildBankItem(bank)),

              if (widget.bloodBanks.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${widget.bloodBanks.length - 3} autres banques',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankItem(BanqueModele bank) {
    final bankPosition = LatLng(
      double.tryParse(bank.latitude.toString()) ?? 0.0,
      double.tryParse(bank.longitude.toString()) ?? 0.0,
    );

    final distance = currentPosition != null
        ? Geolocator.distanceBetween(
            currentPosition!.latitude,
            currentPosition!.longitude,
            bankPosition.latitude,
            bankPosition.longitude,
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ColorPages.COLOR_PRINCIPAL,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.blood_bank_name,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (distance != null)
                  Text(
                    distance < 1000
                        ? '${distance.toInt()} m'
                        : '${(distance / 1000).toStringAsFixed(1)} km',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              mapController.move(bankPosition, 16.0);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.location,
                color: ColorPages.COLOR_PRINCIPAL,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
