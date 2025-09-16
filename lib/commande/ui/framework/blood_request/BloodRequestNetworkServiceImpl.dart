import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../business/model/blood_request/BloodRequestModel.dart';
import '../../../business/service/blood_request/BloodRequestNetworkService.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class BloodRequestNetworkServiceImpl implements BloodRequestNetworkService {
  final String baseURL;

  BloodRequestNetworkServiceImpl(this.baseURL);

  @override
  Future<BloodRequestResponseModel?> getPendingDeliveryRequests(
    int page,
    String authToken,
  ) async {
    return await getBloodRequestsByStatus(
      BloodRequestStatus.pendingDelivery,
      page,
      authToken,
    );
  }

  @override
  Future<BloodRequestResponseModel?> getInProgressDeliveryRequests(
    int page,
    String authToken,
  ) async {
    return await getBloodRequestsByStatus(
      BloodRequestStatus.inProgressDelivery,
      page,
      authToken,
    );
  }

  @override
  Future<BloodRequestResponseModel?> getDeliveredRequests(
    int page,
    String authToken,
  ) async {
    return await getBloodRequestsByStatus(
      BloodRequestStatus.delivered,
      page,
      authToken,
    );
  }

  @override
  Future<BloodRequestResponseModel?> getBloodRequestsByStatus(
    BloodRequestStatus status,
    int page,
    String authToken,
  ) async {
    try {
      final endpoint = "$baseURL/blood-requested/${status.value}/$page";
      print("🚀 Fetching blood requests: $endpoint");
      print("📄 Status: ${status.displayName}");
      print("📄 Page: $page");
      print("🔑 Auth token: ${authToken.isNotEmpty ? "Present (${authToken.length} chars)" : "Empty"}");

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
          "eblood-lockkeys": "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
        },
      );

      print("📡 HTTP Response status: ${response.statusCode}");
      debugPrint("📄 Response body: ${response.body}", wrapWidth: 1024);

      if (response.statusCode == 200) {
        final responseMap = json.decode(response.body) as Map<String, dynamic>;
        print("✅ Response parsed successfully");
        
        return BloodRequestResponseModel.fromJson(responseMap);
      } else {
        print("❌ HTTP Error: ${response.statusCode} - ${response.reasonPhrase}");
        return BloodRequestResponseModel(
          success: false,
          message: "Erreur HTTP: ${response.statusCode} - ${response.reasonPhrase}",
          data: [],
        );
      }
    } catch (e) {
      print("💥 Exception during blood request fetch: $e");
      return BloodRequestResponseModel(
        success: false,
        message: "Erreur de connexion: $e",
        data: [],
      );
    }
  }
}

// Test function
void main() {
  HttpOverrides.global = MyHttpOverrides();
  
  var baseUrlTest = "http://192.168.30.132:3101/eblood-hstdapi/v1";
  var impl = BloodRequestNetworkServiceImpl(baseUrlTest);
  var token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0wOS0xOVQxMjoxMTo0Ny4yMTVaIiwiaWF0IjoxNzI2NzQ3NjA3LCJleHAiOjE3MjcwMDY4MDd9.0-IMlUwcOFsgGVnIkFzfgP-YbTBMoOZ7TybzBWPYiO4';
  
  // Test all endpoints
  impl.getPendingDeliveryRequests(0, token);
  impl.getInProgressDeliveryRequests(0, token);
  impl.getDeliveredRequests(0, token);
}
