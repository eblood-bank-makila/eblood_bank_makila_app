/// Google encoded-polyline decoder (precision 5) for the route legs the
/// tracking endpoint returns.
library;

/// Returns `[]` for empty or malformed input (stray character, truncated
/// value) — a bad route must never break the map.
List<({double lat, double lng})> decodePolyline(String encoded) {
  final points = <({double lat, double lng})>[];
  var index = 0, lat = 0, lng = 0;

  // One zig-zag varint; null when the string ends or holds an invalid char.
  int? nextValue() {
    var result = 0, shift = 0, b = 0;
    do {
      if (index >= encoded.length) return null;
      b = encoded.codeUnitAt(index++) - 63;
      if (b < 0 || b > 63) return null;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    final dLat = nextValue();
    final dLng = nextValue();
    if (dLat == null || dLng == null) return const [];
    lat += dLat;
    lng += dLng;
    points.add((lat: lat / 1e5, lng: lng / 1e5));
  }
  return points;
}
