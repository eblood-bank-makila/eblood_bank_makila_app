import 'dart:io';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:flutter/material.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/banque/BanqueListeNetworkService.dart';
import 'package:eblood_bank_mak_app/core/services/location_tracking_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BanqueListeNetworkServiceImpl implements BanqueListeNetworkService {
  String baseURL;

  BanqueListeNetworkServiceImpl(this.baseURL);

  @override
  Future<List<BanqueModele>?> recuperationListeBanque(String token) async {
    try {
      // Get current GPS location from LocationTrackingService
      final locationService = LocationTrackingService();
      final location = await locationService.getLocationForApi();

      final latitude = location['latitude']!;
      final longitude = location['longitude']!;

      debugPrint("📍 Using location for API: $latitude, $longitude");

      // Call the nearby blood banks endpoint with GPS coordinates
      final response = await postWithDio(
        '/eblood-connect/blood-banks/nearby',
        body: {
          "latitude": latitude,
          "longitude": longitude,
          "radius_km": 100, // Search within 100km radius
          "has_stock": true, // Only blood banks with stock
          "page": 0,
          "limit": 50,
        },
      );

      debugPrint("📡 Blood banks API response: ${response.message}");

      if (!response.success) {
        debugPrint("⚠️ Failed to fetch blood banks: ${response.message}");
        return <BanqueModele>[];
      }

      // Parse the new response format: data.blood_bank
      final dynamic responseData = response.data;
      List<dynamic> items = <dynamic>[];

      if (responseData is Map) {
        // New format: data.blood_bank
        if (responseData.containsKey('blood_bank')) {
          final bloodBankData = responseData['blood_bank'];
          if (bloodBankData is List) {
            items = bloodBankData;
          }
        }
        // Fallback to old format
        else if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            items = data;
          }
        }
      } else if (responseData is List) {
        // Direct list response
        items = responseData;
      }

      debugPrint("✅ Parsed ${items.length} blood banks from response");

      // Convert to BanqueModele objects
      final responseFinal = items
          .whereType<Map>()
          .map((e) {
            try {
              // Map the new API response format to BanqueModele format
              final Map<String, dynamic> bankData = {
                '_id': e['blood_bank_id'] ?? e['id'] ?? e['_id'] ?? '',
                'identifier': e['blood_bank_id'] ?? e['identifier'] ?? e['id'] ?? e['_id'] ?? '',
                'blood_bank_name': e['name'] ?? e['blood_bank_name'] ?? '',
                'blood_bank_logo': e['logo'] ?? e['blood_bank_logo'] ?? '',
                'latitude': e['latitude']?.toString() ?? '0',
                'longitude': e['longitude']?.toString() ?? '0',
                'distance': e['distance_km']?.toString() ?? e['distance']?.toString(),
                'is_favorite': e['is_favorite'] ?? false,
                'inventory_summary': e['inventory_summary'], // Pass directly - BanqueModele will handle type checking
                'town_info': e['town_info'] is Map ? e['town_info'] : null, // Only pass if it's a Map
                'town_name': e['address']?.toString() ?? '', // Use address as town_name fallback
              };

              return BanqueModele.fromJson(bankData);
            } catch (parseError) {
              debugPrint("⚠️ Error parsing blood bank: $parseError");
              return null;
            }
          })
          .whereType<BanqueModele>() // Filter out nulls
          .toList();

      debugPrint("✅ Successfully parsed ${responseFinal.length} blood banks");

      // Sort by distance if available
      responseFinal.sort((a, b) {
        final distA = double.tryParse(a.distance ?? '999999') ?? 999999;
        final distB = double.tryParse(b.distance ?? '999999') ?? 999999;
        return distA.compareTo(distB);
      });

      return responseFinal;
    } catch (e) {
      debugPrint("❌ Error fetching blood banks: $e");
      return <BanqueModele>[];
    }
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
  var impl = BanqueListeNetworkServiceImpl(baseUrl);
  var token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoxNzI2MTM3ODQyNTY1LCJ0b2tlbiI6ImY2YzQ4YjcwZjUzNzRiZjM2MjAyYzk1MWJkZDYyNTU5N2Q2YWFjMmZkOTgyNWU2NjA4OTRmMjY0ZmVlMTE5ZGQiLCJpYXQiOjE3MjYxMzc4NDIsImV4cCI6MTcyNjM5NzA0Mn0.q1L06t0q3pv6JpDb52azAY001B6tIaHc6KHw3lFzG64';
  impl.recuperationListeBanque(token);
}
