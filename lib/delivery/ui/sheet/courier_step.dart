import '../../business/model/delivery_tracking.dart';

/// The courier's next step: the slide label (translation key) and the phase
/// it moves to. A null [nextPhase] means "wait for the other side" (text, no
/// slide); a null result means the courier has nothing to drive.
({String labelKey, String? nextPhase})? courierStep(DeliveryTracking t) => switch (t.phase) {
      'en_route_to_blood_bank' => (labelKey: 'slide_arrived_bank', nextPhase: 'at_blood_bank'),
      // The pickup is gated server-side on the bank's handover confirmation.
      'at_blood_bank' when t.pickupConfirmedAt == null => (labelKey: 'waiting_bank_handover', nextPhase: null),
      'at_blood_bank' => (labelKey: 'slide_picked_up', nextPhase: 'picked_up_from_blood_bank'),
      'picked_up_from_blood_bank' => (labelKey: 'slide_leave_for_hospital', nextPhase: 'en_route_to_hospital'),
      'en_route_to_hospital' => (labelKey: 'slide_arrived_hospital', nextPhase: 'at_hospital'),
      'at_hospital' => (labelKey: 'waiting_hospital_confirm', nextPhase: null),
      _ => null,
    };
