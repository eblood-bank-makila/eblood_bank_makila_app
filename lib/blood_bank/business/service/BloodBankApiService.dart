import 'dart:async';
// Using dio_client instead of http package
import 'package:eblood_bank_mak_app/blood_bank/business/model/BloodEnums.dart';

import '../../../apps/config/api/dio_client.dart';
import '../../../apps/config/api/ApiConfig.dart';
import '../model/BloodStock.dart';
import '../../models/donor_eligibility.dart';

class BloodBankApiService {
  // No longer need UtilisateurLocalService as the dio_client handles token management
  
  BloodBankApiService();
  
  // No longer need _getHeaders as the dio_client's AuthInterceptor handles tokens

  // Blood Stock Management
  Future<ApiResponse<List<BloodStock>>> getBloodStock() async {
    try {
      // Use centralized dio client instead of http package
      final response = await getWithDio(
        ApiConfig.bloodStock,
      );

      // Debug the full response for troubleshooting
      print('📡 Full API Response:');
      print('  - success: ${response.success}');
      print('  - message: ${response.message}');
      print('  - statusCode: ${response.statusCode}');
      print('  - data type: ${response.data?.runtimeType}');
      print('  - data: ${response.data}');

      if (response.success) {
        // Extract items from the response structure
        List<dynamic> items = [];
        
        // The response.data is already the "data" field extracted from the API response
        // We just need to navigate to the items array
        if (response.data is Map) {
          if (response.data.containsKey('items')) {
            // This is the format in your logs: { items: [...], pagination: {...} }
            items = response.data['items'] as List;
            print('📦 Found ${items.length} items directly in response.data.items');
          } else {
            // Try other formats
            print('❓ Items not found directly in response.data, checking other structures...');
            print('📄 Available keys: ${response.data.keys.toList()}');
            
            // Check if any key contains a list that might be our items
            for (var key in response.data.keys) {
              if (response.data[key] is List && (response.data[key] as List).isNotEmpty) {
                items = response.data[key] as List;
                print('🔍 Found potential items list in key "$key" with ${items.length} items');
                break;
              } else if (response.data[key] is Map && (response.data[key] as Map).containsKey('items')) {
                items = (response.data[key] as Map)['items'] as List;
                print('🔍 Found potential items list in key "$key.items" with ${items.length} items');
                break;
              }
            }
          }
        } else if (response.data is List) {
          // Direct list response
          items = response.data as List;
          print('📦 Response data is directly a list with ${items.length} items');
        }
        
        // Check if we found any items
        if (items.isEmpty) {
          print('⚠️ No items found in the response - returning empty list');
          return ApiResponse.success(<BloodStock>[]);
        }
        
        print('🧩 Processing ${items.length} blood stock items');
        
        try {
          final List<BloodStock> stocks = items.map((item) {
            try {
              return BloodStock.fromJson(item);
            } catch (e) {
              print('⚠️ Error parsing individual blood stock item: $e');
              print('⚠️ Problematic item: $item');
              
              // Create a minimal valid BloodStock with the ID to avoid crashing
              return BloodStock(
                id: item['id']?.toString() ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
                bloodType: item['blood_type'] ?? item['bloodType'] ?? 'Unknown',
                volume: 0.0,
                productType: BloodProductType.wholeBlood,
                status: BloodBagStatus.available,
                bagCondition: BloodBagConditionStatus.good,
                expirationDate: DateTime.now().add(const Duration(days: 30)),
                collectionDate: DateTime.now(),
                donorId: '',
                batchNumber: item['batch_number'] ?? item['batchNumber'] ?? '',
                description: 'Error parsing item: ${item.keys.join(", ")}',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }
          }).toList();
          
          print('✅ Successfully parsed ${stocks.length} blood stock items');
          return ApiResponse.success(stocks);
        } catch (e) {
          print('💥 Error processing blood stock items: $e');
          return ApiResponse.error('Error processing blood stock data: $e');
        }
      } else {
        print('❌ API call failed: ${response.message}');
        return ApiResponse.error(response.message ?? 'Failed to load blood stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<BloodStock>> addBloodStock(BloodStock stock) async {
    try {
      // Prepare data payload to match the backend expectations
      final payload = {
        'bloodType': stock.bloodType,
        'volume': stock.volume,
        'productType': stock.productType.value,
        'status': stock.status.value,
        'bagCondition': stock.bagCondition.value,
        'expirationDate': stock.expirationDate.toIso8601String(),
        'collectionDate': stock.collectionDate.toIso8601String(),
        'donorId': stock.donorId.isNotEmpty ? stock.donorId : null,
        'batchNumber': stock.batchNumber,
        'description': stock.description,
      };
      
      // Get endpoint information for logging
      final endpoint = ApiConfig.bloodStockCreate;
      
      print('🚀 API CALL DETAILS:');
      print(' Endpoint: $endpoint');
      print(' Payload: $payload');
      
      // Use dio_client which handles tokens, timeouts, and errors automatically
      final response = await postWithDio(
        endpoint,
        body: payload,
        timeoutDuration: const Duration(seconds: 15),
      );

      print('� Response status: ${response.success ? 'Success' : 'Error'}');
      
      print('📡 Response debug info:');
      print('📡 - Success: ${response.success}');
      print('📡 - Status Code: ${response.statusCode}');
      print('📡 - Message: ${response.message}');
      print('📡 - Data: ${response.data}');
      
      // Check if the API call was successful
      // HTTP 200 and 201 are both success status codes
      if (response.success || (response.statusCode == 200 || response.statusCode == 201)) {
        // Process the data for successful response
        try {
          // The response.data might be a string ID directly in case of creation
          // or it might be an object with a data field
          dynamic data;
          
          if (response.data is String) {
            // If the data is just a string, it's likely the ID directly
            data = response.data;
            print('✅ Response data is a direct ID string: $data');
          } else if (response.data is Map) {
            // If it's a map, extract the data field
            data = response.data.containsKey('data') ? response.data['data'] : response.data;
            print('✅ Extracted data from response map: $data');
          }
          
          if (data == null) {
            print('❌ API returned success but no data');
            return ApiResponse.error('Server returned success but no data');
          }
          
          // Create a new stock object with the returned ID and data
          String id;
          if (data is String) {
            // If data is a string, use it directly as the ID
            id = data;
          } else if (data is Map) {
            // If data is a map, extract ID
            id = data['_id'] ?? data['id'] ?? '';
          } else {
            // Fallback for unexpected data type
            id = data.toString();
          }
          
          final newStock = stock.copyWith(id: id);
          
          print('✅ Successfully created stock with ID: ${newStock.id}');
          return ApiResponse.success(newStock);
        } catch (e) {
          print('❌ Error processing success response: $e');
          return ApiResponse.error('Error processing server response: $e');
        }
      } else {
        // The dio_client already handled error parsing
        return ApiResponse.error(response.message ?? 'Operation failed on the server');
      }
    } catch (e) {
      print('Exception in addBloodStock: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<BloodStock>> updateBloodStock(String id, BloodStock stock) async {
    try {
      final endpoint = ApiConfig.updateStock(id);
      final body = stock.toJson();
      
      // Use dio_client for the request
      final response = await postWithDio(
        endpoint, 
        body: body,
        // Using POST with _method: PUT for compatibility if needed
        // If your backend expects a true PUT, you might need to implement a putWithDio method
      );

      if (response.success) {
        final data = response.data;
        final updatedStock = BloodStock.fromJson(data['data']);
        return ApiResponse.success(updatedStock);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to update blood stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<bool>> deleteBloodStock(String id) async {
    try {
      final endpoint = ApiConfig.deleteStock(id);
      
      // Use dio_client deleteWithDio function
      final response = await deleteWithDio(endpoint);

      if (response.success) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to delete blood stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Blood Requests Management
  Future<ApiResponse<List<BloodRequest>>> getBloodRequests() async {
    try {
      final endpoint = ApiConfig.bloodRequests;
      
      // Use dio_client getWithDio function
      final response = await getWithDio(endpoint);

      if (response.success) {
        final data = response.data;
        final List<BloodRequest> requests = (data['data'] as List)
            .map((item) => BloodRequest.fromJson(item))
            .toList();
        
        return ApiResponse.success(requests);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to load blood requests');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<BloodRequest>> approveBloodRequest(String requestId, String notes) async {
    try {
      final endpoint = ApiConfig.approveRequest(requestId);
      final body = {
        'notes': notes,
        'approvedAt': DateTime.now().toIso8601String(),
      };
      
      // Use dio_client postWithDio function
      final response = await postWithDio(
        endpoint, 
        body: body,
      );

      if (response.success) {
        final data = response.data;
        final approvedRequest = BloodRequest.fromJson(data['data']);
        return ApiResponse.success(approvedRequest);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to approve blood request');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<BloodRequest>> rejectBloodRequest(String requestId, String reason) async {
    try {
      final endpoint = ApiConfig.rejectRequest(requestId);
      final body = {
        'reason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
      };
      
      // Use dio_client postWithDio function
      final response = await postWithDio(
        endpoint, 
        body: body,
      );

      if (response.success) {
        final data = response.data;
        final rejectedRequest = BloodRequest.fromJson(data['data']);
        return ApiResponse.success(rejectedRequest);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to reject blood request');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

    // Statistics and Analytics
  Future<ApiResponse<BloodBankStats>> getBloodBankStats() async {
    try {
      final endpoint = ApiConfig.bloodBankStats;
      
      print('🌐 BloodBankApiService: Fetching stats from $endpoint');
      // Use dio_client getWithDio function
      final response = await getWithDio(endpoint);

      if (response.success) {
        print('✅ BloodBankApiService: Stats API call successful');
        print('📊 Raw response data: ${response.data}');
        
        // The data we need is directly in the response data, not in a nested 'data' field
        final stats = BloodBankStats.fromJson(response.data);
        print('📊 Parsed stats: totalStock=${stats.totalStock}, activeRequests=${stats.activeRequests}');
        return ApiResponse.success(stats);
      } else {
        print('❌ BloodBankApiService: Stats API call failed: ${response.message}');
        return ApiResponse.error(response.message ?? 'Failed to load blood bank stats');
      }
    } catch (e) {
      print('❌ BloodBankApiService: Exception when loading stats: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Blood Type Availability
  Future<ApiResponse<Map<String, int>>> getBloodTypeAvailability() async {
    try {
      final endpoint = ApiConfig.bloodTypeAvailability;
      
      // Use dio_client getWithDio function
      final response = await getWithDio(endpoint);

      if (response.success) {
        final data = response.data;
        final availability = Map<String, int>.from(data['data']);
        return ApiResponse.success(availability);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to load blood type availability');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<DonorEligibility>> checkDonorEligibility(String donorId) async {
    try {
      final response = await getWithDio(
        ApiConfig.donorEligibility,
        queryParams: {'donor_id': donorId},
      );

      if (response.success) {
        Map<String, dynamic>? payload;
        final dynamic rawData = response.data;

        if (rawData is Map<String, dynamic>) {
          if (rawData['data'] is Map<String, dynamic>) {
            payload = Map<String, dynamic>.from(rawData['data'] as Map<String, dynamic>);
          } else {
            payload = Map<String, dynamic>.from(rawData);
          }
        }

        if (payload == null) {
          return ApiResponse.error('Invalid eligibility data received from server');
        }

        final eligibility = DonorEligibility.fromJson(payload);
        return ApiResponse.success(eligibility);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to check donor eligibility');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Expiring Stock
  Future<ApiResponse<List<BloodStock>>> getExpiringStock({int days = 7}) async {
    try {
      final endpoint = ApiConfig.expiringStock;
      final queryParams = {'days': days};
      
      // Use dio_client getWithDio function
      final response = await getWithDio(
        endpoint,
        queryParams: queryParams
      );

      if (response.success) {
        final data = response.data;
        final List<BloodStock> expiringStock = (data['data'] as List)
            .map((item) => BloodStock.fromJson(item))
            .toList();
        
        return ApiResponse.success(expiringStock);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to load expiring stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Low Stock Alert
  Future<ApiResponse<List<BloodStock>>> getLowStock({int threshold = 5}) async {
    try {
      final endpoint = ApiConfig.lowStock;
      final queryParams = {'threshold': threshold};
      
      // Use dio_client getWithDio function
      final response = await getWithDio(
        endpoint,
        queryParams: queryParams
      );

      if (response.success) {
        final data = response.data;
        final List<BloodStock> lowStock = (data['data'] as List)
            .map((item) => BloodStock.fromJson(item))
            .toList();
        
        return ApiResponse.success(lowStock);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to load low stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Recent Activity
  Future<ApiResponse<List<BloodBankActivity>>> getRecentActivity({int limit = 10}) async {
    try {
      final endpoint = ApiConfig.recentActivity;
      final queryParams = {'limit': limit};
      
      // Use dio_client getWithDio function
      final response = await getWithDio(
        endpoint,
        queryParams: queryParams
      );

      if (response.success) {
        final data = response.data;
        final List<BloodBankActivity> activities = (data['data'] as List)
            .map((item) => BloodBankActivity.fromJson(item))
            .toList();
        
        return ApiResponse.success(activities);
      } else {
        return ApiResponse.error(response.message ?? 'Failed to load recent activities');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}

// Generic API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(success: false, error: error);
  }
  
  String toDebugString() {
    return 'Success: $success, Data: $data, Error: $error';
  }
}

// Blood Bank Activity Model
class BloodBankActivity {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  BloodBankActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory BloodBankActivity.fromJson(Map<String, dynamic> json) {
    return BloodBankActivity(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
