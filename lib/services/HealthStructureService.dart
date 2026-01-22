import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import '../apps/config/api/dio_client.dart';

// Storage keys for health structure data
const String _healthStructureKey = 'cached_health_structure';
const String _healthStructureTimestampKey = 'cached_health_structure_timestamp';
const int _cacheExpiryHours = 24; // Cache expires after 24 hours

// Provider for the HealthStructureService
final healthStructureServiceProvider = Provider<HealthStructureService>((ref) {
  return HealthStructureService();
});

class HealthStructureService {
  final GetStorage _storage = GetStorage();
  
  HealthStructureService();

  /// Get cached health structure from storage
  Map<String, dynamic>? getCachedHealthStructure() {
    try {
      final cachedData = _storage.read(_healthStructureKey);
      if (cachedData != null && cachedData is Map) {
        return Map<String, dynamic>.from(cachedData);
      }
      return null;
    } catch (e) {
      print('Error reading cached health structure: $e');
      return null;
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    try {
      final timestamp = _storage.read(_healthStructureTimestampKey);
      if (timestamp == null) return false;
      
      final cachedTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      return now.difference(cachedTime).inHours < _cacheExpiryHours;
    } catch (e) {
      return false;
    }
  }

  /// Save health structure to cache
  Future<void> _cacheHealthStructure(Map<String, dynamic> data) async {
    try {
      await _storage.write(_healthStructureKey, data);
      await _storage.write(_healthStructureTimestampKey, DateTime.now().toIso8601String());
      print('✅ Health structure cached successfully');
    } catch (e) {
      print('Error caching health structure: $e');
    }
  }

  /// Clear cached health structure (useful on logout)
  Future<void> clearCache() async {
    try {
      await _storage.remove(_healthStructureKey);
      await _storage.remove(_healthStructureTimestampKey);
      print('✅ Health structure cache cleared');
    } catch (e) {
      print('Error clearing health structure cache: $e');
    }
  }

  /// Get health structure for logged-in user
  /// First checks cache, then fetches from API if needed
  Future<Map<String, dynamic>?> getMyHealthStructure({bool forceRefresh = false}) async {
    try {
      // Check cache first (unless force refresh requested)
      if (!forceRefresh && _isCacheValid()) {
        final cached = getCachedHealthStructure();
        if (cached != null) {
          print('📦 Using cached health structure');
          return cached;
        }
      }

      print('🌐 Fetching my health structure from API');

      final response = await getWithDio('/eblood/hospital-structure/my-health-structure');

      print('Response success: ${response.success}');
      print('Response data: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data is Map ? response.data as Map<String, dynamic> : null;
        if (data != null) {
          final healthStructure = {
            'id': data['id'],
            'name': data['name'],
            'identifier': data['identifier'],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'address': data['address'],
            'phone_number': data['phone_number'],
            'email': data['email'],
          };
          
          // Cache the result
          await _cacheHealthStructure(healthStructure);
          
          return healthStructure;
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching my health structure: $e');
      
      // Return cached data as fallback on error
      final cached = getCachedHealthStructure();
      if (cached != null) {
        print('📦 Using cached health structure as fallback');
        return cached;
      }
      
      return null;
    }
  }

  /// Fetch and cache health structure (call on login/app start)
  Future<void> fetchAndCacheHealthStructure() async {
    try {
      await getMyHealthStructure(forceRefresh: true);
    } catch (e) {
      print('Error fetching and caching health structure: $e');
    }
  }

  /// Get health structure by identifier
  Future<Map<String, dynamic>?> getHealthStructureByIdentifier(String identifier) async {
    try {
      print('Fetching health structure by identifier: $identifier');

      final response = await getWithDio('/eblood/hospital-structure/by-identifier?identifier=$identifier');

      print('Response success: ${response.success}');
      print('Response data: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data is Map ? response.data as Map<String, dynamic> : null;
        if (data != null) {
          return {
            'id': data['id'],
            'name': data['name'],
            'identifier': data['identifier'],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'address': data['address'],
            'phone_number': data['phone_number'],
            'email': data['email'],
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching health structure by identifier: $e');
      return null;
    }
  }
}
