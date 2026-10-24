import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../apps/config/AppConfig.dart';
import '../../business/interactors/DeliveryController.dart';
import '../../business/interactors/delivery_tracking_provider.dart';
import '../../business/model/DeliveryModels.dart' show LocationInfo;
import '../../business/model/delivery_tracking.dart';
import '../../business/service/DeliveryApiService.dart' show ApiResponse;
import '../widgets/slide_to_confirm.dart';
import 'confirm_reception_dialog.dart';
import 'courier_step.dart';
import 'delivery_map_view.dart';

enum DeliverySheetRole { courier, buyer, seller }

const _red = Color(0xFFD0021B);
const _blue = Color(0xFF1A73E8);
const _green = Color(0xFF1E8E3E);

/// The phases where the courier is still heading to (or at) the blood bank.
const beforePickupPhases = {'awaiting_assignment', 'awaiting_acceptance', 'en_route_to_blood_bank', 'at_blood_bank'};
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

/// Labels under the bar, per role: the seller's trip starts with the courier coming to them.
const _stepLabels = {
  DeliverySheetRole.courier: ['step_bank', 'step_picked_up', 'step_hospital', 'step_delivered'],
  DeliverySheetRole.buyer: ['step_bank', 'step_picked_up', 'step_en_route', 'step_delivered'],
  DeliverySheetRole.seller: ['step_en_route', 'step_handover', 'step_hospital', 'step_delivered'],
};

/// The status pill's translation key for [role]: shared with the home cards so they say the same thing.
String pillKey(DeliverySheetRole role, String phase, {required bool noCourier}) {
  final toBank = beforePickupPhases.contains(phase);
  if (role != DeliverySheetRole.courier && noCourier) return 'pill_waiting_courier';
  if (phase == 'at_blood_bank') return 'pill_at_bank';
  if (phase == 'at_hospital') return role == DeliverySheetRole.buyer ? 'pill_courier_arrived' : 'pill_at_hospital';
  return switch (role) {
    DeliverySheetRole.courier => toBank ? 'pill_to_bank' : 'pill_to_hospital',
    DeliverySheetRole.buyer => toBank ? 'pill_to_bank' : 'pill_to_you',
    DeliverySheetRole.seller => toBank ? 'pill_courier_coming' : 'pill_to_hospital',
  };
}

bool _noCourier(DeliveryTracking t) =>
    (t.courierName ?? '').trim().isEmpty || t.phase == 'awaiting_assignment' || t.phase == 'awaiting_acceptance';

/// The position stamped on a phase change. The server stores it as the
/// courier's live position, so an old last-known fix must not go out as "now".
Future<LocationInfo?> _freshFix() async {
  LocationInfo info(Position p) => LocationInfo(lat: p.latitude, lng: p.longitude, accuracy: p.accuracy);
  try {
    return info(await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 3)),
    ));
  } catch (_) {
    // No fix in time, or location off / denied: try the cached one.
  }
  try {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null && DateTime.now().difference(last.timestamp) <= const Duration(minutes: 2)) return info(last);
  } catch (_) {
    // Same: the step goes out without a position.
  }
  return null;
}

/// « 3,2 » in French, « 3.2 » in English.
String _km(int meters) {
  try {
    return NumberFormat('0.0', Get.locale?.toString()).format(meters / 1000);
  } catch (_) {
    return (meters / 1000).toStringAsFixed(1); // locale unknown to intl
  }
}

String _clock(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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

/// Whether a tracking update ends the delivery for a [role] viewer: null while
/// it runs, else the translation key of the message to show (null = nothing to
/// say). Shared by the sheet and the minimized bar.
({String? messageKey})? deliveryEnd(AsyncValue<DeliveryTracking> update, DeliverySheetRole role) {
  final t = update.valueOrNull;
  // Lost access: « réassignée » is the courier's story; a follower just stops seeing it.
  if (update.error is DeliveryTrackingClosed) {
    return (messageKey: role == DeliverySheetRole.courier ? 'delivery_reassigned' : null);
  }
  if (t != null && t.isCancelled) return (messageKey: 'delivery_cancelled_by_admin');
  if (t != null && t.isDelivered) {
    return (
      messageKey: switch (role) {
        DeliverySheetRole.courier => 'delivery_finished',
        DeliverySheetRole.buyer => 'delivery_confirmed',
        DeliverySheetRole.seller => null,
      }
    );
  }
  return null;
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
    this.dutyRefusal,
    this.onDutyAction,
  });

  final String deliveryId;
  final DeliverySheetRole role;

  /// Defaults to [DeliveryMapView]; tests pass a placeholder (GoogleMap is a platform view).
  final Widget Function(BuildContext, DeliveryTracking)? mapBuilder;
  final VoidCallback? onMinimize;
  final VoidCallback? onClose;

  /// Fired once when the delivery ends for this viewer, with the translation
  /// key of the message to show (null = nothing to say).
  final void Function(String? messageKey)? onEnded;

  /// The courier is off duty for this reason (a translation key): a warning
  /// with [onDutyAction] tops the sheet while it is non-null.
  final ValueListenable<String?>? dutyRefusal;
  final VoidCallback? onDutyAction;

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
      final end = deliveryEnd(next, widget.role);
      if (end != null) _end(end.messageKey);
    }, fireImmediately: true);
  }

  void _end(String? messageKey) {
    if (_ended) return;
    _ended = true;
    // Deferred: with fireImmediately this can run inside initState, and the host will pop.
    scheduleMicrotask(() => widget.onEnded?.call(messageKey));
  }

  void _snack(String text, {bool ok = false}) => _messenger.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: ok ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));

  void _refresh() => ref.invalidate(deliveryTrackingProvider(widget.deliveryId));

  Future<bool> _advance(String phase) async {
    // Read before any await: the sheet may be closed by then.
    final api = ref.read(deliveryApiServiceProvider);
    final id = widget.deliveryId;
    final location = await _freshFix();
    final res = await api
        .updateDeliveryPhase(id, phase, location: location)
        // http.put has no timeout of its own; a dead socket must not lock the slide.
        .timeout(const Duration(seconds: 15), onTimeout: () => ApiResponse.error('timeout'));
    if (!mounted) return res.success;
    if (!res.success) {
      // No status = network error or timeout: never show the raw exception text.
      _snack(res.statusCode == null ? 'error_updating_status'.tr : res.error ?? 'error_updating_status'.tr);
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
                  if (widget.dutyRefusal != null)
                    ValueListenableBuilder<String?>(
                      valueListenable: widget.dutyRefusal!,
                      builder: (context, refusal, _) => refusal == null ? const SizedBox.shrink() : _dutyBanner(refusal),
                    ),
                  if (t != null)
                    ..._content(context, t)
                  else
                    Expanded(
                      child: Center(
                        child: !async.hasError
                            ? const CircularProgressIndicator()
                            : (_courier ? Text('delivery_reassigned'.tr) : null),
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

  Widget _dutyBanner(String refusal) => Container(
        key: const Key('duty-banner'),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: Color(0xFFB06000), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('duty_needed_for_delivery'.tr, style: const TextStyle(fontSize: 13, color: Color(0xFF7A4300))),
            ),
            TextButton(
              onPressed: widget.onDutyAction,
              child: Text((refusal == 'duty_location_needed' ? 'open_settings' : 'retry').tr),
            ),
          ],
        ),
      );

  String _pillKey(DeliveryTracking t) => pillKey(widget.role, t.phase, noCourier: _noCourier(t));

  List<Widget> _content(BuildContext context, DeliveryTracking t) {
    final toBank = beforePickupPhases.contains(t.phase);
    final target = toBank ? t.bloodBank : t.hospital;
    final eta = widget.role == DeliverySheetRole.buyer ? t.etaToHospitalSeconds : t.etaSeconds;
    final legM = t.currentLeg?.distanceM ?? 0;
    // Courier: how far to the stop. Followers: when the courier gets there.
    final etaDetail = _courier
        ? (legM > 0 ? (toBank ? 'eta_km_to_bank' : 'eta_km_to_hospital').trParams({'km': _km(legM)}) : null)
        : (eta != null ? 'eta_arrival_at'.trParams({'time': _clock(DateTime.now().add(Duration(seconds: eta)))}) : null);
    final action = _action(context, t);

    return [
      Expanded(
        // One scroll for the whole sheet: the map takes 75% of its height, the ETA, steps and cards follow it.
        child: LayoutBuilder(builder: (context, box) => ListView(
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            SizedBox(
              height: box.maxHeight * 0.75,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(eta == null ? '—' : 'eta_minutes'.trParams({'m': '${(eta / 60).ceil()}'}),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                      if (etaDetail != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(etaDetail,
                              overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StepBar(done: _progress[t.phase] ?? 0, labels: [for (final k in _stepLabels[widget.role]!) k.tr]),
                  const SizedBox(height: 14),
                  if (_courier && _codePhases.contains(t.phase) && t.verificationCode != null) _codeCard(t.verificationCode!),
                  ..._cards(t, toBank),
                ],
              ),
            ),
          ],
        )),
      ),
      ?action,
    ];
  }

  List<Widget> _cards(DeliveryTracking t, bool toBank) {
    String join(List<String?> parts) => parts.where((p) => p != null && p.isNotEmpty).join(' · ');
    if (_courier) {
      return toBank
          ? [
              _StopCard(look: bankLook, title: t.bloodBank.name, subtitle: join([t.bloodBank.address, t.bloodSummary]),
                  phone: t.bloodBank.phone, callKey: const Key('call-bank')),
              _StopCard(look: hospitalLook, title: t.hospital.name, subtitle: t.hospital.address),
            ]
          : [
              _StopCard(look: hospitalLook, title: t.hospital.name, subtitle: join([t.hospital.address, t.bloodSummary]),
                  phone: t.hospital.phone, callKey: const Key('call-hospital')),
            ];
    }
    final cargo = t.bloodSummary.isEmpty ? '—' : t.bloodSummary;
    return [
      if (!_noCourier(t))
        _StopCard(
          look: courierLook,
          title: t.courierName,
          subtitle: 'courier_on_moto'.tr,
          phone: t.courierPhone,
          callKey: const Key('call-courier'),
        ),
      _CargoCard(widget.role == DeliverySheetRole.buyer
          ? 'cargo_from'.trParams({'cargo': cargo, 'place': t.bloodBank.name ?? '—'})
          : 'cargo_prepare_for'.trParams({'cargo': cargo, 'place': t.hospital.name ?? '—'})),
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
        if (t.pickupConfirmedAt != null || !beforePickupPhases.contains(t.phase)) return null;
        return button(
          'confirm_handover',
          t.phase == 'at_blood_bank' ? () => _run(() => _confirmHandover(context, t)) : null,
        );
    }
  }

  /// Same confirmation as the outgoing-delivery card.
  Future<void> _confirmHandover(BuildContext context, DeliveryTracking t) async {
    final outgoing = ref.read(outgoingDeliveriesProvider.notifier);
    final id = widget.deliveryId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_handover'.tr),
        content: Text('confirm_handover_message'.trParams({'name': t.courierName ?? ''}).replaceAll('  ', ' ')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await outgoing.confirmPickup(id);
    if (!mounted) return;
    _snack(error ?? 'handover_confirmed'.tr, ok: error == null);
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.done, required this.labels});

  final int done;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => Semantics(
        label: labels.join(', '),
        value: done > 0 ? '${labels[done - 1]} ($done / 4)' : '0 / 4',
        child: ExcludeSemantics(
          child: Column(
            children: [
              Row(
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
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final l in labels)
                    Expanded(
                      child: Text(l,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.look, required this.title, this.subtitle, this.phone, this.callKey});

  /// The same icon and colour as the place's map marker.
  final StopLook look;
  final String? title, subtitle, phone;
  final Key? callKey;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: look.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(look.icon, color: look.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

/// The cargo line of the followers' sheet: dashed outline, no icon tile.
class _CargoCard extends StatelessWidget {
  const _CargoCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CustomPaint(
          painter: const _DashedBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          ),
        ),
      );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..style = PaintingStyle.stroke;
    final outline = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)));
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 5, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => false;
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
