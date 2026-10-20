import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../apps/config/AppConfig.dart';
import '../../business/interactors/DeliveryController.dart';
import '../../business/interactors/delivery_tracking_provider.dart';
import '../../business/model/DeliveryModels.dart' show LocationInfo;
import '../../business/model/delivery_tracking.dart';
import '../../business/service/courier_presence_service.dart';
import '../widgets/slide_to_confirm.dart';
import 'confirm_reception_dialog.dart';
import 'courier_step.dart';
import 'delivery_map_view.dart';

enum DeliverySheetRole { courier, buyer, seller }

const _red = Color(0xFFD0021B);
const _blue = Color(0xFF1A73E8);
const _green = Color(0xFF1E8E3E);

const _beforePickup = {'awaiting_assignment', 'awaiting_acceptance', 'en_route_to_blood_bank', 'at_blood_bank'};
const _codePhases = {'picked_up_from_blood_bank', 'en_route_to_hospital', 'at_hospital'};

/// Filled segments of the 4-step bar (bank · picked up · hospital · delivered).
const _progress = {
  'en_route_to_blood_bank': 1,
  'at_blood_bank': 1,
  'picked_up_from_blood_bank': 2,
  'en_route_to_hospital': 3,
  'at_hospital': 3,
  'delivered_and_confirmed': 4,
};

bool _noCourier(DeliveryTracking t) =>
    t.courierName == null || t.phase == 'awaiting_assignment' || t.phase == 'awaiting_acceptance';

String _supportPhone() {
  try {
    return AppConfig.instance.getEnvValue('SUPPORT_PHONE').trim();
  } catch (_) {
    return ''; // dotenv not loaded (tests)
  }
}

/// Tries each URL in turn; `canLaunchUrl` is skipped because the manifest does
/// not declare the `google.navigation` scheme.
Future<void> _launch(List<String> urls) async {
  for (final url in urls) {
    try {
      if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // No handler: try the next one.
    }
  }
}

/// The live delivery sheet: map, ETA, progress, stops, and the one action the
/// [role] owns. Polls the tracking read while it is open.
class DeliverySheet extends ConsumerStatefulWidget {
  const DeliverySheet({
    super.key,
    required this.deliveryId,
    required this.role,
    this.mapBuilder,
    this.onMinimize,
    this.onClose,
    this.onEnded,
  });

  final String deliveryId;
  final DeliverySheetRole role;

  /// Defaults to [DeliveryMapView]; tests pass a placeholder (GoogleMap is a platform view).
  final Widget Function(BuildContext, DeliveryTracking)? mapBuilder;
  final VoidCallback? onMinimize;
  final VoidCallback? onClose;

  /// Fired once when the delivery ends for this viewer, with the translation
  /// key of the message to show (null = delivered, nothing to say).
  final void Function(String? messageKey)? onEnded;

  @override
  ConsumerState<DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends ConsumerState<DeliverySheet> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _ended = false;
  bool _busy = false;

  bool get _courier => widget.role == DeliverySheetRole.courier;

  @override
  void initState() {
    super.initState();
    ref.listenManual(deliveryTrackingProvider(widget.deliveryId), (_, next) {
      final t = next.valueOrNull;
      if (next.error is DeliveryTrackingClosed) {
        _end('delivery_reassigned');
      } else if (t != null && t.isCancelled) {
        _end('delivery_cancelled_by_admin');
      } else if (t != null && t.isDelivered) {
        _end(null);
      }
    }, fireImmediately: true);
  }

  void _end(String? messageKey) {
    if (_ended) return;
    _ended = true;
    // Deferred: with fireImmediately this can run inside initState, and the host will pop.
    scheduleMicrotask(() => widget.onEnded?.call(messageKey));
  }

  void _snack(String text) => _messenger.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));

  void _refresh() => ref.invalidate(deliveryTrackingProvider(widget.deliveryId));

  Future<bool> _advance(String phase) async {
    final pos = await CourierPresenceService.lastPosition();
    final res = await ref.read(deliveryApiServiceProvider).updateDeliveryPhase(
          widget.deliveryId,
          phase,
          location: pos == null ? null : LocationInfo(lat: pos['lat']!, lng: pos['lng']!, accuracy: pos['accuracy']),
        );
    if (!mounted) return res.success;
    if (!res.success) {
      _snack(res.error ?? 'error_updating_status'.tr);
      return false;
    }
    _refresh();
    return true;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(deliveryTrackingProvider(widget.deliveryId));
    final t = async.valueOrNull;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: ScaffoldMessenger(
        key: _messenger,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: false,
            child: Builder(
              builder: (context) => Column(
                children: [
                  _topBar(context, t),
                  if (t != null)
                    ..._content(context, t)
                  else
                    Expanded(
                      child: Center(
                        child: async.hasError ? Text('delivery_reassigned'.tr) : const CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, DeliveryTracking? t) {
    final support = _courier ? _supportPhone() : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (t != null)
                  Flexible(
                    flex: 3, // the phase matters more than the identifier
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFE3E5), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _pillKey(t).tr,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (t != null)
                  Flexible(
                    child: Text(t.identifier,
                        overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
              ],
            ),
          ),
          if (_courier) ...[
            OutlinedButton(
              key: const Key('sheet-minimize'),
              onPressed: widget.onMinimize,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: const StadiumBorder(),
              ),
              child: Text('sheet_minimize'.tr),
            ),
            if (support.isNotEmpty)
              PopupMenuButton<void>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (_) => [
                  PopupMenuItem(onTap: () => _launch(['tel:$support']), child: Text('contact_support'.tr)),
                ],
              )
            else
              const SizedBox(width: 8),
          ] else
            IconButton(
              key: const Key('sheet-close'),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  String _pillKey(DeliveryTracking t) {
    final toBank = _beforePickup.contains(t.phase);
    return switch (widget.role) {
      DeliverySheetRole.courier => toBank ? 'pill_to_bank' : 'pill_to_hospital',
      _ when _noCourier(t) => 'pill_waiting_courier',
      DeliverySheetRole.buyer => toBank ? 'pill_to_bank' : 'pill_to_you',
      DeliverySheetRole.seller => toBank ? 'pill_courier_coming' : 'pill_to_hospital',
    };
  }

  List<Widget> _content(BuildContext context, DeliveryTracking t) {
    final toBank = _beforePickup.contains(t.phase);
    final target = toBank ? t.bloodBank : t.hospital;
    final eta = widget.role == DeliverySheetRole.buyer ? t.etaToHospitalSeconds : t.etaSeconds;
    final leg = t.currentLeg;
    // The buyer's ETA runs to the hospital; a distance to the bank would not match it.
    final distanceM = widget.role == DeliverySheetRole.buyer && t.activeLeg != 'to_hospital' ? null : leg?.distanceM;
    final action = _action(context, t);

    return [
      SizedBox(
        height: 235,
        child: Stack(
          children: [
            Positioned.fill(child: (widget.mapBuilder ?? (_, t) => DeliveryMapView(tracking: t))(context, t)),
            if (_courier && target.lat != null && target.lng != null)
              Positioned(
                left: 10,
                bottom: 10,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _blue, visualDensity: VisualDensity.compact),
                  onPressed: () => _launch([
                    'google.navigation:q=${target.lat},${target.lng}&mode=l',
                    'https://www.google.com/maps/dir/?api=1&destination=${target.lat},${target.lng}',
                  ]),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: Text('sheet_navigate'.tr),
                ),
              ),
            if (!_courier && !_noCourier(t) && t.courierLastSeenAt != null)
              Positioned(left: 10, top: 10, child: _FreshnessBadge(t)),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(eta == null ? '—' : '${(eta / 60).ceil()} min',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                if (distanceM != null && distanceM > 0) ...[
                  const SizedBox(width: 8),
                  Text('· ${(distanceM / 1000).toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _StepBar(done: _progress[t.phase] ?? 0),
            const SizedBox(height: 14),
            if (_courier && _codePhases.contains(t.phase) && t.verificationCode != null) _codeCard(t.verificationCode!),
            ..._cards(t, toBank),
          ],
        ),
      ),
      ?action,
    ];
  }

  List<Widget> _cards(DeliveryTracking t, bool toBank) {
    String join(List<String?> parts) => parts.where((p) => p != null && p.isNotEmpty).join(' · ');
    if (_courier) {
      return toBank
          ? [
              _StopCard(icon: Icons.bloodtype, title: t.bloodBank.name, subtitle: join([t.bloodBank.address, t.bloodSummary]),
                  phone: t.bloodBank.phone, callKey: const Key('call-bank')),
              _StopCard(icon: Icons.local_hospital, title: t.hospital.name, subtitle: t.hospital.address),
            ]
          : [
              _StopCard(icon: Icons.local_hospital, title: t.hospital.name, subtitle: join([t.hospital.address, t.bloodSummary]),
                  phone: t.hospital.phone, callKey: const Key('call-hospital')),
            ];
    }
    final other = widget.role == DeliverySheetRole.buyer ? t.bloodBank.name : t.hospital.name;
    return [
      if (!_noCourier(t))
        _StopCard(icon: Icons.two_wheeler, title: t.courierName, phone: t.courierPhone, callKey: const Key('call-courier')),
      _StopCard(icon: Icons.bloodtype, title: join([t.bloodSummary, other]), outlined: true),
    ];
  }

  Widget _codeCard(String code) => Container(
        key: const Key('handover-code'),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1D1D1F), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text('handover_code_label'.tr, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12)),
            const SizedBox(height: 2),
            SelectableText(code,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 6)),
          ],
        ),
      );

  Widget? _action(BuildContext context, DeliveryTracking t) {
    Widget pad(Widget child) => Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 14), child: child);
    Widget button(String key, VoidCallback? onPressed) => pad(SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red, shape: const StadiumBorder()),
            onPressed: _busy ? null : onPressed,
            child: Text(key.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ));

    switch (widget.role) {
      case DeliverySheetRole.courier:
        final step = courierStep(t);
        if (step == null) return null;
        final next = step.nextPhase;
        if (next == null) {
          return pad(Text(step.labelKey.tr,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)));
        }
        return pad(SlideToConfirm(
          key: ValueKey(t.phase),
          label: step.labelKey.tr,
          busyHint: 'slide_busy'.tr,
          onConfirmed: () => _advance(next),
        ));
      case DeliverySheetRole.buyer:
        if (t.isDelivered || t.isCancelled) return null;
        return button(
          'confirm_receipt',
          t.phase == 'at_hospital'
              ? () => _run(() => confirmReception(context, ref, deliveryId: widget.deliveryId, bloodRequestId: t.bloodRequestId))
              : null,
        );
      case DeliverySheetRole.seller:
        if (t.pickupConfirmedAt != null || !_beforePickup.contains(t.phase)) return null;
        return button(
          'confirm_handover',
          t.phase == 'at_blood_bank'
              ? () => _run(() async {
                    final error = await ref.read(outgoingDeliveriesProvider.notifier).confirmPickup(widget.deliveryId);
                    if (error != null) _snack(error);
                  })
              : null,
        );
    }
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) => Semantics(
        value: '$done / 4',
        child: Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < done ? _red : const Color(0xFFE4E4E8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.icon, required this.title, this.subtitle, this.phone, this.callKey, this.outlined = false});

  final IconData icon;
  final String? title, subtitle, phone;
  final Key? callKey;

  /// The cargo line: lighter, no icon tile.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: outlined ? const Color(0xFFDDDDDD) : const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xFFFFE3E5), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _red, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? '—',
                    style: TextStyle(fontSize: outlined ? 13 : 15, fontWeight: outlined ? FontWeight.w500 : FontWeight.w700)),
                if (sub != null && sub.isNotEmpty)
                  Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (phone != null && phone!.isNotEmpty)
            IconButton(
              key: callKey,
              tooltip: 'call'.tr,
              onPressed: () => _launch(['tel:$phone']),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFFE7F6EA), foregroundColor: _green),
              icon: const Icon(Icons.call, size: 20),
            ),
        ],
      ),
    );
  }
}

/// « en direct · il y a 8 s », or the stale warning; ticks on its own so a
/// silent poll never leaves a frozen "live" label.
class _FreshnessBadge extends StatefulWidget {
  const _FreshnessBadge(this.tracking);

  final DeliveryTracking tracking;

  @override
  State<_FreshnessBadge> createState() => _FreshnessBadgeState();
}

class _FreshnessBadgeState extends State<_FreshnessBadge> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final age = widget.tracking.positionAge(now) ?? Duration.zero;
    final stale = widget.tracking.isStale(now);
    final color = stale ? const Color(0xFFB06000) : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!stale) ...[
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Text(
            stale
                ? 'position_stale_minutes'.trParams({'m': '${age.inMinutes}'})
                : 'live_seconds_ago'.trParams({'s': '${math.max(0, age.inSeconds)}'}),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
