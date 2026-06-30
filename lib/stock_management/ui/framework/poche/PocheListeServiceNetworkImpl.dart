import 'package:eblood_bank_mak_app/stock_management/business/model/poche/PocheModel.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/poche/PocheListeNetworkService.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PocheListeNetworkServiceImpl implements PocheListeNetworkService {
  String baseURL;

  PocheListeNetworkServiceImpl(this.baseURL);

  @override
  Future<List<PocheModel>?> recuperationListePoche(String _id, String token) async {
    try {
      debugPrint("📍 Fetching blood bags for blood bank: $_id");

      // Call the new endpoint with dio_client
      final response = await getWithDio(
        '/eblood-connect/blood-bags',
        queryParams: {'blood_bank_id': _id},
      );

      debugPrint("📡 Blood bags API response: ${response.message}");

      if (!response.success) {
        debugPrint("⚠️ Failed to fetch blood bags: ${response.message}");
        return <PocheModel>[];
      }

      // Parse the response - handle nested data structure
      final dynamic responseData = response.data;
      List<dynamic> items = <dynamic>[];

      if (responseData is Map) {
        // Check for nested data.data structure (from backend response)
        if (responseData.containsKey('data')) {
          final nestedData = responseData['data'];
          if (nestedData is Map && nestedData.containsKey('data')) {
            // Double nested: {data: {data: [...]}}
            final innerData = nestedData['data'];
            if (innerData is List) {
              items = innerData;
            }
          } else if (nestedData is List) {
            // Single nested: {data: [...]}
            items = nestedData;
          }
        }
      } else if (responseData is List) {
        // Direct list response
        items = responseData;
      }

      debugPrint("✅ Parsed ${items.length} blood bags from response");

      // Convert flat API response to PocheModel format
      final responseFinal = items
          .whereType<Map>()
          .map((e) {
            try {
              // Transform flat structure to nested structure expected by PocheModel
              final transformedData = _transformBloodBagData(e as Map<String, dynamic>);
              return PocheModel.fromJson(transformedData);
            } catch (parseError) {
              debugPrint("⚠️ Error parsing blood bag: $parseError");
              debugPrint("⚠️ Problematic data: $e");
              return null;
            }
          })
          .whereType<PocheModel>() // Filter out nulls
          .toList();

      debugPrint("✅ Successfully parsed ${responseFinal.length} blood bags");

      return responseFinal;
    } catch (e) {
      debugPrint("❌ Error fetching blood bags: $e");
      return <PocheModel>[];
    }
  }

  /// Transform flat API response to nested structure expected by PocheModel
  Map<String, dynamic> _transformBloodBagData(Map<String, dynamic> flatData) {
    // If the backend already returns the nested "blood_bag_info" structure, reuse it directly
    if (flatData['blood_bag_info'] is Map) {
      final info = Map<String, dynamic>.from(flatData['blood_bag_info'] as Map);

      final String resolvedId = info['_id']?.toString() ??
          info['id']?.toString() ??
          info['blood_bag_id']?.toString() ??
          info['identifier']?.toString() ??
          '';

      info['_id'] = resolvedId;
      info['identifier'] = info['identifier']?.toString() ?? resolvedId;

      return {
        'blood_bag_info': info,
        'blood_stock_count': flatData['blood_stock_count'] ?? 1,
        'price': (flatData['price'] is num)
            ? (flatData['price'] as num).toInt()
            : (flatData['price'] ?? 0),
        'blood_product_type': flatData['blood_product_type'],
        'status': flatData['status'],
        'batch_number': flatData['batch_number'],
        'expire_date': flatData['expire_date'],
        'days_until_expiry': flatData['days_until_expiry'],
        'blood_bag_condition': flatData['blood_bag_condition'],
        'currency_id': flatData['currency_id'],
        'currency_symbol': flatData['currency_symbol'],
        'currency_code': flatData['currency_code'],
        'description': flatData['description'],
      };
    }

    // Extract rhesus factor components (e.g., "B-" -> blood_type: "B", rhesus: "-")
    final rhesusFactorFull = flatData['rhesus_factor'] ?? 'O+';
    final bloodType = rhesusFactorFull.length > 1
        ? rhesusFactorFull.substring(0, rhesusFactorFull.length - 1)
        : 'O'; // "B-" -> "B"
    final rhesusFactor = rhesusFactorFull.length > 0
        ? rhesusFactorFull.substring(rhesusFactorFull.length - 1)
        : '+'; // "B-" -> "-"

    return {
      "blood_bag_info": {
        "_id": flatData['blood_bag_id'] ?? '',
        "is_activated": true,
        "identifier": flatData['identifier'] ?? '',
        "createdAt": flatData['collected_on_date'] ?? DateTime.now().toIso8601String(),
        "blood_type_id": '',
        "blood_rhesus_id": '',
        "blood_volume_id": '',
        "blood_type_info": {
          "_id": '',
          "is_activated": true,
          "identifier": '',
          "createdAt": DateTime.now().toIso8601String(),
          "blood_type_name": bloodType,
        },
        "blood_rhesus_info": {
          "_id": '',
          "is_activated": true,
          "identifier": '',
          "createdAt": DateTime.now().toIso8601String(),
          "blood_rheusus_name": rhesusFactor,
        },
        "blood_volume_info": {
          "_id": '',
          "is_activated": true,
          "identifier": '',
          "createdAt": DateTime.now().toIso8601String(),
          "blood_volume_name": flatData['volume'] ?? '450ml',
          "blood_volume_unity_id": '',
          "blood_volume_unity_info": {
            "_id": '',
            "is_activated": true,
            "identifier": '',
            "createdAt": DateTime.now().toIso8601String(),
            "blood_volume_unity_name": 'ml',
          }
        }
      },
      "blood_stock_count": 1,
      "price": (flatData['price'] is double)
          ? (flatData['price'] as double).toInt()
          : (flatData['price'] ?? 0),
      "blood_product_type": flatData['blood_product_type'],
      "status": flatData['status'],
      "batch_number": flatData['batch_number'],
      "expire_date": flatData['expire_date'],
      "days_until_expiry": flatData['days_until_expiry'],
      "blood_bag_condition": flatData['blood_bag_condition'],
      "currency_id": flatData['currency_id'],
      "currency_symbol": flatData['currency_symbol'] ?? '\$',
      "currency_code": flatData['currency_code'] ?? 'USD',
      "description": flatData['description'] ?? 'Aucune description disponible.',
    };
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  String baseUrl = dotenv.env['BASE_URL'] ?? '';

  var impl = PocheListeNetworkServiceImpl(baseUrl);
  // var data = BanqueListeModele(page: "0");
  var token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0wOS0xOVQxMjoxMTo0Ny4yMTVaIiwiaWF0IjoxNzI2NzQ3NjA3LCJleHAiOjE3MjcwMDY4MDd9.0-IMlUwcOFsgGVnIkFzfgP-YbTBMoOZ7TybzBWPYiO4';
  // impl.authenticate(data);
  var id = "66d717cd75d90a7bc227fd20";
  impl.recuperationListePoche(id, token);
}
