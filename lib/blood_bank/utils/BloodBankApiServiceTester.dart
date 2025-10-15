import 'package:flutter/foundation.dart';
import '../business/service/BloodBankApiService.dart';

/// This class provides helper methods for testing the BloodBankApiService implementation
class BloodBankApiServiceTester {

  /// Test that all API calls work with the centralized token handling
  static Future<void> testApiIntegration() async {
    debugPrint('🧪 TESTING BLOOD BANK API SERVICE INTEGRATION');
    final apiService = BloodBankApiService();
    
    // Test getBloodStock method
    debugPrint('🧪 Testing getBloodStock...');
    try {
      final stockResult = await apiService.getBloodStock();
      debugPrint('✅ getBloodStock result: ${stockResult.success ? 'Success' : 'Error: ${stockResult.error}'}');
      if (stockResult.success) {
        debugPrint('📊 Retrieved ${stockResult.data?.length ?? 0} stock items');
      }
    } catch (e) {
      debugPrint('❌ getBloodStock test failed: $e');
    }
    
    // Test getBloodRequests method
    debugPrint('🧪 Testing getBloodRequests...');
    try {
      final requestsResult = await apiService.getBloodRequests();
      debugPrint('✅ getBloodRequests result: ${requestsResult.success ? 'Success' : 'Error: ${requestsResult.error}'}');
      if (requestsResult.success) {
        debugPrint('📊 Retrieved ${requestsResult.data?.length ?? 0} blood requests');
      }
    } catch (e) {
      debugPrint('❌ getBloodRequests test failed: $e');
    }
    
    // Test getBloodBankStats method
    debugPrint('🧪 Testing getBloodBankStats...');
    try {
      final statsResult = await apiService.getBloodBankStats();
      debugPrint('✅ getBloodBankStats result: ${statsResult.success ? 'Success' : 'Error: ${statsResult.error}'}');
    } catch (e) {
      debugPrint('❌ getBloodBankStats test failed: $e');
    }
    
    debugPrint('🧪 API INTEGRATION TESTS COMPLETED');
  }
}