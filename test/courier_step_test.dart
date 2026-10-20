import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/delivery/business/model/delivery_tracking.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/courier_step.dart';

DeliveryTracking _at(String phase, {bool pickupConfirmed = false}) => DeliveryTracking(
      id: 'd1',
      identifier: 'del-1',
      bloodRequestId: 'br1',
      phase: phase,
      assignmentStatus: 'accepted',
      pickupConfirmedAt: pickupConfirmed ? DateTime.utc(2026, 10, 20, 8) : null,
      bloodBank: const TrackingPlace(),
      hospital: const TrackingPlace(),
    );

void main() {
  test('each courier phase maps to its slide label and next phase', () {
    expect(courierStep(_at('en_route_to_blood_bank')),
        (labelKey: 'slide_arrived_bank', nextPhase: 'at_blood_bank'));
    expect(courierStep(_at('at_blood_bank')), (labelKey: 'waiting_bank_handover', nextPhase: null));
    expect(courierStep(_at('at_blood_bank', pickupConfirmed: true)),
        (labelKey: 'slide_picked_up', nextPhase: 'picked_up_from_blood_bank'));
    expect(courierStep(_at('picked_up_from_blood_bank')),
        (labelKey: 'slide_leave_for_hospital', nextPhase: 'en_route_to_hospital'));
    expect(courierStep(_at('en_route_to_hospital')),
        (labelKey: 'slide_arrived_hospital', nextPhase: 'at_hospital'));
    expect(courierStep(_at('at_hospital')), (labelKey: 'waiting_hospital_confirm', nextPhase: null));
  });

  test('phases the courier does not drive have no step', () {
    for (final phase in ['awaiting_acceptance', 'delivered_and_confirmed', 'cancelled', '']) {
      expect(courierStep(_at(phase)), isNull, reason: phase);
    }
  });
}
