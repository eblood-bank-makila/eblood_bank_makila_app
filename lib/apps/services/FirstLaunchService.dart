import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

class FirstLaunchService extends StateNotifier<bool> {
  static const String _firstLaunchKey = 'app_has_been_launched';
  final GetStorage _storage = GetStorage();

  FirstLaunchService() : super(true) {
    // Initialize state from storage
    _loadFirstLaunchState();
  }

  void _loadFirstLaunchState() {
    // Check if app has been launched before
    final hasBeenLaunched = _storage.read(_firstLaunchKey) ?? false;
    final isFirstLaunch = !hasBeenLaunched; // If not launched before, it's first launch

    print('🔄 FirstLaunchService: hasBeenLaunched = $hasBeenLaunched');
    print('🔄 FirstLaunchService: isFirstLaunch = $isFirstLaunch');

    state = isFirstLaunch;
  }

  /// Check if this is the first launch of the app
  bool isFirstLaunch() {
    return state;
  }

  /// Mark that the app has been launched before
  Future<void> markFirstLaunchComplete() async {
    print('🔄 FirstLaunchService: Marking app as launched');
    await _storage.write(_firstLaunchKey, true); // Mark as launched
    state = false; // No longer first launch
    print('🔄 FirstLaunchService: App marked as launched, isFirstLaunch = false');
  }

  /// Reset first launch status (useful for testing)
  Future<void> resetFirstLaunch() async {
    print('🔄 FirstLaunchService: Resetting first launch status');
    await _storage.remove(_firstLaunchKey);
    state = true;
    print('🔄 FirstLaunchService: Reset complete, isFirstLaunch = true');
  }

  /// Debug method to check current storage state
  void debugStorageState() {
    final hasBeenLaunched = _storage.read(_firstLaunchKey);
    print('🔍 DEBUG: Storage key "$_firstLaunchKey" = $hasBeenLaunched');
    print('🔍 DEBUG: Current state (isFirstLaunch) = $state');
  }
}

// Provider for FirstLaunchService
final firstLaunchServiceProvider = StateNotifierProvider<FirstLaunchService, bool>((ref) {
  return FirstLaunchService();
});

// Provider to check if it's first launch (for backward compatibility)
final isFirstLaunchProvider = Provider<bool>((ref) {
  return ref.watch(firstLaunchServiceProvider);
});
