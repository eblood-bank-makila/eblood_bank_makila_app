import 'dart:convert';
import 'dart:io';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/DactumFavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/FavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/favoris/FavorisBanqueNetworkService.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../business/model/favoris/SupprimerFavorisModel.dart';

class FavorisNetworkServiceImpl implements FavorisBanqueNetworkService {
  String baseURL;

  FavorisNetworkServiceImpl(this.baseURL);

  @override
  // Future<AuthentificationModel> ajouterFavorisd(
  //     AuthenticateRequestBody data) async {
  //   var res = await http.post(Uri.parse("$baseURL/data/blood-bank-favory"),
  //       body: data.toJson(),
  //       headers: {
  //         "eblood-lockkeys":
  //             "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
  //       });
  //   print("gggggggggggggggggggg $res");
  //   print("jjjjjjjjjjjjjjjj ${res.body}");
  //   print("status coode ${res.statusCode}");
  //   var reponseMap = json.decode(res.body) as Map;
  //
  //   print("responseMap USER $reponseMap");
  //   var reponseFinal = AuthentificationModel.fromJson(reponseMap['data']);
  //   return reponseFinal;
  // }

  Future<void> ajouterFavoris(String authBearer, FavorisModele favorite) async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/data/blood-bank-favory'),
        headers: {
          "eblood-lockkeys":
              "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
          'Authorization': 'Bearer $authBearer', // Utiliser authBearer ici
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'blood_bank_id': favorite.blood_bank_id,
          // Utiliser l'ID de l'objet FavorisModele
        }),
      );
      print("gggggggggggggggggggg $response");
      print("jjjjjjjjjjjjjjjj ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Retourne les données de la réponse
      } else {
        throw Exception(
            'Erreur lors de l\'ajout aux favoris : ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion : $e');
    }
  }

  @override
  Future<List<BanqueModele>?> recuperationListeBanque(String authBarear) {
    // TODO: implement recuperationListeBanque
    throw UnimplementedError();
  }

  @override
  Future<List<BanqueModele>> recupererFavorites() {
    // TODO: implement recupererFavorites
    throw UnimplementedError();
  }

  @override
  Future<void> supprimerFavorite(String id) {
    // TODO: implement supprimerFavorite
    throw UnimplementedError();
  }

  @override
  // Future<List<FavorisRecupererModel>?> recuperationFavorisBanque(String authBarear) async {
  //   var res = await http
  //       .get(Uri.parse("$baseURL/data/blood-bank-favory?page=0"), headers: {
  //     "Authorization": "Bearer $authBarear",
  //     "Content-Type": "application/json",
  //     "eblood-lockkeys":
  //         "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
  //   });
  //   print("body response getuser: ${res.body}");
  //   var reponseMap = json.decode(res.body) as Map;
  //   print("responseMap $reponseMap");
  //   var data = reponseMap['data'] as List;
  //   var responseFinal =
  //       data.map((e) => FavorisRecupererModel.fromJson(e)).toList();
  //   return responseFinal;
  // }
  Future<List<DactumFavorisModel>?> recuperationFavorisBanque(String authBarear) async {
    var res = await http.get(
      Uri.parse("$baseURL/data/blood-bank-favory?page=0"),
      headers: {
        "Authorization": "Bearer $authBarear",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      },
    );

    print("body response getuser: ${res.body}");
    var reponseMap = json.decode(res.body) as Map<String, dynamic>;
    print("responseMap $reponseMap");

    var data =
        reponseMap['data'] as List? ?? []; // Gérer le cas où data est nul
    var responseFinal =
        data.map((e) => DactumFavorisModel.fromJson(e)).toList();

    return responseFinal;
  }

  @override
  Future<SupprimerFavorisModel> removeFavorite(String id, String authBearer) async {
    var res = await http.delete(
      Uri.parse("$baseURL/data/blood-bank-favory/$id"),
      headers: {
        "Authorization": "Bearer $authBearer",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      },
    );

    print("body response panier suppression: ${res.body}");
    var reponseMap = json.decode(res.body) as Map;
    print("responseMap $reponseMap");
    if (res.statusCode == 200 || res.statusCode == 204) {
      return supprimerFavorisModelFromJson(res.body);
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

void main() async {
  HttpOverrides.global = new MyHttpOverrides();

  String baseUrl = dotenv.env['BASE_URL'] ?? '';

  var impl = FavorisNetworkServiceImpl(baseUrl);
  var token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0xMC0wMVQxMDoxMDoyOC4xMDdaIiwiaWF0IjoxNzI3Nzc3MTI4LCJleHAiOjE3MjgwMzYzMjh9.QbERkKCLiLUT4_cha1cYgm-Y6O7wbiFX3HKZCLiIJNo';
  //var favorite = FavorisModele(blood_bank_id: "66d717d175d90a7bc227fd76");
  var id = "ere";

  impl.removeFavorite(id, token);
}
