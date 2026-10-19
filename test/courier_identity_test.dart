import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The server takes the acting courier from the login token. The app used
/// to send `delivery_person_id` from a provider nobody ever set (always
/// empty → 500/403 on accept, reject, phase), and the server trusted it.
void main() {
  test('the delivery API never sends a courier id', () {
    final src = File('lib/delivery/business/service/DeliveryApiService.dart').readAsStringSync();
    expect(src.contains('delivery_person_id'), isFalse);
  });

  test('no courier-id provider is left to forget to set', () {
    final src = File('lib/delivery/business/interactors/DeliveryController.dart').readAsStringSync();
    expect(src.contains('deliveryPersonIdProvider'), isFalse);
  });
}
