import 'dart:convert';
import 'dart:io';
import 'package:eblood_bank_mak_app/commande/business/model/PanierModel.dart';
import 'package:eblood_bank_mak_app/commande/business/model/PanierReponseModel.dart';
import 'package:eblood_bank_mak_app/commande/business/model/RecupererPanierResponseModel.dart';
import 'package:http/http.dart' as http;
import '../../../business/model/panier/SuppressionPanierResponseModel.dart';
import '../../../business/service/panier/PanierNetworkService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PanierServiceNetworkImpl implements PanierNetworkService {
  String baseURL;

  PanierServiceNetworkImpl(this.baseURL);

  @override
  Future<PanierReponseModel?> ajouterPanier(
      PanierModel data, String authBearer) async {
    final response = await http.post(
      Uri.parse('$baseURL/data/carts'),
      headers: {
        "Authorization": "Bearer $authBearer",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
      },
      body: jsonEncode({
        'blood_bank_id': data.blood_bank_id,
        'blood_bag_id': data.blood_bag_id,
        'quantity': data.quantity,
      }),
    );

    if (response.statusCode == 200) {
      var responseMap = json.decode(response.body) as Map<String, dynamic>;
      print("Response Map: $responseMap");
      var responseFinal = PanierReponseModel.fromJson(responseMap);
      return responseFinal;
    } else {
      // Gérer les erreurs ici
      return null;
    }
  }

  @override
  Future<RecupererPanierResponseModel> recuperationListePanier(
      String authBearer) async {
    final res = await http.get(
      Uri.parse("$baseURL/data/carts?page=0"),
      headers: {
        "Authorization": "Bearer $authBearer",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      },
    );

    print("body response getuser: ${res.body}");

    // Vérifiez le code de statut de la réponse
    if (res.statusCode != 200) {
      throw Exception(
          "Erreur lors de la récupération des données: ${res.statusCode}");
    }

    // Décodez la réponse JSON
    var responseMap = json.decode(res.body) as Map<String, dynamic>;
    print("responseMap: $responseMap");

    // Créez un objet RecupererPanierResponseModel à partir de la réponse
    var responseFinal = RecupererPanierResponseModel.fromJson(responseMap);

    return responseFinal;
  }

  // @override
  // Future<void> supprimerPochePanier(
  //     String cartId, String bloodBagId, String authBearer) async {
  //   final url =
  //       Uri.parse("$baseURL/data/carts/$cartId?blood_bag_id=$bloodBagId");
  //
  //   final response = await http.delete(
  //     url,
  //     headers: {
  //       "Authorization": "Bearer $authBearer",
  //       "Content-Type": "application/json",
  //       "eblood-lockkeys":
  //           "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
  //     },
  //   );
  //   if (response.statusCode != 200) {
  //     throw Exception(
  //         "Erreur lors de la suppression de la poche: ${response.statusCode}");
  //   }
  // }

  @override
  Future<SuppressionPanierResponseModel> supprimerPochePanier(
      String cartId, String bloodBagId, String authBearer) async {
    final url =
        Uri.parse("$baseURL/data/carts/$cartId?blood_bag_id=$bloodBagId");

    print("hhhhhhhhhhh $url");

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $authBearer",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      },
    );
    print("body response panier suppression: ${response.body}");
    var reponseMap = json.decode(response.body) as Map;
    print("responseMap $reponseMap");
    if (response.statusCode == 200 || response.statusCode == 204) {
      return suppressionPanierResponseModelFromJson(response.body);
    } else {
      throw Exception('Erreur lors de la suppression de la notification');
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

  var impl = PanierServiceNetworkImpl(baseUrl);
  var authBearer =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0xMC0xMFQxMTozNDozMS4wNjNaIiwiaWF0IjoxNzI4NTU5NzcxLCJleHAiOjE3Mjg4MTg5NzF9.Qpxv4-PfsC4dm8TF5fWjR9Io5dSVKjuygmJ0atZ7Z-I';

  String cartId = "66e83a46e207195903763505";
  String bloodBagId = "66d7141975d90a7bc227adeb";

  impl.supprimerPochePanier(cartId, bloodBagId, authBearer);
}
