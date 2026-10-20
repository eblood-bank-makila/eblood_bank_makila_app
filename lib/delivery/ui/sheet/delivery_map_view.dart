import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../business/model/delivery_tracking.dart';

const _routeColor = Color(0xFF1A73E8);
const _kinshasa = LatLng(-4.325, 15.322);

/// One look per place, shared by the map markers and the sheet's stop cards.
typedef StopLook = ({IconData icon, Color color});
const bankLook = (icon: Icons.bloodtype, color: Color(0xFFD0021B));
const hospitalLook = (icon: Icons.local_hospital, color: Color(0xFF00897B));
const courierLook = (icon: Icons.two_wheeler, color: Color(0xFF1D1D1F));

/// A round badge with the place's icon, white-ringed so it reads on any tile; [pin] adds the point
/// that marks the exact spot (bank, hospital). The courier's badge has none: it sits on its position.
Future<BitmapDescriptor> markerIcon(StopLook look, double pixelRatio, {required bool pin}) async {
  const size = 40.0, tip = 10.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);
  const center = Offset(size / 2, size / 2);
  if (pin) {
    canvas.drawPath(
      Path()
        ..moveTo(size / 2 - 8, size - 8)
        ..lineTo(size / 2, size + tip)
        ..lineTo(size / 2 + 8, size - 8)
        ..close(),
      Paint()..color = look.color,
    );
  }
  canvas.drawCircle(center, size / 2, Paint()..color = Colors.white);
  canvas.drawCircle(center, size / 2 - 3, Paint()..color = look.color);
  final glyph = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(look.icon.codePoint),
      style: TextStyle(fontSize: 22, fontFamily: look.icon.fontFamily, package: look.icon.fontPackage, color: Colors.white),
    ),
  )..layout();
  glyph.paint(canvas, center - Offset(glyph.width / 2, glyph.height / 2));
  final image = await recorder.endRecording().toImage((size * pixelRatio).ceil(), ((pin ? size + tip : size) * pixelRatio).ceil());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(png!.buffer.asUint8List(), imagePixelRatio: pixelRatio);
}

LatLng? _latLng(double? lat, double? lng) => lat == null || lng == null ? null : LatLng(lat, lng);

/// Everything the camera must show: the known pins, then the active route.
List<LatLng> trackingPoints(DeliveryTracking t) => [
      ?_latLng(t.bloodBank.lat, t.bloodBank.lng),
      ?_latLng(t.hospital.lat, t.hospital.lng),
      ?_latLng(t.courierPosition?.lat, t.courierPosition?.lng),
      for (final p in t.currentLeg?.points ?? const <LatLngPoint>[]) LatLng(p.lat, p.lng),
    ];

/// The live map of the delivery sheet: the active leg's road route (dashed when
/// it is only a straight-line estimate), bank / hospital / courier pins, and a
/// recenter button. Fits everything in view once the map is ready, and again
/// when the first coordinates arrive after an empty start.
class DeliveryMapView extends StatefulWidget {
  const DeliveryMapView({super.key, required this.tracking});

  final DeliveryTracking tracking;

  @override
  State<DeliveryMapView> createState() => _DeliveryMapViewState();
}

class _DeliveryMapViewState extends State<DeliveryMapView> {
  GoogleMapController? _controller;
  // bank, hospital, courier; the default pins show until they are drawn.
  List<BitmapDescriptor>? _icons;
  bool _drawing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_drawing) return;
    _drawing = true;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    Future.wait([
      markerIcon(bankLook, ratio, pin: true),
      markerIcon(hospitalLook, ratio, pin: true),
      markerIcon(courierLook, ratio, pin: false),
    ]).then((icons) {
      if (mounted) setState(() => _icons = icons);
    }, onError: (Object e) => debugPrint('[delivery-map] marker icons: $e'));
  }

  @override
  void didUpdateWidget(DeliveryMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The camera opened on Kinshasa with nothing to show: frame the first coordinates once they come.
    if (trackingPoints(oldWidget.tracking).isEmpty && trackingPoints(widget.tracking).isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fit();
      });
    }
  }

  Future<void> _fit() async {
    final c = _controller;
    final pts = trackingPoints(widget.tracking);
    if (c == null || pts.isEmpty) return;
    if (pts.length == 1) return c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 15));
    final lats = pts.map((p) => p.latitude), lngs = pts.map((p) => p.longitude);
    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
    );
    try {
      await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    } catch (_) {
      // Android refuses bounds while the map has no size yet; centre instead.
      final sw = bounds.southwest, ne = bounds.northeast;
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng((sw.latitude + ne.latitude) / 2, (sw.longitude + ne.longitude) / 2), 13),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tracking;
    final leg = t.currentLeg;
    final pts = trackingPoints(t);
    final icons = _icons;
    Marker pin(String id, LatLng at, int look, double hue, String? title) => Marker(
          markerId: MarkerId(id),
          position: at,
          icon: icons?[look] ?? BitmapDescriptor.defaultMarkerWithHue(hue),
          // The courier's badge is centred on its position; the pins point at theirs.
          anchor: icons != null && id == 'courier' ? const Offset(0.5, 0.5) : const Offset(0.5, 1),
          infoWindow: InfoWindow(title: title),
        );
    final bank = _latLng(t.bloodBank.lat, t.bloodBank.lng);
    final hospital = _latLng(t.hospital.lat, t.hospital.lng);
    final courier = _latLng(t.courierPosition?.lat, t.courierPosition?.lng);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: pts.isEmpty ? _kinshasa : pts.first, zoom: 13),
          // The sheet must not steal the pan / zoom gestures.
          gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)},
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          markers: {
            if (bank != null) pin('bank', bank, 0, BitmapDescriptor.hueRed, t.bloodBank.name),
            if (hospital != null) pin('hospital', hospital, 1, BitmapDescriptor.hueCyan, t.hospital.name),
            if (courier != null) pin('courier', courier, 2, BitmapDescriptor.hueViolet, t.courierName),
          },
          polylines: {
            if (leg != null && leg.points.length > 1)
              Polyline(
                polylineId: const PolylineId('route'),
                points: [for (final p in leg.points) LatLng(p.lat, p.lng)],
                color: _routeColor,
                width: 6,
                patterns: leg.approximate ? [PatternItem.dash(20), PatternItem.gap(12)] : const [],
              ),
          },
          onMapCreated: (c) {
            _controller = c;
            WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
          },
        ),
        Positioned(
          top: 10,
          right: 10,
          child: FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            tooltip: 'map_recenter'.tr,
            onPressed: _fit,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
