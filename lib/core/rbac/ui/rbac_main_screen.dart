import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';

import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import 'package:eblood_bank_mak_app/apps/services/AuthService.dart';
import '../providers/rbac_provider.dart';
import '../rbac_screen_registry.dart';
import '../models/rbac_models.dart';

/// Dynamic main screen that builds bottom navigation from RBAC applications.
///
/// Watches [rbacProvider] for the applications list, filters by visibility
/// and registry, sorts by orderBy, and builds NavigationBar destinations
/// dynamically using [RbacScreenRegistry].
class RbacMainScreen extends ConsumerStatefulWidget {
  const RbacMainScreen({super.key});

  @override
  ConsumerState<RbacMainScreen> createState() => _RbacMainScreenState();
}

class _RbacMainScreenState extends ConsumerState<RbacMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  /// Infer account type from the RBAC applications the backend returned.
  /// Profile-specific app flags act as reliable signals — if the user got
  /// blood_bank inventory, they are a blood bank, etc.
  /// Falls back to GetStorage profile flags / account_type if RBAC is empty.
  RbacAccountType _determineAccountType(List<RbacApplication> apps) {
    final appFlags = apps.map((a) => a.flag).toSet();

    // CNTS-specific apps
    if (appFlags.contains('flutter_apps_eblood_bank_cnts_inventory_app') ||
        appFlags.contains('flutter_apps_eblood_bank_cnts_donors_app')) {
      return RbacAccountType.cnts;
    }

    // Blood Bank-specific apps (legacy + bb_home_* flags from backend)
    if (appFlags.contains('flutter_apps_eblood_bank_blood_bank_inventory_app') ||
        appFlags.contains('flutter_apps_eblood_bank_blood_bank_requests_app') ||
        appFlags.contains('flutter_apps_eblood_bank_bb_home_inventory') ||
        appFlags.contains('flutter_apps_eblood_bank_bb_home_requests') ||
        appFlags.contains('flutter_apps_eblood_bank_bb_home_donors') ||
        appFlags.contains('flutter_apps_eblood_bank_bb_home_wallet')) {
      return RbacAccountType.bloodBank;
    }

    // Hospital-specific apps
    if (appFlags.contains('flutter_apps_eblood_bank_hospital_blood_bags_app') ||
        appFlags.contains('flutter_apps_eblood_bank_hospital_search_app')) {
      return RbacAccountType.hospital;
    }

    // Customer-specific apps
    if (appFlags.contains('flutter_apps_eblood_bank_customer_announcements_app') ||
        appFlags.contains('flutter_apps_eblood_bank_customer_network_app')) {
      return RbacAccountType.customer;
    }

    // Fallback to stored profile flags
    final storage = GetStorage();
    final dynamic storedProfiles =
        storage.read('user_profiles') ?? storage.read('user_profils');

    if (storedProfiles is List && storedProfiles.isNotEmpty) {
      final flags = storedProfiles
          .whereType<Map>()
          .map((e) => (e['profil'] ?? e['flag'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet();

      if (flags.contains('mobile_app_cnts_profil')) return RbacAccountType.cnts;
      if (flags.contains('mobile_app_blood_bank_profil')) return RbacAccountType.bloodBank;
      if (flags.contains('mobile_app_health_structure_profil')) return RbacAccountType.hospital;
    }

    // Last fallback to stored account_type
    final stored = (storage.read('account_type') as String?) ?? '';
    final lower = stored.toLowerCase().trim();
    if (lower == 'cnts') return RbacAccountType.cnts;
    if (lower == 'blood_bank' || lower == 'bloodbank') return RbacAccountType.bloodBank;
    if (lower == 'hospital' || lower == 'hopital') return RbacAccountType.hospital;

    return RbacAccountType.customer;
  }

  Future<void> _initFcm() async {
    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // FCM permission requested; push notification handling
      // is done by the platform-level background handler.
    } catch (e) {
      debugPrint('[RbacMainScreen] FCM init error: $e');
    }
  }

  List<RbacApplication> _getFilteredApps(List<RbacApplication> allApps) {
    debugPrint('[RbacMainScreen] _getFilteredApps: ${allApps.length} total apps');
    for (final app in allApps) {
      final registered = RbacScreenRegistry.isRegistered(app.flag);
      debugPrint('[RbacMainScreen]   flag=${app.flag}, isHidden=${app.isHidden}, registered=$registered');
    }
    final filtered = allApps
        .where((app) =>
            !app.isHidden &&
            RbacScreenRegistry.isRegistered(app.flag))
        .toList()
      ..sort((a, b) => a.orderBy.compareTo(b.orderBy));
    debugPrint('[RbacMainScreen] _getFilteredApps: ${filtered.length} after filter');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final rbacState = ref.watch(rbacProvider);
    debugPrint('[RbacMainScreen] build: isLoaded=${rbacState.isLoaded}, isLoading=${rbacState.isLoading}, apps=${rbacState.applications.length}, error=${rbacState.errorMessage}');
    final filteredApps = _getFilteredApps(rbacState.applications);

    // Determine account type from the actual apps the backend gave us
    final accountType = _determineAccountType(rbacState.applications);

    // Clamp index if apps changed
    if (_currentIndex >= filteredApps.length && filteredApps.isNotEmpty) {
      _currentIndex = 0;
    }

    // No apps available — show empty/no-access state
    if (filteredApps.isEmpty) {
      return _buildNoAccessScreen();
    }

    // Build screens list from registry
    final screens = filteredApps
        .map((app) => RbacScreenRegistry.getEntry(app.flag)!.screen)
        .toList();

    return RbacAccountTypeScope(
      accountType: accountType,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: _buildBottomNav(filteredApps),
      ),
    );
  }

  Widget _buildBottomNav(List<RbacApplication> apps) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.1),
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: apps.map((app) {
          final entry = RbacScreenRegistry.getEntry(app.flag)!;
          return NavigationDestination(
            icon: Icon(entry.icon, color: Colors.grey),
            selectedIcon: Icon(entry.selectedIcon, color: ColorPages.COLOR_PRINCIPAL),
            label: entry.labelKey.tr,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoAccessScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.lock,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'no_access_title'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'no_access_message'.tr,
                style: GoogleFonts.ubuntu(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService().logout();
                    if (mounted) context.go('/welcome');
                  },
                  icon: Icon(Iconsax.logout, size: 20, color: Colors.white),
                  label: Text(
                    'sign_out'.tr,
                    style: GoogleFonts.ubuntu(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
