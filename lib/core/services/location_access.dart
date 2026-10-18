import 'package:geolocator/geolocator.dart';

/// Where the app stands on reading the phone's position.
enum LocationAccessStatus { granted, servicesDisabled, denied, deniedForever }

/// The app has no position at all (phone location off, permission refused and
/// nothing saved), so a "nearby" search would be meaningless.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException();

  @override
  String toString() => 'LocationUnavailableException: no known position';
}

/// Reads the location state and takes the user to whatever fixes it: the
/// Android location switch, the permission prompt, or the app's settings page.
/// Shared by the profile "Localisation" row and the blood-bag tab.
class LocationAccess {
  LocationAccess({
    Future<bool> Function()? isServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<bool> Function()? openLocationSettings,
    Future<bool> Function()? openAppSettings,
  })  : _isServiceEnabled = isServiceEnabled ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _openLocationSettings = openLocationSettings ?? Geolocator.openLocationSettings,
        _openAppSettings = openAppSettings ?? Geolocator.openAppSettings;

  final Future<bool> Function() _isServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<bool> Function() _openLocationSettings;
  final Future<bool> Function() _openAppSettings;

  static String statusLabelKey(LocationAccessStatus status) => switch (status) {
        LocationAccessStatus.granted => 'location_access_status_granted',
        LocationAccessStatus.servicesDisabled => 'location_access_status_services_disabled',
        LocationAccessStatus.denied => 'location_access_status_denied',
        LocationAccessStatus.deniedForever => 'location_access_status_denied_forever',
      };

  Future<LocationAccessStatus> status() async {
    if (!await _isServiceEnabled()) return LocationAccessStatus.servicesDisabled;
    return _fromPermission(await _checkPermission());
  }

  /// Takes the step the current state calls for and returns the state right
  /// after it. When it opens a settings screen the change only happens once
  /// the user comes back, so callers re-read [status] on app resume.
  Future<LocationAccessStatus> fix() async {
    final current = await status();
    switch (current) {
      case LocationAccessStatus.servicesDisabled:
        await _openLocationSettings();
        return current;
      case LocationAccessStatus.denied:
        return _fromPermission(await _requestPermission());
      case LocationAccessStatus.deniedForever:
      case LocationAccessStatus.granted:
        await _openAppSettings();
        return current;
    }
  }

  static LocationAccessStatus _fromPermission(LocationPermission permission) => switch (permission) {
        LocationPermission.always || LocationPermission.whileInUse => LocationAccessStatus.granted,
        LocationPermission.deniedForever => LocationAccessStatus.deniedForever,
        LocationPermission.denied || LocationPermission.unableToDetermine => LocationAccessStatus.denied,
      };
}
