/// The courier's position goes out every 15 s over a bare PUT: a send that
/// hangs must give its socket back when it times out, not hold it open.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';

class _TrackedClient extends MockClient {
  _TrackedClient(super.fn);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'BASE_API_URL=http://api.test');
    // A stored token: getAuthToken returns before its GetStorage fallback (needs path_provider).
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
  });

  test('a send that times out closes its client, which drops the socket', () async {
    final client = _TrackedClient((_) => Completer<http.Response>().future); // never answers

    final res = await http.runWithClient(
      () => DeliveryApiService().updateDeliveryPersonLocation(-4.3, 15.3, accuracy: 9, timeout: const Duration(milliseconds: 20)),
      () => client,
    );

    expect(res.success, isFalse);
    expect(client.closed, isTrue);
  });

  test('a send that is answered closes its client too, and reads the status', () async {
    late http.Request sent;
    final client = _TrackedClient((req) async {
      sent = req;
      return http.Response('{}', 200);
    });

    final res = await http.runWithClient(() => DeliveryApiService().updateDeliveryPersonLocation(-4.3, 15.3, accuracy: 9), () => client);

    expect(res.success, isTrue);
    expect(client.closed, isTrue);
    expect(sent.method, 'PUT');
    expect(sent.url.toString(), 'http://api.test/eblood-connect/delivery-assignment/update-location');
    expect(sent.headers['Authorization'], 'Bearer tok');
    expect(jsonDecode(sent.body), {'lat': -4.3, 'lng': 15.3, 'accuracy': 9});
  });

  test('a refused send is an error', () async {
    final res = await http.runWithClient(
      () => DeliveryApiService().updateDeliveryPersonLocation(-4.3, 15.3),
      () => _TrackedClient((_) async => http.Response('{}', 403)),
    );

    expect(res.success, isFalse);
  });
}
