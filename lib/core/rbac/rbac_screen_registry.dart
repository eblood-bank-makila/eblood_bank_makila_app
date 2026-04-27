import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// Hospital screens
import 'package:eblood_bank_mak_app/apps/home/hospital_home_page.dart';
import 'package:eblood_bank_mak_app/stock_management/ui/pages/banque/BanquePage.dart';
import 'package:eblood_bank_mak_app/stock_management/ui/pages/recherchePoche/RecherchePochePage.dart';

// Blood bank screens
import 'package:eblood_bank_mak_app/blood_bank/ui/pages/BloodBankHomePage.dart';
import 'package:eblood_bank_mak_app/blood_bank/ui/pages/BloodBankInventoryPage.dart';
import 'package:eblood_bank_mak_app/blood_bank/ui/pages/BloodBankRequestsPage.dart';
import 'package:eblood_bank_mak_app/blood_bank/ui/pages/WalletManagementPage.dart';

// Customer screens
import 'package:eblood_bank_mak_app/apps/home/customer_home_page.dart';
import 'package:eblood_bank_mak_app/apps/connect/announcements/announcements_screen.dart';
import 'package:eblood_bank_mak_app/blood_bank/ui/pages/HealthStructureNetworkPage.dart';

// CNTS screens (reuses blood bank screens)
import 'package:eblood_bank_mak_app/blood_bank/ui/pages/BloodDonorsManagementPage.dart';

// Common screens
import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/profil/ProfilePage.dart';

/// Maps backend app flags to Flutter screens and icons.
/// When a new bottom-nav feature is added, register it here.
///
/// Backend flags come from:
/// eblood_apps_api/.../eblood_bank_flutter_app/apps/eblood_bank_flutter_app.py
class RbacScreenRegistry {
  static final _registry = <String, RbacScreenEntry>{
    // ─── COMMON (all profiles) ───────────────────────
    'flutter_apps_eblood_bank_home_app': RbacScreenEntry(
      screenBuilder: () => const _HomeScreenRouter(),
      icon: Iconsax.home,
      selectedIcon: Iconsax.home_15,
      labelKey: 'home',
    ),
    'flutter_apps_eblood_bank_profile_app': RbacScreenEntry(
      screenBuilder: () => ProfilePage(),
      icon: Iconsax.profile_circle,
      selectedIcon: Iconsax.profile_circle5,
      labelKey: 'profile',
    ),

    // ─── HOSPITAL ────────────────────────────────────
    'flutter_apps_eblood_bank_hospital_blood_bags_app': RbacScreenEntry(
      screenBuilder: () => Banquepage(),
      icon: Iconsax.box,
      selectedIcon: Iconsax.box_15,
      labelKey: 'blood_bags',
    ),
    'flutter_apps_eblood_bank_hospital_search_app': RbacScreenEntry(
      screenBuilder: () => const Recherchepage(query: ''),
      icon: Iconsax.search_normal,
      selectedIcon: Iconsax.search_normal_15,
      labelKey: 'search',
    ),

    // ─── BLOOD BANK ──────────────────────────────────
    'flutter_apps_eblood_bank_blood_bank_inventory_app': RbacScreenEntry(
      screenBuilder: () => const BloodBankInventoryPage(),
      icon: Iconsax.box,
      selectedIcon: Iconsax.box_15,
      labelKey: 'inventory',
    ),
    'flutter_apps_eblood_bank_blood_bank_requests_app': RbacScreenEntry(
      screenBuilder: () => const BloodBankRequestsPage(),
      icon: Iconsax.document_text,
      selectedIcon: Iconsax.document_text_15,
      labelKey: 'requests',
    ),

    // ─── BLOOD BANK (bb_home_* flags from backend) ──
    'flutter_apps_eblood_bank_bb_home_inventory': RbacScreenEntry(
      screenBuilder: () => const BloodBankInventoryPage(),
      icon: Iconsax.box,
      selectedIcon: Iconsax.box_15,
      labelKey: 'inventory',
    ),
    'flutter_apps_eblood_bank_bb_home_requests': RbacScreenEntry(
      screenBuilder: () => const BloodBankRequestsPage(),
      icon: Iconsax.document_text,
      selectedIcon: Iconsax.document_text_15,
      labelKey: 'requests',
    ),
    'flutter_apps_eblood_bank_bb_home_wallet': RbacScreenEntry(
      screenBuilder: () => const WalletManagementPage(),
      icon: Iconsax.wallet,
      selectedIcon: Iconsax.wallet_15,
      labelKey: 'wallet',
    ),
    'flutter_apps_eblood_bank_bb_home_donors': RbacScreenEntry(
      screenBuilder: () => const BloodDonorsManagementPage(),
      icon: Iconsax.people,
      selectedIcon: Iconsax.people,
      labelKey: 'donors',
    ),
    'flutter_apps_eblood_bank_bb_home_announcements': RbacScreenEntry(
      screenBuilder: () => const AnnouncementsScreen(showBackButton: false),
      icon: Iconsax.notification,
      selectedIcon: Iconsax.notification_bing,
      labelKey: 'announcements',
    ),
    'flutter_apps_eblood_bank_bb_home_network': RbacScreenEntry(
      screenBuilder: () => const HealthStructureNetworkPage(showBackButton: false),
      icon: Iconsax.location,
      selectedIcon: Iconsax.location_add,
      labelKey: 'network',
    ),

    // ─── CUSTOMER ────────────────────────────────────
    'flutter_apps_eblood_bank_customer_announcements_app': RbacScreenEntry(
      screenBuilder: () => const AnnouncementsScreen(showBackButton: false),
      icon: Iconsax.notification,
      selectedIcon: Iconsax.notification_bing,
      labelKey: 'announcements',
    ),
    'flutter_apps_eblood_bank_customer_network_app': RbacScreenEntry(
      screenBuilder: () => const HealthStructureNetworkPage(showBackButton: false),
      icon: Iconsax.location,
      selectedIcon: Iconsax.location_add,
      labelKey: 'network',
    ),

    // ─── CNTS (reuses blood bank screens) ────────────
    'flutter_apps_eblood_bank_cnts_inventory_app': RbacScreenEntry(
      screenBuilder: () => const BloodBankInventoryPage(),
      icon: Iconsax.box,
      selectedIcon: Iconsax.box_15,
      labelKey: 'inventory',
    ),
    'flutter_apps_eblood_bank_cnts_donors_app': RbacScreenEntry(
      screenBuilder: () => const BloodDonorsManagementPage(),
      icon: Iconsax.people,
      selectedIcon: Iconsax.people,
      labelKey: 'donors',
    ),
  };

  /// Get the screen entry for a given app flag. Returns null if unknown.
  static RbacScreenEntry? getEntry(String flag) => _registry[flag];

  /// Check if a flag is registered.
  static bool isRegistered(String flag) => _registry.containsKey(flag);
}

class RbacScreenEntry {
  final Widget Function() screenBuilder;
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;

  const RbacScreenEntry({
    required this.screenBuilder,
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });

  Widget get screen => screenBuilder();
}

/// Routes the "Home" tab to the correct home page based on account type.
/// This allows a single flag (flutter_apps_eblood_bank_home_app) to serve
/// different home screens for hospital, blood bank, and customer profiles.
class _HomeScreenRouter extends StatelessWidget {
  const _HomeScreenRouter();

  @override
  Widget build(BuildContext context) {
    // The RbacMainScreen determines account type and passes it down.
    // This widget uses the inherited account type to pick the right home page.
    final accountType = RbacAccountTypeScope.of(context);

    switch (accountType) {
      case RbacAccountType.hospital:
        return const HospitalHomePage();
      case RbacAccountType.bloodBank:
        return const BloodBankHomePage();
      case RbacAccountType.cnts:
        return const BloodBankHomePage(); // CNTS reuses blood bank home
      case RbacAccountType.customer:
        return const CustomerHomePage();
    }
  }
}

/// Account type enum used by the RBAC system.
enum RbacAccountType {
  hospital,
  bloodBank,
  cnts,
  customer,
}

/// InheritedWidget that provides the account type to descendants.
class RbacAccountTypeScope extends InheritedWidget {
  final RbacAccountType accountType;

  const RbacAccountTypeScope({
    super.key,
    required this.accountType,
    required super.child,
  });

  static RbacAccountType of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RbacAccountTypeScope>();
    return scope?.accountType ?? RbacAccountType.customer;
  }

  @override
  bool updateShouldNotify(RbacAccountTypeScope oldWidget) =>
      accountType != oldWidget.accountType;
}
