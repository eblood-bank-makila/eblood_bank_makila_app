import 'package:get_storage/get_storage.dart';

/// One-stop reader for the auth-state bits the new Sprint 15/17 contracts
/// need but didn't before: user_id, role flag, and org_ids.
///
/// Why a dedicated helper:
/// * Several services (coolbox, payments) all need the same data from
///   the same GetStorage shape. Inline reads diverge over time.
/// * The mapping from `mobile_app_*_profil` flags to the backend's
///   CoolboxRequestRole / CoolboxRequestOutcome enum lives here so any
///   schema drift only has to be fixed in one place.
class EbloodAuthHelper {
  EbloodAuthHelper._();

  static final GetStorage _storage = GetStorage();

  /// Logged-in user id, written by AuthApi at login under `user_data.id`.
  /// Returns empty string if not logged in (callers should validate).
  static String currentUserId() {
    final data = _storage.read('user_data');
    if (data is Map) {
      final raw = data['id'] ?? data['_id'];
      if (raw != null) return raw.toString();
    }
    return '';
  }

  /// Profile flags stored at login under `user_profiles[].profil` (or
  /// the legacy `user_profils` key — AuthApi writes both).
  static Set<String> profileFlags() {
    final dynamic raw =
        _storage.read('user_profiles') ?? _storage.read('user_profils');
    if (raw is! List) return <String>{};
    return raw
        .whereType<Map>()
        .map((m) => (m['profil'] ?? m['flag'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  /// All sys_organization_ids the user belongs to via their profiles.
  /// Backend's coolbox + payments endpoints want the full set so the
  /// access-gate can verify any of them against the delivery's parties.
  static List<String> currentUserOrgIds() {
    final dynamic raw =
        _storage.read('user_profiles') ?? _storage.read('user_profils');
    if (raw is! List) return <String>[];
    final ids = <String>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final candidate =
          entry['sys_organization_id'] ?? entry['organization_id'] ?? entry['org_id'];
      if (candidate != null && candidate.toString().isNotEmpty) {
        ids.add(candidate.toString());
      }
    }
    // Fall back to the user_data org if the profiles list is empty.
    if (ids.isEmpty) {
      final data = _storage.read('user_data');
      if (data is Map) {
        final candidate = data['sys_organization_id'] ?? data['organization_id'];
        if (candidate != null && candidate.toString().isNotEmpty) {
          ids.add(candidate.toString());
        }
      }
    }
    return ids.toList(growable: false);
  }

  /// Maps the user's profile flag to the backend's CoolboxRequestRole
  /// enum. Hospital wins over blood bank when both are present (matches
  /// the existing `_isHospitalAccount` precedence).
  static String coolboxRequestRole() {
    final flags = profileFlags();
    if (flags.contains('mobile_app_health_structure_profil')) return 'hospital';
    if (flags.contains('mobile_app_cnts_profil')) return 'cnts';
    if (flags.contains('mobile_app_blood_bank_profil')) return 'blood_bank';
    if (flags.contains('mobile_app_delivery_person_profil')) {
      return 'delivery_person';
    }
    return 'other';
  }
}
