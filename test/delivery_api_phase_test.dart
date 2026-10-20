import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:eblood_bank_mak_app/delivery/business/model/DeliveryModels.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';

/// PUT /phase end to end against a fake server: the courier must read the
/// server's own 409 text, which arrives in the AppResponse envelope's `message`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'BASE_API_URL=http://api.test');
    // A stored token: getAuthToken returns before its GetStorage fallback (needs path_provider).
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
  });

  late http.Request sent;

  Future<ApiResponse<bool>> put(int status, String body) => http.runWithClient(
        () => DeliveryApiService().updateDeliveryPhase('d1', 'at_blood_bank', location: LocationInfo(lat: -4.3, lng: 15.3)),
        () => MockClient((req) async {
          sent = req;
          return http.Response.bytes(utf8.encode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});
        }),
      );

  test('a 409 carries the server message and status', () async {
    const msg = "La livraison n'est pas encore remise par la banque…";
    final res = await put(409, jsonEncode({'success': false, 'status_code': 409, 'message': msg, 'data': null}));
    expect(res.success, isFalse);
    expect(res.error, msg);
    expect(res.statusCode, 409);
    expect(sent.method, 'PUT');
    expect(sent.headers['Authorization'], 'Bearer tok');
    expect(sent.url.toString(), 'http://api.test/eblood-connect/delivery-assignment/d1/phase');
    expect(jsonDecode(sent.body), {
      'phase': 'at_blood_bank',
      'location': {'lat': -4.3, 'lng': 15.3},
    });
  });

  test('a plain FastAPI {detail} body is read too', () async {
    final res = await put(409, jsonEncode({'detail': 'Cette livraison est terminée ou annulée.'}));
    expect(res.error, 'Cette livraison est terminée ou annulée.');
  });

  test('a non-JSON error body falls back to the generic text', () async {
    final res = await put(502, '<html>Bad gateway</html>');
    expect(res.error, 'Failed to update delivery phase');
    expect(res.statusCode, 502);
  });

  test('200 is a success', () async {
    final res = await put(200, jsonEncode({'success': true}));
    expect(res.success, isTrue);
  });
}
