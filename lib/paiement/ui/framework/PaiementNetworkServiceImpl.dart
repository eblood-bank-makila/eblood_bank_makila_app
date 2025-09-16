import 'dart:convert';
import 'dart:io';
import 'package:eblood_bank_mak_app/paiement/businness/models/PaiementModel.dart';
import 'package:eblood_bank_mak_app/paiement/businness/models/PaiementResponseModel.dart';
import 'package:eblood_bank_mak_app/paiement/businness/service/PaiementNetworkService.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaiementServiceNetworkImpl implements PaiementNetworkService {
  String baseURL;

  PaiementServiceNetworkImpl(this.baseURL);

  @override
  Future<PaiementResponseModel?> ajouterPaiement(
      PaiementModel data, String authBearer) async {
    final response = await http.post(
      Uri.parse('$baseURL/data/blood-request'),
      headers: {
        "Authorization": "Bearer $authBearer",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
      },
      body: jsonEncode({
        'cart_id': data.cartId,
        if (data.phoneNumber != null) 'phone_number': data.phoneNumber,
        if (data.transactionalCurrencyId != null) 'transactional_currency_id': data.transactionalCurrencyId,
      }),
    );

    if (response.statusCode == 200) {
      var responseMap = json.decode(response.body) as Map<String, dynamic>;
      print("Response Map: $responseMap");
      var responseFinal = PaiementResponseModel.fromJson(responseMap);
      return responseFinal;
    } else {
      // Gérer les erreurs ici
      return null;
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = new MyHttpOverrides();
  String baseUrl = dotenv.env['BASE_URL'] ?? '';
  var impl = PaiementServiceNetworkImpl(baseUrl);
  var authBearer =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0wOS0zMFQxMTozNDoxOS41ODVaIiwiaWF0IjoxNzI3Njk1NzU5LCJleHAiOjE3Mjc5NTQ5NTl9.DeRfSlq90U9DylDtzqbEbSIuazLd9n2PoN9wFSbFoJ8';
  var card = PaiementModel(cartId: "66fd405f337dfdc01e1bd9c4");

  //String cart_id = "66fd405f337dfdc01e1bd9c4";

  impl.ajouterPaiement(card, authBearer);
}
