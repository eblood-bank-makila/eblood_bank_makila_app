import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/structure_validation_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/providers/structure_validation_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/rbac_screen_registry.dart';

/// Copy for the three blocking states, shared by the banner and the gate snack.
class StructureValidationCopy {
  static String title(StructureValidationModel m) => m.isNotLinked
      ? 'structure_not_linked_title'.tr
      : m.isRejected
          ? 'structure_rejected_title'.tr
          : 'structure_pending_validation_title'.tr;

  static String body(StructureValidationModel m) => m.isNotLinked
      ? 'structure_not_linked_body'.tr
      : m.isRejected
          ? 'structure_rejected_body'.tr
          : 'structure_pending_validation_body'.tr;
}

/// eBlood validation state of the logged-in org's structure (spec 2026-09-15 §7,
/// addendum 2026-10-10). Pinned at the top of the RBAC shell for blood-bank /
/// CNTS / hospital accounts and repeated on the gated pages. Renders nothing
/// while loading, when the read fails, or once validated — it is additive and
/// never blocks the page by itself (the gate helper below does that).
class StructureValidationBanner extends ConsumerWidget {
  /// When true (the RBAC shell), the banner only shows for structure accounts
  /// as told by [RbacAccountTypeScope]; pushed pages (add stock, add donor…)
  /// are only reachable by structure staff and keep the default (false).
  final bool requireStructureAccount;
  /// The shell places the banner above an IndexedStack whose pages manage
  /// their own SafeArea: pad the status bar here, only when actually shown.
  final bool padStatusBar;
  final EdgeInsetsGeometry margin;

  const StructureValidationBanner({
    super.key,
    this.requireStructureAccount = false,
    this.padStatusBar = false,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 0),
  });

  static bool _isStructureAccount(BuildContext context) =>
      RbacAccountTypeScope.of(context) != RbacAccountType.customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requireStructureAccount && !_isStructureAccount(context)) return const SizedBox.shrink();
    final model = ref.watch(myStructureProvider).valueOrNull;
    if (model == null || model.isValidated) return const SizedBox.shrink();
    final danger = model.isRejected || model.isNotLinked;
    final bg = danger ? const Color(0xFFFDECEC) : const Color(0xFFFFF4E0);
    final fg = danger ? const Color(0xFFB42318) : const Color(0xFF9A5B00);
    final topInset = padStatusBar ? MediaQuery.paddingOf(context).top : 0.0;
    return Container(
      key: const Key('structure-validation-banner'),
      margin: margin.add(EdgeInsets.only(top: topInset)),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(danger ? Iconsax.close_circle : Iconsax.timer_1, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(StructureValidationCopy.title(model),
                          style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(999)),
                      child: Text('structure_unverified_badge'.tr,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(StructureValidationCopy.body(model), style: TextStyle(color: fg, fontSize: 13, height: 1.35)),
                if (model.isRejected && (model.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('${'structure_validation_reason'.tr} : ${model.note}',
                      style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 4),
                Text('structure_validation_contact'.tr, style: TextStyle(color: fg.withValues(alpha: .85), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Client-side mirror of the backend write gate. Call it first in every
/// Save / Order handler: when the org's structure is KNOWN to be unvalidated
/// it shows the same message the server would answer and returns true. When
/// the state is unknown (not loaded, read failed) it lets the call through —
/// the server stays authoritative and its 409 reaches the existing error path.
class StructureValidationGate {
  static bool blockIfUnverified(BuildContext context, WidgetRef ref) {
    final model = ref.read(myStructureProvider).valueOrNull;
    if (model == null || !model.blocksActions) return false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${StructureValidationCopy.title(model)}\n${StructureValidationCopy.body(model)}'),
      backgroundColor: const Color(0xFFB42318),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ));
    return true;
  }
}
