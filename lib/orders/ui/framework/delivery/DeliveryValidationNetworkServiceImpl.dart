import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../business/model/delivery/DeliveryValidationModel.dart';
import '../../../business/service/DeliveryValidationNetworkService.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class QrCodeActionNetworkServiceImpl implements QrCodeActionNetworkService, DeliveryValidationNetworkService {
  final String baseURL;

  QrCodeActionNetworkServiceImpl(this.baseURL);

  @override
  Future<QrCodeActionResponseModel?> executeQrCodeAction(
    String requestedAction,
    String qrCodeData,
    String authToken,
  ) async {
    try {
      print("🚀 Starting QR code action request to: $baseURL/data/blood-request");
      print("📤 Action: $requestedAction");
      print("📤 QR Code data: $qrCodeData");
      print("🔑 Auth token: ${authToken.isNotEmpty ? "Present (${authToken.length} chars)" : "Empty"}");

      // Construct the URL with query parameters
      final uri = Uri.parse("$baseURL/data/blood-request").replace(queryParameters: {
        'requested_action': requestedAction,
        'action_data': qrCodeData,
      });

      print("🌐 Full URL: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
          "eblood-lockkeys": "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
        },
      );

      print("📡 HTTP Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseMap = json.decode(response.body) as Map<String, dynamic>;
        print("✅ Response parsed successfully: $responseMap");

        return QrCodeActionResponseModel.fromJson(responseMap);
      } else {
        print("❌ HTTP Error: ${response.statusCode} - ${response.reasonPhrase}");
        return QrCodeActionResponseModel(
          success: false,
          message: "Erreur HTTP: ${response.statusCode} - ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print("💥 Exception during QR code action: $e");
      return QrCodeActionResponseModel(
        success: false,
        message: "Erreur de connexion: $e",
      );
    }
  }

  @override
  Future<DeliveryValidationResponseModel?> validateDelivery(
    String qrCodeData,
    String authToken,
  ) async {
    return await executeQrCodeAction('delivery_validation', qrCodeData, authToken);
  }
}

// Keep old class name for backward compatibility
typedef DeliveryValidationNetworkServiceImpl = QrCodeActionNetworkServiceImpl;

// Test function - commented out to avoid hardcoded URLs
/*
void main() {
  HttpOverrides.global = MyHttpOverrides();

  // TODO: Use AppConfig.instance.fullApiUrl instead of hardcoded URL
  var baseUrlTest = "http://192.168.30.132:3101/eblood-hstdapi/v1";
  var impl = QrCodeActionNetworkServiceImpl(baseUrlTest);
  var token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0wOS0xOVQxMjoxMTo0Ny4yMTVaIiwiaWF0IjoxNzI2NzQ3NjA3LCJleHAiOjE3MjcwMDY4MDd9.0-IMlUwcOFsgGVnIkFzfgP-YbTBMoOZ7TybzBWPYiO4';

  var testQrCode = "eblood___request___66d717cd75d90a7bc227fd20___66e83a46e207195903763505";
  impl.validateDelivery(testQrCode, token);
  impl.executeQrCodeAction('password', testQrCode, token);
}
*/
