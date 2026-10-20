import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/services/location_access.dart';
import '../../../core/services/session_identity.dart';
import '../../../main.dart' show navigatorKey;
import '../../business/model/delivery_tracking.dart';
import '../../business/service/courier_duty_service.dart';
import 'delivery_sheet.dart';

/// What is on screen for one delivery sheet.
class _Open {
  _Open(this.id, this.role);

  final String id;
  final DeliverySheetRole role;

  /// Known once the sheet's first frame is built.
  ModalRoute<void>? route;
}

/// Owns the delivery sheet that is on screen and the courier's minimized state:
/// the courier's sheet cannot be dismissed (« Réduire » or back shrinks it to
/// the bar that [ActiveDeliveryBar] draws), followers' sheets close like any
/// other. A courier delivery becoming current puts the courier on duty.
class ActiveDeliverySheetController extends ChangeNotifier {
  static final instance = ActiveDeliverySheetController();

  String? _courierId;
  bool _minimized = false;
  _Open? _open;

  /// The delivery whose end message was last shown: the sheet and the bar can both report the same end.
  String? _endedId;
  SessionIdentity? _session;

  /// The courier's delivery in progress, while there is one.
  String? get courierDeliveryId => _courierId;
  bool get minimized => _minimized;

  /// The courier's sheet is shrunk: the bar stands in for it.
  bool get showBar => _courierId != null && _minimized;

  /// Why the courier could not go on duty for the current delivery (a
  /// translation key), else null: off duty, none of its positions go out.
  final dutyRefusal = ValueNotifier<String?>(null);
  int _dutyCalls = 0;

  /// Puts the courier on duty (a no-op when already on); returns the refusal key.
  @visibleForTesting
  Future<String?> Function() goOnDuty = () => CourierDutyService.instance.setOnDuty(true);

  /// Tests pass a placeholder (the default map is a platform view).
  @visibleForTesting
  Widget Function(BuildContext, DeliveryTracking)? mapBuilder;

  /// Opens the sheet for [role]; a no-op if that same sheet is already up.
  Future<void> open(NavigatorState navigator, String deliveryId, DeliverySheetRole role) async {
    final shown = _open;
    if (shown != null && shown.id == deliveryId && shown.role == role) return;
    _watchSession();
    if (_endedId == deliveryId) _endedId = null;
    // One sheet at a time. The courier's must stay reachable, so it shrinks to the bar.
    if (shown != null) shown.role == DeliverySheetRole.courier ? minimize() : _popSheet();

    final courier = role == DeliverySheetRole.courier;
    if (courier) {
      _courierId = deliveryId;
      _minimized = false;
      notifyListeners();
      unawaited(_ensureOnDuty());
    }
    final sheet = _open = _Open(deliveryId, role);
    await showModalBottomSheet<void>(
      context: navigator.context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: !courier,
      enableDrag: !courier,
      backgroundColor: Colors.transparent,
      builder: (context) {
        sheet.route ??= ModalRoute.of<void>(context);
        final content = FractionallySizedBox(
          heightFactor: 0.9,
          child: DeliverySheet(
            deliveryId: deliveryId,
            role: role,
            mapBuilder: mapBuilder,
            onMinimize: minimize,
            onClose: _popSheet,
            // Shown on the app's messenger: it outlives the sheet this closes.
            onEnded: (key) => closeFor(deliveryId, message: key?.tr),
            dutyRefusal: courier ? dutyRefusal : null,
            onDutyAction: () => unawaited(_retryDuty()),
          ),
        );
        // Back shrinks the courier's sheet to the bar; it is never dismissed.
        return courier
            ? PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) minimize();
                },
                child: content,
              )
            : content;
      },
    );
    if (identical(_open, sheet)) {
      // Dragged, tapped away or popped by someone else, not by this controller.
      _open = null;
      if (courier && _courierId == deliveryId) {
        _minimized = true; // the delivery goes on: the bar is the way back
        notifyListeners();
      }
    }
  }

  /// A delivery in progress that no sheet shows (after a restart, or loaded
  /// by the courier's home page) becomes current as the bar, without opening
  /// the sheet, so its positions go out. A current delivery is left alone.
  void adopt(String deliveryId) {
    if (_courierId != null || deliveryId.isEmpty) return;
    _watchSession();
    _courierId = deliveryId;
    _minimized = true;
    notifyListeners();
    unawaited(_ensureOnDuty());
  }

  /// The duty stream is the only sender of a delivery's positions: an off-duty
  /// courier goes on duty, or the courier's sheet says why not.
  Future<void> _ensureOnDuty() async {
    final call = ++_dutyCalls;
    String? refusal;
    try {
      refusal = await goOnDuty();
    } catch (e) {
      debugPrint('[delivery] going on duty: $e');
      refusal = 'duty_server_error';
    }
    if (call != _dutyCalls) return; // a later attempt's answer wins
    if (_courierId != null) dutyRefusal.value = refusal; // the delivery may have ended meanwhile
  }

  /// The warning's action: try again; if location is still what is missing,
  /// open the location switch or the app's settings (the permission prompt
  /// already ran in setOnDuty, so a fresh refusal is left alone).
  Future<void> _retryDuty() async {
    await _ensureOnDuty();
    if (dutyRefusal.value != 'duty_location_needed') return;
    final access = LocationAccess();
    if (await access.status() != LocationAccessStatus.denied) await access.fix();
  }

  /// Shrinks the courier's sheet to the bar; the delivery stays current.
  void minimize() {
    if (_courierId == null) return;
    if (_open?.role == DeliverySheetRole.courier) _popSheet();
    _minimized = true;
    notifyListeners();
  }

  /// The delivery [deliveryId] is over for this user: closes its sheet and the
  /// bar, and shows [message] (already translated) in the app.
  void closeFor(String deliveryId, {String? message}) {
    if (_open?.id == deliveryId) _popSheet();
    if (_courierId == deliveryId) {
      _courierId = null;
      _minimized = false;
      dutyRefusal.value = null;
    }
    notifyListeners();
    if (message != null) {
      if (_endedId != deliveryId) _snack(message);
      _endedId = deliveryId;
    }
  }

  /// Another user signing in, or a logout, is another session, to which this
  /// one's sheet and bar do not belong (they would poll without its token, or
  /// with the next user's). A same-user profile refresh keeps them.
  void _watchSession() {
    if (_session != null) return;
    final session = _session = SessionIdentity();
    GetStorage().listenKey('user_profiles', (_) {
      if (!session.changed()) return;
      _popSheet();
      _courierId = null;
      _minimized = false;
      _endedId = null;
      dutyRefusal.value = null;
      notifyListeners();
    });
  }

  void _popSheet() {
    final route = _open?.route;
    if (route == null) return; // first frame not built yet: the sheet reports its own end
    _open = null;
    // A menu or dialog above the sheet would take a plain pop.
    if (route.isCurrent) {
      route.navigator?.pop();
    } else {
      route.navigator?.removeRoute(route);
    }
  }

  /// On the app's messenger, which outlives the sheet (the sheet has its own).
  void _snack(String text) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }
}
