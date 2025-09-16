import 'dart:io';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/Authentification.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/changerPassword/ChangerPasswordModel.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/changerPassword/PasswordChangerModel.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/notification/DatumNotificationModel.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/MotDePasseModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/MotDePasseOublieModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/OtpCodeReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/OtpReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/ReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/reinitialiserPassword/ReinitialiserPasswordModele.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurNetworkService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../business/models/notification/SuppressionDatumNotificationModel.dart';


class UtilisateurNetworkServiceImpl implements UtilisateurNetworkService {
  String baseURL;

  UtilisateurNetworkServiceImpl(this.baseURL) {
    // Temporary override for testing
    String baseUrl = dotenv.env['BASE_URL'] ?? '';
    this.baseURL = baseUrl;
    print("🔧 UtilisateurNetworkServiceImpl initialized with baseURL: ${this.baseURL}");
  }

  @override
  Future<AuthentificationModel> login(AuthenticateRequestBody data) async {
    try {
      print("🚀 Starting login request to: $baseURL/auth/login");
      print("📤 Request data: ${data.toJson()}");

      var res = await http.post(
        Uri.parse("$baseURL/auth/login"),
        body: json.encode(data.toJson()),
        headers: {
          "Content-Type": "application/json",
          "eblood-lockkeys": "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
        }
      );

      print("📡 HTTP Response: $res");
      print("📄 Response body: ${res.body}");
      print("🔢 Status code: ${res.statusCode}");

      if (res.statusCode != 200) {
        print("❌ HTTP Error: ${res.statusCode} - ${res.reasonPhrase}");
        throw Exception("HTTP Error: ${res.statusCode} - ${res.reasonPhrase}");
      }

      var reponseMap = json.decode(res.body) as Map;
      print("🗂️ Response map: $reponseMap");

      if (reponseMap['data'] == null) {
        print("❌ No data field in response");
        throw Exception("No data field in response");
      }

      var reponseFinal = AuthentificationModel.fromJson(reponseMap['data']);
      print("✅ Login successful: ${reponseFinal.toJson()}");
      return reponseFinal;
    } catch (e) {
      print("💥 Login error: $e");
      rethrow;
    }
  }

  @override
  Future<List<String>> recuperationNomUtilisateur(String name) async {
    var res = await http
        .post(Uri.parse("$baseURL/api/getnameuser"), body: {"name": name});
    print(res.body);
    List<dynamic> decodedResponse = json.decode(res.body) as List<dynamic>;
    List<String> nameList =
        decodedResponse.map((item) => item.toString()).toList();
    print("response $nameList");
    return nameList;
  }

  @override
  // Future<AuthentificationModel?> recuperationUtilisateur(String token) async {
  //   var res = await http.get(Uri.parse("$baseURL/api/getuser"),
  //       headers: {"Authorization": "Bearer $token"});
  //   print("body response getuser: ${res.body}");
  //   var reponseMap = json.decode(res.body) as Map;
  //   print("responseMap $reponseMap");
  //   var responseFinal = AuthentificationModel.fromJson(reponseMap);
  //   return responseFinal;
  // }

  Future<AuthentificationModel?> recuperationUtilisateur(String token) async {
    var res = await http.get(Uri.parse("$baseURL/api/getuser"),
        headers: {"Authorization": "Bearer $token"});

    print("body response getuser: ${res.body}");

    // Decode the response body to a Map<dynamic, dynamic>
    var responseMap = json.decode(res.body) as Map<dynamic, dynamic>;
    print("responseMap $responseMap");

    // Cast to Map<String, dynamic> before passing to fromJson
    var responseFinal =
        AuthentificationModel.fromJson(responseMap.cast<String, dynamic>());

    return responseFinal;
  }

  @override
  Future<DatumCodeOtpModele?> verifyOtp(OtpModele data, String token) async {
    var res = await http
        .post(Uri.parse("$baseURL/auth/otp"), body: data.toJson(), headers: {
      "Authorization": "Bearer $token",
      //"Content-Type":"application/json",
      "eblood-lockkeys":
          "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
    });
    print("gggggggggggggggggggg ${data.toJson()}");
    print("gggggggggggggggggggg $res");
    print("jjjjjjjjjjjjjjjj ${res.body}");
    print("status coode ${res.statusCode}");
    var reponseMap = json.decode(res.body);
    print("responseMap USER $reponseMap");

    // Check if the response indicates success
    if (reponseMap['success'] == true && reponseMap['data'] != null) {
      var reponseFinal = DatumCodeOtpModele.fromJson(reponseMap['data']);
      return reponseFinal;
    } else {
      // Handle error case - throw exception with server message
      String errorMessage = reponseMap['sms'] ?? 'Code OTP invalide';
      print("❌ OTP verification failed: $errorMessage");
      throw Exception(errorMessage);
    }
  }

  @override
  Future<DatumCodeOtpModele?> recuperationUtilisateurOtp(String token) {
    // T ODO: implement recuperationUtilisateurOtp
    throw UnimplementedError();
  }

  @override
  Future<String> renvoiCode(String token) async {
    final res = await http.get(
      Uri.parse("$baseURL/auth/resent-login-otp"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      },
    );
    print("body response : ${res.body}");
    var reponseMap = res.body;
    print("responseMap $reponseMap");
    return reponseMap;
  }

  @override
  Future<bool> deconnexion(String? token) async {
    final res = await http.get(
      Uri.parse('$baseURL/auth/logout'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "eblood-l ockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      },
    );

    print("body response : ${res.body}"); // Affiche le corps de la réponse

    // Vérifiez le code de statut
    if (res.statusCode == 200 || res.statusCode == 204) {
      return true; // Déconnexion réussie
    } else {
      print('Erreur de déconnexion : ${res.statusCode} ${res.body}');
      return false; // Déconnexion échouée
    }
  }

  @override
  Future<MotDePasseModele?> reinitialiserPassword(
      MotDePasseOublieModele data) async {
    var res = await http.post(Uri.parse("$baseURL/auth/c-username"),
        body: data.toJson(),
        headers: {
          "eblood-lockkeys":
              "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
        });
    print("gggggggggggggggggggg $res");
    print("jjjjjjjjjjjjjjjj ${res.body}");
    print("status coode ${res.statusCode}");
    var reponseMap = json.decode(res.body) as Map;
    //toucher
    // var resp = reponseMap['data'];
    //toucher
    print("responseMap USER $reponseMap");
    var reponseFinal = MotDePasseModele.fromJson(reponseMap['data']);
    return reponseFinal;
  }

  @override
  Future<String> renvoiCodePassword(String token) async {
    final res = await http.get(
      Uri.parse("$baseURL/auth/resent-otp"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      },
    );
    print("body response : ${res.body}");
    var reponseMap = res.body;
    print("responseMap $reponseMap");
    return reponseMap;
  }

  @override
  Future<OtpCodeReinitialiserModele?> verifyOtpPassword(
      OtpReinitialiserModele data, String token) async {
    var res = await http.post(Uri.parse("$baseURL/auth/check-otp-existance"),
        body: data.toJson(),
        headers: {
          "Authorization": "Bearer $token",
          //"Content-Type":"application/json",
          "eblood-lockkeys":
              "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
        });
    print("gggggggggggggggggggg ${data.toJson()}");
    print("gggggggggggggggggggg $res");
    print("jjjjjjjjjjjjjjjj ${res.body}");
    print("status coode ${res.statusCode}");
    var reponseMap = json.decode(res.body);
    print("responseMap USER $reponseMap");
    var reponseFinal = OtpCodeReinitialiserModele.fromJson(reponseMap);
    return reponseFinal;
  }

  @override
  Future<ReinitialiserModele?> passwordReinitialiser(
      ReinitialiserPasswordModele data, String token) async {
    var response = await http.post(
      Uri.parse("$baseURL/auth/initiate-password"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
      },
      body: jsonEncode(data.toJson()), // Utilisez jsonEncode ici
    );

    print("Response: $response");
    print("Body: ${response.body}");
    print("Status Code: ${response.statusCode}");
    print("Request Body: ${jsonEncode(data.toJson())}");

    if (response.statusCode == 200) {
      var responseMap = json.decode(response.body) as Map<String, dynamic>;
      print("Response Map: $responseMap");
      var responseFinal = ReinitialiserModele.fromJson(responseMap);
      return responseFinal;
    } else {
      // Gérer les erreurs ici
      return null;
    }
  }

  @override
  Future<PasswordChangerModel?> passwordChanger(
      ChangerPasswordModel data) async {
    // Call the method to change the password
    return await changerPassword(data, "your_token_here");
  }

  Future<PasswordChangerModel?> changerPassword(
      ChangerPasswordModel data, String token) async {
    try {
      var res = await http.post(
        Uri.parse("$baseURL/data/users/reset-password"),
        body: json.encode(data.toJson()), // Assurez-vous de l'encoder en JSON
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          // Assurez-vous d'indiquer le type de contenu
          "eblood-lockkeys":
              "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
        },
      );

      print("Response: $res");
      print("Response Body: ${res.body}");
      print("Status Code: ${res.statusCode}");

      if (res.statusCode == 200) {
        var responseMap = json.decode(res.body) as Map;
        print("Response Map: $responseMap");

        if (responseMap['data'] != null) {
          return PasswordChangerModel.fromJson(responseMap['data']);
        } else {
          print("Aucune donnée dans la réponse.");
          return null; // Gérer le cas où 'data' est null
        }
      } else {
        print("Erreur: ${res.statusCode} - ${res.body}");
        return null; // Gérer les erreurs en fonction du code de statut
      }
    } catch (e) {
      print("Exception lors de l'appel à l'API: $e");
      return null; // Gérer l'exception
    }
  }

  // Future<PasswordChangerModel?> changerPassword(
  //     ChangerPasswordModel data, String token) async {
  //   var res = await http.post(
  //     Uri.parse("$baseURL/data/users/reset-password"),
  //     body: data.toJson(),
  //     headers: {
  //       "Authorization": "Bearer $token",
  //       "eblood-lockkeys":
  //           "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
  //     },
  //   );
  //
  //   print("Response: $res");
  //   print("Response Body: ${res.body}");
  //   print("Status Code: ${res.statusCode}");
  //
  //   var responseMap = json.decode(res.body) as Map;
  //   print("Response Map: $responseMap");
  //
  //   if (responseMap['data'] != null) {
  //     return PasswordChangerModel.fromJson(responseMap['data']);
  //   } else {
  //     return null; // Handle the case where 'data' is null
  //   }
  // }

  @override
  Future<List<DatumNotificationModel>?> recuperationNotification(
      String authBarear) async {
    var res = await http
        .get(Uri.parse("$baseURL/data/notifications?page=0"), headers: {
      "Authorization": "Bearer $authBarear",
      "Content-Type": "application/json",
      "eblood-lockkeys":
          "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
    });
    print("body response getuser: ${res.body}");
    var reponseMap = json.decode(res.body) as Map;
    print("responseMap $reponseMap");
    var data = reponseMap['data'] as List;
    var responseFinal =
        data.map((e) => DatumNotificationModel.fromJson(e)).toList();
    return responseFinal;
  }

  @override
  Future<SuppressionDatumNotificationModel> suppressionNotification(
      String _id, String authBarear) async {
    final res = await http
        .delete(Uri.parse("$baseURL/data/notifications/$_id"), headers: {
      "Authorization": "Bearer $authBarear",
      "Content-Type": "application/json",
      "eblood-lockkeys":
          "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
    });
    print("body response getuser: ${res.body}");
    var reponseMap = json.decode(res.body) as Map;
    print("responseMap $reponseMap");
    if (res.statusCode == 200 || res.statusCode == 204) {
      return suppresionDatumNotificationModelFromJson(res.body);
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
  var impl = UtilisateurNetworkServiceImpl(baseUrl);
  var token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0xMC0wMVQxMDoxMDoyOC4xMDdaIiwiaWF0IjoxNzI3Nzc3MTI4LCJleHAiOjE3MjgwMzYzMjh9.QbERkKCLiLUT4_cha1cYgm-Y6O7wbiFX3HKZCLiIJNo';
  //var data =ReinitialiserPasswordModele(password: "Nd.hena", password2: "Nd.hena");
  var data = ChangerPasswordModel(
      oldpassword: "mmmm", password: "ppppp", password2: "ppppp");
  //var data = "66deb4b202760076e9bc5e1a";
  impl.changerPassword(data, token);
}
