import 'dart:convert';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/poche/PocheListeNetworkService.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PocheListeNetworkServiceImpl implements PocheListeNetworkService {
  String baseURL;

  PocheListeNetworkServiceImpl(this.baseURL);

  @override
  Future<List<PocheModel>?> recuperationListePoche(String _id, String token) async {
    var res = await http.get(
        Uri.parse("$baseURL/data/blood-bags?blood_bank_id=$_id"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "eblood-lockkeys":
              "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
        });
    print("body response getuser: ${res.body}");
    var reponseMap = json.decode(res.body) as Map;
    print("responseMap $reponseMap");
    var data = reponseMap['data'] as List;
    var responseFinal = data.map((e) => PocheModel.fromJson(e)).toList();
    return responseFinal;
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

  var impl = PocheListeNetworkServiceImpl(baseUrl);
  // var data = BanqueListeModele(page: "0");
  var token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0wOS0xOVQxMjoxMTo0Ny4yMTVaIiwiaWF0IjoxNzI2NzQ3NjA3LCJleHAiOjE3MjcwMDY4MDd9.0-IMlUwcOFsgGVnIkFzfgP-YbTBMoOZ7TybzBWPYiO4';
  // impl.authenticate(data);
  var id = "66d717cd75d90a7bc227fd20";
  impl.recuperationListePoche(id, token);
}
