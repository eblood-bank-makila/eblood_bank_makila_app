import 'package:flutter/foundation.dart';

import '../../../apps/config/api/dio_client.dart';
import '../model/poche/PocheModel.dart';

/// Pure helpers for the logged-in hospital's "Commander en ligne" /
/// "Adresses des banques" wizard.
///
/// The wizard used to hit `GET /eblood-connect/blood-bags?blood_bank_id=`
/// and the `/pricing/*` module, neither of which is granted to ANY
/// profile nor whitelisted by `PermissionCheckMiddleware` — every call
/// 403'd as "Client error". The welcome-QR (visitor) flow works because
/// it only uses whitelisted routes and prices the address fee on-device,
/// so the hospital wizard now mirrors it:
///
///  * bags come from `blood-bags/search-simple` (same rows as the old
///    endpoint — both call `BloodBagSearchService.search_blood_bags`),
///    filtered here to the selected bank + blood type;
///  * the address-access fee is 10% of the bag price, exactly the
///    visitor payment page's `_viewAddressPrice`;
///  * the mobile-money phone is normalised to `+243…` like the visitor
///    page's `momoPhone`.
class HospitalBagPurchaseFlow {
  HospitalBagPurchaseFlow._();

  /// Page size of `search-simple` (backend caps `limit` at 100).
  static const int searchPageSize = 100;

  /// Hard stop so a runaway `total` can never loop forever.
  static const int _maxSearchPages = 20;

  /// Rows out of a `search-simple` / `blood-bags` response. Both endpoints
  /// answer `{success, data: {data: [...], total}}`, but tolerate the flat
  /// `{data: [...]}` and bare-list shapes too.
  static List<dynamic> rowsFromResponse(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map) {
      final nested = responseData['data'];
      if (nested is List) return nested;
      if (nested is Map && nested['data'] is List) {
        return nested['data'] as List;
      }
    }
    return const <dynamic>[];
  }

  /// `total` reported by the paginated envelope, or null when absent.
  static int? totalFromResponse(dynamic responseData) {
    if (responseData is! Map) return null;
    final nested = responseData['data'];
    final raw = nested is Map ? nested['total'] : responseData['total'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  /// Keep the rows that belong to [bloodBankId] and are exactly the
  /// [bloodType] the hospital asked for (e.g. `A+`), parsed to [PocheModel].
  static List<PocheModel> filterBankBags(
    List<dynamic> rows, {
    required String bloodBankId,
    required String bloodType,
  }) {
    final wanted = bloodType.trim().toUpperCase();
    final bags = <PocheModel>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final json = Map<String, dynamic>.from(row);
      final bank = json['blood_bank_info'];
      final rowBankId =
          bank is Map ? (bank['_id'] ?? bank['id'])?.toString() : null;
      if (rowBankId != bloodBankId) continue;

      final PocheModel bag;
      try {
        bag = PocheModel.fromJson(json);
      } catch (e) {
        debugPrint('⚠️ HospitalBagPurchaseFlow: unparsable bag row: $e');
        continue;
      }
      final fullType =
          '${bag.bloodBagInfo.bloodTypeInfo.bloodTypeName}${bag.bloodBagInfo.bloodRhesusInfo.bloodRheususName}'
              .toUpperCase();
      if (fullType != wanted) continue;
      bags.add(bag);
    }
    return bags;
  }

  /// All available bags of [bloodType] held by [bloodBankId], via the
  /// whitelisted `search-simple` route (paged until the reported total is
  /// reached, since it searches across every bank and only the backend
  /// caps at 100 per page).
  static Future<List<PocheModel>> fetchBankBags({
    required String bloodBankId,
    required String bloodType,
    double? userLatitude,
    double? userLongitude,
    double? hospitalLatitude,
    double? hospitalLongitude,
  }) async {
    final bags = <PocheModel>[];
    var page = 0;
    var fetched = 0;
    int? total;
    while (page < _maxSearchPages) {
      final queryParams = <String, dynamic>{
        'search_key': bloodType,
        'page': page,
        'limit': searchPageSize,
        if (userLatitude != null && userLongitude != null) ...{
          'user_latitude': userLatitude,
          'user_longitude': userLongitude,
        },
        if (hospitalLatitude != null && hospitalLongitude != null) ...{
          'hospital_latitude': hospitalLatitude,
          'hospital_longitude': hospitalLongitude,
        },
      };
      final response = await getWithDio(
        '/eblood-connect/blood-bags/search-simple',
        queryParams: queryParams,
      );
      if (!response.success) {
        throw Exception(
          (response.message?.trim().isNotEmpty ?? false)
              ? response.message
              : 'Failed to fetch blood bags (HTTP ${response.statusCode})',
        );
      }
      final rows = rowsFromResponse(response.data);
      total ??= totalFromResponse(response.data);
      bags.addAll(
        filterBankBags(rows, bloodBankId: bloodBankId, bloodType: bloodType),
      );
      fetched += rows.length;
      if (rows.isEmpty || rows.length < searchPageSize) break;
      if (total != null && fetched >= total) break;
      page++;
    }
    return bags;
  }

  /// Address-access fee = 10% of the bag price, in cents — the visitor
  /// payment page's `(_selectedPrice * 100).round()` with
  /// `_viewAddressPrice = _bloodBagPrice * 0.10`. Floors at 1 cent for a
  /// priced bag because `/payments/initiate/payment` rejects
  /// `amount_cents < 1`.
  static int addressAccessFeeCents(num bagPrice) {
    if (bagPrice <= 0) return 0;
    final cents = (bagPrice * 0.10 * 100).round();
    return cents < 1 ? 1 : cents;
  }

  /// `+243XXXXXXXXX` as the visitor flow sends it to the lokotro SDK.
  /// Accepts `243…`, `+243…`, `0…` and space/dash-separated input; null
  /// when nothing usable was typed.
  static String? normalizeMomoPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!digits.startsWith('243')) digits = '243$digits';
    return '+$digits';
  }
}
