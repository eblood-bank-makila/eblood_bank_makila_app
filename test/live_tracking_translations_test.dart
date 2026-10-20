import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';

/// GetX's `.tr` shows the raw key when a locale lacks it, so every string the
/// live delivery tracking feature can display must exist in all five locales,
/// once per locale, with the same `@param` placeholders everywhere.
void main() {
  final locales = AppTranslations().keys;

  // The keys the code uses, by file. Dynamic ones (pillKey, courierStep, the
  // duty refusals, deliveryEnd, _stepLabels) are spelled out here.
  const keys = <String>[
    // delivery_sheet.dart
    'sheet_minimize', 'sheet_navigate', 'contact_support', 'call', 'slide_busy',
    'error_updating_status', 'handover_code_label', 'live_seconds_ago', 'position_stale_minutes',
    'eta_minutes', 'eta_km_to_bank', 'eta_km_to_hospital', 'eta_arrival_at',
    'courier_on_moto', 'cargo_from', 'cargo_prepare_for',
    'step_bank', 'step_picked_up', 'step_en_route', 'step_handover', 'step_hospital', 'step_delivered',
    'confirm_receipt', 'confirm_handover', 'confirm_handover_message', 'handover_confirmed',
    'cancel', 'confirm',
    // pillKey (sheet pill + home cards)
    'pill_waiting_courier', 'pill_at_bank', 'pill_courier_arrived', 'pill_at_hospital',
    'pill_to_bank', 'pill_to_hospital', 'pill_to_you', 'pill_courier_coming',
    // courierStep slide / wait labels
    'slide_arrived_bank', 'slide_picked_up', 'slide_leave_for_hospital', 'slide_arrived_hospital',
    'waiting_bank_handover', 'waiting_hospital_confirm',
    // end of delivery (deliveryEnd, delivery_call_payload) and the minimized bar
    'delivery_reassigned', 'delivery_cancelled_by_admin', 'delivery_in_progress_bar', 'delivery_bar_subtitle',
    // confirm_reception_dialog.dart, active_delivery_sheet_controller.dart, delivery_map_view.dart
    'confirm_delivery', 'confirm_delivery_message', 'delivery_confirmed', 'map_recenter',
    // duty_switch.dart / courier_duty_service.dart
    'duty_on', 'duty_off', 'duty_location_needed', 'duty_finish_delivery_first', 'duty_server_error', 'open_settings',
    // Active / Incoming / Outgoing delivery cards
    'active_delivery', 'en_route_to_blood_bank', 'at_blood_bank', 'picked_up', 'en_route_to_hospital',
    'at_hospital', 'delivered', 'in_progress', 'incoming_delivery', 'eta', 'from', 'delivery_person',
    'blood_bags', 'track',
  ];

  final params = RegExp(r'@\w+');
  Set<String> paramsOf(String s) => params.allMatches(s).map((m) => m[0]!).toSet();

  test('every live tracking key is translated in every locale', () {
    final missing = <String>[];
    for (final entry in locales.entries) {
      for (final key in keys) {
        final value = entry.value[key];
        if (value == null || value.trim().isEmpty) missing.add('${entry.key}: $key');
      }
    }
    expect(missing, isEmpty);
  });

  test('every locale uses the same @params as French', () {
    final differing = <String>[];
    for (final key in keys) {
      final expected = paramsOf(locales['fr_FR']![key] ?? '');
      for (final entry in locales.entries) {
        final got = paramsOf(entry.value[key] ?? '');
        if (got.length != expected.length || !got.containsAll(expected)) {
          differing.add('${entry.key}: $key has $got, fr_FR has $expected');
        }
      }
    }
    expect(differing, isEmpty);
  });

  test('no key is declared twice in a locale', () {
    // A repeated map-literal key compiles; the later one silently wins.
    final lines = File('lib/apps/translations/AppTranslations.dart').readAsLinesSync();
    final locale = RegExp(r"^    '([a-z]{2}_[A-Z]{2})': \{");
    final entry = RegExp(r"^      '([^']+)':");
    final seen = <String, int>{};
    String? current;
    for (final line in lines) {
      final l = locale.firstMatch(line);
      if (l != null) current = l[1];
      final e = entry.firstMatch(line);
      if (current != null && e != null && keys.contains(e[1])) {
        seen.update('$current: ${e[1]}', (n) => n + 1, ifAbsent: () => 1);
      }
    }
    expect(seen.entries.where((e) => e.value > 1).map((e) => '${e.key} x${e.value}'), isEmpty);
    expect(seen.length, locales.length * keys.length, reason: 'a key was not found in the scan');
  });
}
