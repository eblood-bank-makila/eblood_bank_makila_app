import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:eblood_bank_mak_app/core/services/location_access.dart';

/// Records which platform call the helper made, so each test can assert the
/// user lands on the right Android screen for the state they are in.
class _FakePlatform {
  _FakePlatform({
    this.serviceEnabled = true,
    this.permission = LocationPermission.denied,
  });

  bool serviceEnabled;
  LocationPermission permission;

  /// What the user answers when the system prompt shows.
  LocationPermission permissionAfterRequest = LocationPermission.whileInUse;
  final calls = <String>[];

  LocationAccess build() => LocationAccess(
        isServiceEnabled: () async => serviceEnabled,
        checkPermission: () async => permission,
        requestPermission: () async {
          calls.add('requestPermission');
          permission = permissionAfterRequest;
          return permission;
        },
        openLocationSettings: () async {
          calls.add('openLocationSettings');
          return true;
        },
        openAppSettings: () async {
          calls.add('openAppSettings');
          return true;
        },
      );
}

void main() {
  group('status', () {
    test('phone location off wins over a granted permission', () async {
      final access = _FakePlatform(
        serviceEnabled: false,
        permission: LocationPermission.whileInUse,
      ).build();
      expect(await access.status(), LocationAccessStatus.servicesDisabled);
    });

    test('maps every Geolocator permission', () async {
      const expected = {
        LocationPermission.denied: LocationAccessStatus.denied,
        LocationPermission.unableToDetermine: LocationAccessStatus.denied,
        LocationPermission.deniedForever: LocationAccessStatus.deniedForever,
        LocationPermission.whileInUse: LocationAccessStatus.granted,
        LocationPermission.always: LocationAccessStatus.granted,
      };
      for (final entry in expected.entries) {
        final access = _FakePlatform(permission: entry.key).build();
        expect(await access.status(), entry.value, reason: '${entry.key}');
      }
    });
  });

  group('fix', () {
    test('phone location off opens the Android location screen', () async {
      final fake = _FakePlatform(serviceEnabled: false);
      await fake.build().fix();
      expect(fake.calls, ['openLocationSettings']);
    });

    test('permission not granted shows the system prompt and reports the answer', () async {
      final fake = _FakePlatform(permission: LocationPermission.denied);
      final after = await fake.build().fix();
      expect(fake.calls, ['requestPermission']);
      expect(after, LocationAccessStatus.granted);
    });

    test('permission blocked opens the app settings page', () async {
      final fake = _FakePlatform(permission: LocationPermission.deniedForever);
      await fake.build().fix();
      expect(fake.calls, ['openAppSettings']);
    });

    test('already granted opens the app settings page so it can be turned off', () async {
      final fake = _FakePlatform(permission: LocationPermission.whileInUse);
      await fake.build().fix();
      expect(fake.calls, ['openAppSettings']);
    });
  });

  test('every status has its own label', () {
    final labels = LocationAccessStatus.values.map(LocationAccess.statusLabelKey).toSet();
    expect(labels.length, LocationAccessStatus.values.length);
  });
}
