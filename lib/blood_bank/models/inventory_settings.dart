class InventorySettings {
  final Map<String, int> criticalThresholds;
  final Map<String, double> productPrices;
  final bool expirationAlertsEnabled;
  final int expirationAlertDays;
  final bool criticalStockAlertsEnabled;
  final bool dailySummaryEnabled;
  final String currency;

  InventorySettings({
    required this.criticalThresholds,
    required this.productPrices,
    required this.expirationAlertsEnabled,
    required this.expirationAlertDays,
    required this.criticalStockAlertsEnabled,
    required this.dailySummaryEnabled,
    this.currency = 'USD',
  });

  factory InventorySettings.fromJson(Map<String, dynamic> json) {
    // Helper function to convert values to double
    Map<String, double> parseProductPrices(Map<String, dynamic>? prices) {
      if (prices == null) return {};
      return prices.map((key, value) {
        if (value is int) {
          return MapEntry(key, value.toDouble());
        } else if (value is double) {
          return MapEntry(key, value);
        } else {
          return MapEntry(key, 0.0);
        }
      });
    }

    // Helper function to parse critical thresholds
    // Backend now sends list format: [{"blood_type": "A+", "threshold": 10}, ...]
    // Convert to map format for easier UI usage: {"A+": 10, ...}
    Map<String, int> parseCriticalThresholds(dynamic thresholds) {
      if (thresholds == null) return {};

      // If it's already a map (old format), return it
      if (thresholds is Map) {
        return Map<String, int>.from(thresholds);
      }

      // If it's a list (new format), convert to map
      if (thresholds is List) {
        Map<String, int> result = {};
        for (var item in thresholds) {
          if (item is Map && item.containsKey('blood_type') && item.containsKey('threshold')) {
            String bloodType = item['blood_type'].toString();
            int threshold = item['threshold'] is int ? item['threshold'] : int.tryParse(item['threshold'].toString()) ?? 0;
            result[bloodType] = threshold;
          }
        }
        return result;
      }

      return {};
    }

    // Parse currency - can be a string or an object
    String parseCurrency(dynamic currencyData) {
      if (currencyData == null) return 'USD';

      // If it's a string, return it
      if (currencyData is String) return currencyData;

      // If it's an object with code, return the code
      if (currencyData is Map && currencyData.containsKey('code')) {
        return currencyData['code'].toString().toUpperCase();
      }

      return 'USD';
    }

    return InventorySettings(
      criticalThresholds: parseCriticalThresholds(json['critical_thresholds']),
      productPrices: parseProductPrices(json['product_prices']),
      expirationAlertsEnabled: json['expiration_alerts_enabled'] ?? false,
      expirationAlertDays: json['expiration_alert_days'] ?? 7,
      criticalStockAlertsEnabled: json['critical_stock_alerts_enabled'] ?? false,
      dailySummaryEnabled: json['daily_summary_enabled'] ?? false,
      currency: parseCurrency(json['currency']),
    );
  }

  Map<String, dynamic> toJson() {
    // Convert critical thresholds map to list format for backend
    // From: {"A+": 10, "A-": 5}
    // To: [{"blood_type": "A+", "threshold": 10}, {"blood_type": "A-", "threshold": 5}]
    List<Map<String, dynamic>> thresholdsList = criticalThresholds.entries
        .map((entry) => {
              'blood_type': entry.key,
              'threshold': entry.value,
            })
        .toList();

    return {
      'critical_thresholds': thresholdsList,
      'product_prices': productPrices,
      'expiration_alerts_enabled': expirationAlertsEnabled,
      'expiration_alert_days': expirationAlertDays,
      'critical_stock_alerts_enabled': criticalStockAlertsEnabled,
      'daily_summary_enabled': dailySummaryEnabled,
      'currency': currency,
    };
  }
}
