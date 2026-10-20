import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/location_access.dart';
import '../../business/service/courier_duty_service.dart';

/// « En service / Hors service » for the courier's dashboard header. Disabled
/// while a change is on its way; a refusal shows why in a SnackBar, with a way
/// to the settings when location is what is missing. On duty with the phone's
/// location off, the label says so, subscribes the position stream anew and opens the settings.
class DutySwitch extends StatefulWidget {
  DutySwitch({super.key, CourierDutyService? duty, Future<void> Function()? fixLocation})
      : duty = duty ?? CourierDutyService.instance,
        fixLocation = fixLocation ?? _fixLocation;

  final CourierDutyService duty;

  /// The location switch, the permission prompt or the app's settings, whichever is missing.
  final Future<void> Function() fixLocation;

  static Future<void> _fixLocation() => LocationAccess().fix();

  @override
  State<DutySwitch> createState() => _DutySwitchState();
}

class _DutySwitchState extends State<DutySwitch> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    String? refusal;
    try {
      refusal = await widget.duty.setOnDuty(value);
    } catch (e) {
      debugPrint('[duty] switch: $e');
      refusal = 'duty_server_error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || refusal == null) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(refusal.tr),
        behavior: SnackBarBehavior.floating,
        action: refusal == 'duty_location_needed'
            ? SnackBarAction(label: 'open_settings'.tr, onPressed: () => widget.fixLocation())
            : null,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final duty = widget.duty;
    return ListenableBuilder(
      listenable: duty,
      builder: (context, _) => MergeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              key: const Key('duty-switch'),
              value: duty.onDuty,
              onChanged: _busy ? null : _toggle,
            ),
            if (duty.onDuty && duty.locationProblem)
              TextButton(
                key: const Key('duty-location-off'),
                onPressed: () {
                  // Location may be back already (quick settings): the stream is dead until resubscribed.
                  unawaited(duty.retryLocation());
                  unawaited(widget.fixLocation());
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800, visualDensity: VisualDensity.compact),
                child: Text('duty_location_off'.tr),
              )
            else
              Text(
                (duty.onDuty ? 'duty_on' : 'duty_off').tr,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
      ),
    );
  }
}
