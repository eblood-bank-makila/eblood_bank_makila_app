import 'dart:convert';
import 'dart:io';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/recherche/DatumRecherchePocheModel.dart';
import 'package:http/http.dart' as http;

import '../../../business/service/recherche/RechercheListeNetworkService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RechercheListeNetworkServiceImpl implements RechercheListeNetworkService {
  String baseURL;

  RechercheListeNetworkServiceImpl(this.baseURL);



  @override
  Future<List<DatumRecherchePocheModel>> recuperationRechercheListeBanque(String searchKey, String authBearer) async {
    print('🌐 Making search API call to: $baseURL/data/blood-bags?search_key=$searchKey');
    print('🔑 Auth token: ${authBearer.isNotEmpty ? "Present (${authBearer.length} chars)" : "Empty"}');

    var res = await http.get(Uri.parse("$baseURL/data/blood-bags?search_key=$searchKey"),
        headers: {
      "Authorization": "Bearer $authBearer",
      "Content-Type":"application/json",
      "eblood-lockkeys":
      "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
    });

    print("📡 Response status: ${res.statusCode}");
    print("📄 Response body: ${res.body}");

    if (res.statusCode != 200) {
      print("❌ API Error: Status ${res.statusCode}");
      return [];
    }

    try {
      var reponseMap = json.decode(res.body) as Map;
      print("🗂️ Response map keys: ${reponseMap.keys.toList()}");

      if (!reponseMap.containsKey('data')) {
        print("❌ No 'data' key in response");
        return [];
      }

      var data = reponseMap['data'] as List;
      print("📊 Data array length: ${data.length}");

      if (data.isEmpty) {
        print("⚠️ Data array is empty");
        return [];
      }

      print("📋 First item keys: ${data.first.keys.toList()}");
      print("🔍 First item content: ${data.first}");

      var responseFinal = <DatumRecherchePocheModel>[];
      for (int i = 0; i < data.length; i++) {
        try {
          print("🔄 Parsing item $i...");
          var item = DatumRecherchePocheModel.fromJson(data[i]);
          responseFinal.add(item);
          print("✅ Successfully parsed item $i");
        } catch (e) {
          print("💥 Error parsing item $i: $e");
          print("📄 Item $i content: ${data[i]}");
        }
      }

      print("✅ Successfully parsed ${responseFinal.length} items out of ${data.length}");

      return responseFinal;
    } catch (e) {
      print("💥 Error parsing response: $e");
      return [];
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
  var impl = RechercheListeNetworkServiceImpl(baseUrl);
//  var data = BanqueListeModele(page: "0");
  var token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoiMjAyNC0wOS0xOVQxMjoxMTo0Ny4yMTVaIiwiaWF0IjoxNzI2NzQ3NjA3LCJleHAiOjE3MjcwMDY4MDd9.0-IMlUwcOFsgGVnIkFzfgP-YbTBMoOZ7TybzBWPYiO4';
  // impl.authenticate(data);
  String searchKey="c";
  impl.recuperationRechercheListeBanque(searchKey, token);
}
