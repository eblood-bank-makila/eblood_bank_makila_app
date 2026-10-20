/// The courier's duty stream needs geolocator_android's single cached
/// position stream: the app's own tracking stops while on duty and may not
/// restart until the duty lets go.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/core/services/location_tracking_service.dart';

class _FakeGeolocator extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  final streams = <StreamController<Position>>[];

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    final c = StreamController<Position>();
    streams.add(c);
    return c.stream;
  }
}

void main() {
  late _FakeGeolocator geolocator;
  final tracking = LocationTrackingService();

  setUp(() => GeolocatorPlatform.instance = geolocator = _FakeGeolocator());
  tearDown(() {
    tracking.resume();
    tracking.stopBackgroundTracking();
  });

  test('suspended: tracking lets go of its stream and a start waits for resume', () {
    tracking.startBackgroundTracking();
    expect(geolocator.streams.single.hasListener, isTrue);

    tracking.suspend();
    expect(tracking.isTracking, isFalse);
    expect(geolocator.streams.single.hasListener, isFalse);

    tracking.startBackgroundTracking(); // e.g. the search flow's requestPermission
    expect(tracking.isTracking, isFalse);
    expect(geolocator.streams, hasLength(1));

    tracking.resume();
    expect(tracking.isTracking, isTrue);
    expect(geolocator.streams, hasLength(2));
  });

  test('not tracking before: resume leaves it stopped', () {
    tracking.suspend();
    tracking.resume();
    expect(tracking.isTracking, isFalse);
    expect(geolocator.streams, isEmpty);
  });

  test('a stop while suspended (permission revoked) cancels the restart', () {
    tracking.startBackgroundTracking();
    tracking.suspend();
    tracking.stopBackgroundTracking();

    tracking.resume();
    expect(tracking.isTracking, isFalse);
  });
}
