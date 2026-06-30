import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../providers/rbac_provider.dart';

/// Schedule a post-frame RBAC entry check for a page.
///
/// If the user does not have the given [flag] in the loaded RBAC applications
/// tree, the current route is popped and an access-denied snackbar is shown.
///
/// Call from `initState` AFTER `super.initState()`:
///
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   guardPageEntry(ref, context, 'flutter_apps_eblood_bank_bb_inventory_stock_add');
///   // ... other init logic ...
/// }
/// ```
void guardPageEntry(WidgetRef ref, BuildContext context, String flag) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final hasAccess =
        ref.read(rbacProvider.notifier).hasMenuFlag(flag);
    if (!hasAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('access_denied'.tr)),
      );
      Navigator.of(context).maybePop();
    }
  });
}

/// Same as [guardPageEntry] but accepts a pool of flags. Access is granted
/// when ANY of the supplied flags is present in the RBAC tree.
///
/// Use this on pages reachable from multiple profiles (blood_bank + cnts,
/// blood_bank + hospital, etc.) so a user with any one of the matching
/// sub_menu flags can enter the page.
void guardPageEntryAny(
    WidgetRef ref, BuildContext context, List<String> flags) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final hasAccess =
        ref.read(rbacProvider.notifier).hasAnyMenuFlag(flags);
    if (!hasAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('access_denied'.tr)),
      );
      Navigator.of(context).maybePop();
    }
  });
}
