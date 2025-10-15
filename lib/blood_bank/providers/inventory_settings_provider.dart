import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_settings.dart';
import '../services/inventory_settings_service.dart';

// State class for inventory settings
class InventorySettingsState {
  final InventorySettings? settings;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const InventorySettingsState({
    this.settings,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  InventorySettingsState copyWith({
    InventorySettings? settings,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return InventorySettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// StateNotifier for managing inventory settings
class InventorySettingsNotifier extends StateNotifier<InventorySettingsState> {
  final InventorySettingsService _service;

  InventorySettingsNotifier(this._service) : super(const InventorySettingsState()) {
    // Load settings on initialization
    loadSettings();
  }

  // Load settings from backend
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final settings = await _service.fetchSettings();
      state = InventorySettingsState(
        settings: settings,
        isLoading: false,
        error: null,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des paramètres: ${e.toString()}',
      );
    }
  }

  // Refresh settings (for pull-to-refresh)
  Future<void> refreshSettings() async {
    await loadSettings();
  }

  // Update settings on backend
  Future<bool> updateSettings(InventorySettings settings) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updateSettings(settings);

      if (success) {
        state = InventorySettingsState(
          settings: settings,
          isLoading: false,
          error: null,
          lastUpdated: DateTime.now(),
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Échec de la mise à jour des paramètres',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour: ${e.toString()}',
      );
      return false;
    }
  }

  // ========== STRUCTURED UPDATE METHODS ==========

  /// Update a single product price using structured API
  Future<bool> updatePrice(String bloodComponent, double price) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updatePrice(bloodComponent, price);

      if (success) {
        // Reload settings to get updated data from backend
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Échec de la mise à jour du prix',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour du prix: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update a single critical stock threshold using structured API
  Future<bool> updateCriticalStock(String bloodType, int threshold) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updateCriticalStock(bloodType, threshold);

      if (success) {
        // Reload settings to get updated data from backend
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Échec de la mise à jour du seuil',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour du seuil: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update expiration parameters using structured API
  Future<bool> updateExpirationParams({
    int? alertDays,
    bool? enabled,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updateExpirationParams(
        alertDays: alertDays,
        enabled: enabled,
      );

      if (success) {
        // Reload settings to get updated data from backend
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Échec de la mise à jour des paramètres d\'expiration',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour des paramètres d\'expiration: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update notification settings using structured API
  Future<bool> updateNotifications({
    bool? email,
    bool? sms,
    bool? criticalAlerts,
    bool? dailySummary,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.updateNotifications(
        email: email,
        sms: sms,
        criticalAlerts: criticalAlerts,
        dailySummary: dailySummary,
      );

      if (success) {
        // Reload settings to get updated data from backend
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Échec de la mise à jour des notifications',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour des notifications: ${e.toString()}',
      );
      return false;
    }
  }
}

// Provider for the inventory settings service
final inventorySettingsServiceProvider = Provider<InventorySettingsService>((ref) {
  return InventorySettingsService();
});

// Main provider for inventory settings state
final inventorySettingsProvider = StateNotifierProvider<InventorySettingsNotifier, InventorySettingsState>((ref) {
  final service = ref.watch(inventorySettingsServiceProvider);
  return InventorySettingsNotifier(service);
});

// Legacy provider for backward compatibility (deprecated)
@Deprecated('Use inventorySettingsProvider instead')
final inventorySettingsUpdateProvider = Provider<InventorySettingsService>((ref) {
  return ref.watch(inventorySettingsServiceProvider);
});
