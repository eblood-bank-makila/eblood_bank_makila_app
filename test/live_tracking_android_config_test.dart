/// Build plumbing for live delivery tracking: Google Maps SDK key + the
/// permissions the location foreground service needs (source scans, no device).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('manifest carries the Maps key through the mapsApiKey placeholder', () {
    expect(manifest, contains('com.google.android.geo.API_KEY'));
    expect(manifest, contains(r'${mapsApiKey}'));
  });

  test('manifest declares the foreground-service and notification permissions', () {
    for (final p in ['FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_LOCATION', 'POST_NOTIFICATIONS']) {
      expect(manifest, contains('android.permission.$p"'), reason: p);
    }
  });

  test('gradle feeds MAPS_API_KEY from local.properties into the placeholder', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('MAPS_API_KEY'));
    expect(gradle, contains('manifestPlaceholders'));
  });

  test('google_maps_flutter is a dependency', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('google_maps_flutter:'));
  });

  test('.env exposes SUPPORT_PHONE for the call-support fallback', () {
    expect(File('.env').readAsStringSync(), matches(RegExp(r'^SUPPORT_PHONE=', multiLine: true)));
  });
}
