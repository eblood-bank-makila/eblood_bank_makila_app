import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/rbac_local_storage.dart';
import '../data/rbac_repository.dart';
export '../data/rbac_repository.dart' show SseProgressEvent;
import '../models/rbac_models.dart';
import '../services/rbac_url_helper.dart';
import 'rbac_state.dart';

/// Repository provider.
final rbacRepositoryProvider = Provider<RbacRepository>((ref) {
  return RbacRepository();
});

/// RbacUrlHelper singleton provider.
final rbacUrlHelperProvider = Provider<RbacUrlHelper>((ref) {
  return RbacUrlHelper();
});

/// Main RBAC state provider.
final rbacProvider =
    StateNotifierProvider<RbacNotifier, RbacState>((ref) {
  final repository = ref.watch(rbacRepositoryProvider);
  return RbacNotifier(repository);
});

class RbacNotifier extends StateNotifier<RbacState> {
  final RbacRepository _repository;
  static RbacNotifier? _activeInstance;

  RbacNotifier(this._repository) : super(const RbacState()) {
    _activeInstance = this;
  }

  /// Reset the active RBAC state from non-Riverpod contexts (e.g. AuthService logout).
  /// No-op if the notifier has been disposed.
  static void resetIfActive() {
    _activeInstance?.reset();
  }

  /// Load agent applications from backend (blocking).
  /// Call this after successful authentication.
  /// Saves to local Isar cache on success.
  Future<void> loadApplications() async {
    if (state.isLoaded || state.isLoading) return;

    state = state.asLoading();
    try {
      final applications = await _repository.fetchAgentApplications();
      state = state.asLoaded(applications);
      // Cache locally for offline / fast reopen
      await RbacLocalStorage.instance.saveApplications(applications);
      if (kDebugMode) {
        print('[RBAC] Loaded ${applications.length} applications from API + cached');
      }
    } catch (e) {
      state = state.asError(e.toString());
      if (kDebugMode) {
        print('[RBAC] Error loading applications: $e');
      }
    }
  }

  /// Load applications from local Isar cache.
  /// Returns true if cache was found and loaded.
  Future<bool> loadFromCache() async {
    if (state.isLoaded) return true;

    try {
      final cached = await RbacLocalStorage.instance.loadApplications();
      if (cached != null && cached.isNotEmpty) {
        state = state.asLoaded(cached);
        if (kDebugMode) {
          print('[RBAC] Loaded ${cached.length} applications from cache');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[RBAC] Error loading from cache: $e');
      }
    }
    return false;
  }

  /// Load applications with SSE progress streaming.
  /// The [onProgress] callback is called for each SSE event (init, app_complete, done).
  /// Returns the loaded applications list.
  Future<List<RbacApplication>> loadApplicationsWithProgress(
    void Function(SseProgressEvent) onProgress,
  ) async {
    state = state.asLoading();
    try {
      final (:progress, :result) = _repository.fetchAgentApplicationsWithSse();

      // Forward SSE events to caller
      progress.listen(
        onProgress,
        onError: (_) {},
        cancelOnError: false,
      );

      final applications = await result;
      state = state.asLoaded(applications);
      await RbacLocalStorage.instance.saveApplications(applications);
      if (kDebugMode) {
        print('[RBAC] Loaded ${applications.length} apps with SSE progress');
      }
      return applications;
    } catch (e) {
      state = state.asError(e.toString());
      if (kDebugMode) {
        print('[RBAC] Error loading with progress: $e');
      }
      rethrow;
    }
  }

  /// Fetch fresh applications from API in background.
  /// Updates state and cache silently without blocking UI.
  Future<void> refreshInBackground() async {
    try {
      final applications = await _repository.fetchAgentApplications();
      state = state.asLoaded(applications);
      await RbacLocalStorage.instance.saveApplications(applications);
      if (kDebugMode) {
        print('[RBAC] Background refresh: ${applications.length} applications');
      }
    } catch (e) {
      // Silent failure — cached data is still in use
      if (kDebugMode) {
        print('[RBAC] Background refresh failed (using cache): $e');
      }
    }
  }

  /// Find application by path guard flag.
  RbacApplication? findApplicationByFlag(String flag) {
    for (final app in state.applications) {
      if (app.rbacPathGuard.pathGuard == flag) return app;
    }
    return null;
  }

  /// Find menu by path guard flag (searches recursively in all apps).
  RbacMenu? findMenuByFlag(String flag) {
    for (final app in state.applications) {
      final menu = _findMenuRecursive(app.subMenus, flag);
      if (menu != null) return menu;
    }
    return null;
  }

  /// Find menu by path (searches recursively).
  RbacMenu? findMenuByPath(String path) {
    for (final app in state.applications) {
      final menu = _findMenuByPathRecursive(app.subMenus, path);
      if (menu != null) return menu;
    }
    return null;
  }

  /// Get RBAC items (actions + components) for a given path or flag.
  ({List<RbacAction> actions, List<RbacComponent> components})
      getRbacItemsByPath(String path) {
    for (final app in state.applications) {
      if (app.rbacPathGuard.path == path || app.flag == path) {
        return (actions: app.rbacActions, components: app.rbacComponents);
      }
      final menu = _findMenuByPathRecursive(app.subMenus, path);
      if (menu != null) {
        return (actions: menu.rbacActions, components: menu.rbacComponents);
      }
    }
    return (actions: <RbacAction>[], components: <RbacComponent>[]);
  }

  /// Get collection_crud_info for a given path or flag.
  List<RbacCollectionCrudItem> getCrudInfoByPath(String path) {
    for (final app in state.applications) {
      if (app.rbacPathGuard.path == path || app.flag == path) {
        if (kDebugMode) {
          print('[RBAC] getCrudInfoByPath("$path") → matched app "${app.flag}", '
              'crudInfo count: ${app.collectionCrudInfo.length}');
        }
        return app.collectionCrudInfo;
      }
      final menu = _findMenuByPathRecursive(app.subMenus, path);
      if (menu != null) {
        if (kDebugMode) {
          print('[RBAC] getCrudInfoByPath("$path") → matched menu "${menu.flag}", '
              'crudInfo count: ${menu.collectionCrudInfo.length}');
        }
        return menu.collectionCrudInfo;
      }
    }
    if (kDebugMode) {
      print('[RBAC] ⚠️ getCrudInfoByPath("$path") → NO MATCH in '
          '${state.applications.length} applications');
    }
    return [];
  }

  /// Check if a path or flag exists in the loaded applications.
  bool checkPathExists(String path) {
    for (final app in state.applications) {
      if (app.rbacPathGuard.path == path || app.flag == path) return true;
      if (_findMenuByPathRecursive(app.subMenus, path) != null) return true;
    }
    return false;
  }

  /// Check whether a given sub_menu `flag` exists anywhere in the loaded
  /// applications' nested sub_menus tree. Matches the existing convention in
  /// BloodBankHomePage: searches the `flag` field (NOT `rbacPathGuard.pathGuard`,
  /// which is a different field). Returns `true` if the flag is found at any
  /// depth in any application's sub_menus, or if it matches a top-level app
  /// flag directly.
  bool hasMenuFlag(String flag) {
    for (final app in state.applications) {
      if (app.flag == flag) return true;
      if (_findFlagRecursive(app.subMenus, flag)) return true;
    }
    return false;
  }

  /// Return `true` if the user has access to ANY of the given flags.
  /// Useful for pages that are shared across multiple profiles — e.g.
  /// `HealthStructureNetworkPage` opens for both blood_bank users (via
  /// `flutter_apps_eblood_bank_bb_home_network`) AND hospital users
  /// (via `flutter_apps_eblood_bank_hosp_home_network`). Callers pass
  /// both flags and the page unlocks if either grants access.
  bool hasAnyMenuFlag(List<String> flags) =>
      flags.any((f) => hasMenuFlag(f));

  bool _findFlagRecursive(List<RbacMenu> menus, String flag) {
    for (final menu in menus) {
      if (menu.flag == flag) return true;
      if (menu.subMenus.isNotEmpty && _findFlagRecursive(menu.subMenus, flag)) {
        return true;
      }
    }
    return false;
  }

  /// Reset state (e.g., on logout).
  void reset() {
    state = const RbacState();
  }

  @override
  void dispose() {
    if (_activeInstance == this) _activeInstance = null;
    super.dispose();
  }

  // ── Private helpers ──

  RbacMenu? _findMenuRecursive(List<RbacMenu> menus, String flag) {
    for (final menu in menus) {
      if (menu.rbacPathGuard.pathGuard == flag) return menu;
      if (menu.subMenus.isNotEmpty) {
        final found = _findMenuRecursive(menu.subMenus, flag);
        if (found != null) return found;
      }
    }
    return null;
  }

  RbacMenu? _findMenuByPathRecursive(List<RbacMenu> menus, String path) {
    for (final menu in menus) {
      if (menu.rbacPathGuard.path == path || menu.flag == path) return menu;
      if (menu.subMenus.isNotEmpty) {
        final found = _findMenuByPathRecursive(menu.subMenus, path);
        if (found != null) return found;
      }
    }
    return null;
  }
}
