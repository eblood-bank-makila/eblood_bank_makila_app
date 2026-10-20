import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../business/service/courier_duty_service.dart';

/// « En service / Hors service » for the courier's dashboard header; a refusal
/// (delivery in progress, no location) shows why in a SnackBar.
class DutySwitch extends StatelessWidget {
  DutySwitch({super.key, CourierDutyService? duty}) : duty = duty ?? CourierDutyService.instance;

  final CourierDutyService duty;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: duty,
      builder: (context, _) => MergeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              key: const Key('duty-switch'),
              value: duty.onDuty,
              onChanged: (value) async {
                final refusal = await duty.setOnDuty(value);
                if (refusal == null || !context.mounted) return;
                ScaffoldMessenger.maybeOf(context)
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(refusal.tr), behavior: SnackBarBehavior.floating));
              },
            ),
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
