import '../models/inventory_settings.dart';
import '../../apps/config/api/ApiConfig.dart';
import '../../apps/config/api/dio_client.dart';

class InventorySettingsService {
  InventorySettingsService();

  String _getEndpoint() {
    return ApiConfig.inventorySettings;
  }

  Future<InventorySettings?> fetchSettings() async {
    final endpoint = _getEndpoint();

    print('📡 InventorySettingsService: Fetching settings from: $endpoint');

    try {
      final response = await getWithDio(endpoint);

      print('📡 InventorySettingsService: Response status: ${response.statusCode}');
      print('📡 InventorySettingsService: Response success: ${response.success}');
      print('📡 InventorySettingsService: Response message: ${response.message}');

      if (response.success && response.data != null) {
        print('✅ InventorySettingsService: Successfully fetched settings');
        return InventorySettings.fromJson(response.data);
      } else {
        print('❌ InventorySettingsService: Failed - ${response.message}');
        throw Exception('Failed to load settings: ${response.message}');
      }
    } catch (e) {
      print('❌ InventorySettingsService: Error fetching settings: $e');
      rethrow;
    }
  }

  Future<bool> updateSettings(InventorySettings settings) async {
    final endpoint = _getEndpoint();

    print('📡 InventorySettingsService: Updating settings at: $endpoint');

    try {
      final response = await putWithDio(
        endpoint,
        body: settings.toJson(),
      );

      print('📡 InventorySettingsService: Update response status: ${response.statusCode}');
      print('📡 InventorySettingsService: Update response success: ${response.success}');

      if (response.success) {
        print('✅ InventorySettingsService: Successfully updated settings');
        return true;
      } else {
        print('❌ InventorySettingsService: Update failed - ${response.message}');
        throw Exception('Failed to update settings: ${response.message}');
      }
    } catch (e) {
      print('❌ InventorySettingsService: Error updating settings: $e');
      rethrow;
    }
  }

  // ========== STRUCTURED UPDATE METHODS ==========

  /// Update a single product price
  ///
  /// Example:
  /// ```dart
  /// await service.updatePrice('whole_blood', 25.0);
  /// ```
  Future<bool> updatePrice(String bloodComponent, double price) async {
    final endpoint = _getEndpoint();

    print('📡 InventorySettingsService: Updating price for $bloodComponent to $price');

    try {
      final response = await putWithDio(
        endpoint,
        body: {
          'update_type': 'price',
          'blood_component': bloodComponent,
          'price': price,
        },
      );

      print('📡 InventorySettingsService: Update response status: ${response.statusCode}');
      print('📡 InventorySettingsService: Update response success: ${response.success}');

      if (response.success) {
        print('✅ InventorySettingsService: Successfully updated price for $bloodComponent');
        return true;
      } else {
        print('❌ InventorySettingsService: Update failed - ${response.message}');
        throw Exception('Failed to update price: ${response.message}');
      }
    } catch (e) {
      print('❌ InventorySettingsService: Error updating price: $e');
      rethrow;
    }
  }

  /// Update a single critical stock threshold
  ///
  /// Example:
  /// ```dart
  /// await service.updateCriticalStock('O+', 25);
  /// ```
  Future<bool> updateCriticalStock(String bloodType, int threshold) async {
    final endpoint = _getEndpoint();

    print('📡 InventorySettingsService: Updating critical stock for $bloodType to $threshold');

    try {
      final response = await putWithDio(
        endpoint,
        body: {
          'update_type': 'critical_stock',
          'blood_type': bloodType,
          'threshold': threshold,
        },
      );

      print('📡 InventorySettingsService: Update response status: ${response.statusCode}');
      print('📡 InventorySettingsService: Update response success: ${response.success}');

      if (response.success) {
        print('✅ InventorySettingsService: Successfully updated critical stock for $bloodType');
        return true;
      } else {
        print('❌ InventorySettingsService: Update failed - ${response.message}');
        throw Exception('Failed to update critical stock: ${response.message}');
      }
    } catch (e) {
      print('❌ InventorySettingsService: Error updating critical stock: $e');
      rethrow;
    }
  }

  /// Update expiration parameters
  ///
  /// Example:
  /// ```dart
  /// await service.updateExpirationParams(alertDays: 14, enabled: true);
  /// ```
  Future<bool> updateExpirationParams({
    int? alertDays,
    bool? enabled,
  }) async {
    final endpoint = _getEndpoint();

    print('📡 InventorySettingsService: Updating expiration params');

    try {
      final body = <String, dynamic>{
        'update_type': 'expiration_param',
      };

      if (alertDays != null) {
        body['expiration_alert_days'] = alertDays;
      }
      if (enabled != null) {
        body['expiration_alerts_enabled'] = enabled;
      }

      final response = await putWithDio(endpoint, body: body);

      print('📡 InventorySettingsService: Update response status: ${response.statusCode}');
      print('📡 InventorySettingsService: Update response success: ${response.success}');

      if (response.success) {
        print('✅ InventorySettingsService: Successfully updated expiration params');
        return true;
      } else {
        print('❌ InventorySettingsService: Update failed - ${response.message}');
        throw Exception('Failed to update expiration params: ${response.message}');
      }
    } catch (e) {
      print('❌ InventorySettingsService: Error updating expiration params: $e');
      rethrow;
    }
  }

  /// Update notification settings
  ///
  /// Example:
  /// ```dart
  /// await service.updateNotifications(email: true, criticalAlerts: true);
  /// ```
  Future<bool> updateNotifications({
    bool? email,
    bool? sms,
    bool? criticalAlerts,
    bool? dailySummary,
  }) async {
    final endpoint = _getEndpoint();

    print('📡 InventorySettingsService: Updating notification settings');

    try {
      final body = <String, dynamic>{
        'update_type': 'notification',
      };

      if (email != null) {
        body['email'] = email;
      }
      if (sms != null) {
        body['sms'] = sms;
      }
      if (criticalAlerts != null) {
        body['critical_stock_alerts_enabled'] = criticalAlerts;
      }
      if (dailySummary != null) {
        body['daily_summary_enabled'] = dailySummary;
      }

      final response = await putWithDio(endpoint, body: body);

      print('📡 InventorySettingsService: Update response status: ${response.statusCode}');
      print('📡 InventorySettingsService: Update response success: ${response.success}');

      if (response.success) {
        print('✅ InventorySettingsService: Successfully updated notification settings');
        return true;
      } else {
        print('❌ InventorySettingsService: Update failed - ${response.message}');
        throw Exception('Failed to update notification settings: ${response.message}');
      }
    } catch (e) {
      print('❌ InventorySettingsService: Error updating notification settings: $e');
      rethrow;
    }
  }
}
