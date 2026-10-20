import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../main.dart' show navigatorKey;
import '../../business/interactors/delivery_tracking_provider.dart';
import 'active_delivery_sheet_controller.dart';
import 'delivery_sheet.dart';

/// Lays [ActiveDeliveryBar] over the whole app (the router's navigator). Only the bar's own area takes touches.
Widget withActiveDeliveryBar(Widget? child) => Stack(
      fit: StackFit.expand,
      children: [child ?? const SizedBox.shrink(), const ActiveDeliveryBar()],
    );

/// The courier's minimized delivery, above the bottom navigation on every
/// screen. Tapping it brings the sheet back.
class ActiveDeliveryBar extends StatelessWidget {
  const ActiveDeliveryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ActiveDeliverySheetController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final id = controller.courierDeliveryId;
        return Positioned(
          left: 12,
          right: 12,
          // Just above the bottom navigation, which is 65 dp plus the system inset.
          bottom: 62 + MediaQuery.viewPaddingOf(context).bottom,
          child: controller.showBar && id != null ? _Bar(id) : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar(this.deliveryId);

  final String deliveryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ActiveDeliverySheetController.instance;
    final tracking = deliveryTrackingProvider(deliveryId);
    // The sheet is gone, so this is the only watcher of the delivery: it
    // keeps the ETA fresh and closes the bar when the delivery ends. It polls
    // every 10 s, which is fine while the courier is on a delivery.
    ref.listen(tracking, (_, next) {
      final end = deliveryEnd(next, DeliverySheetRole.courier);
      if (end != null) controller.closeFor(deliveryId, message: end.messageKey?.tr);
    });
    final t = ref.watch(tracking).valueOrNull;

    final eta = t?.etaSeconds;
    final stop = t == null ? null : (beforePickupPhases.contains(t.phase) ? t.bloodBank : t.hospital).name;
    const white = TextStyle(color: Colors.white);

    return Material(
      color: const Color(0xFF1D1D1F),
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('active-delivery-bar'),
        onTap: () {
          final navigator = navigatorKey.currentState;
          if (navigator != null) unawaited(controller.open(navigator, deliveryId, DeliverySheetRole.courier));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.two_wheeler, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'delivery_in_progress_bar'.trParams({
                        'eta': eta == null ? '—' : 'eta_minutes'.trParams({'m': '${(eta / 60).ceil()}'}),
                      }),
                      overflow: TextOverflow.ellipsis,
                      style: white.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    if (stop != null && stop.isNotEmpty)
                      Text(
                        'delivery_bar_subtitle'.trParams({'stop': stop}),
                        overflow: TextOverflow.ellipsis,
                        style: white.copyWith(fontSize: 12, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_up, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
