import 'dart:convert';
import 'dart:io';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueListeModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eblood_bank_mak_app/gestionStocks/business/service/banque/BanqueListeNetworkService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BanqueListeNetworkServiceImpl implements BanqueListeNetworkService {
  String baseURL;

  BanqueListeNetworkServiceImpl(this.baseURL);

  @override
  Future<List<BanqueModele>?> recuperationListeBanque(String token) async {
    var res =
        await http.get(Uri.parse("$baseURL/data/blood-banks?page=0"), headers: {
      "Authorization": "Bearer $token",
      //"Content-Type":"application/json",
      "eblood-lockkeys":
          "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
    });
    debugPrint("body response getuser: ${res.body}", wrapWidth: 1024);
    var reponseMap = json.decode(res.body) as Map;
    debugPrint("responseMap $reponseMap");
    var data = reponseMap['data'] as List;
    var responseFinal = data.map((e) => BanqueModele.fromJson(e)).toList();
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
  var impl = BanqueListeNetworkServiceImpl(baseUrl);
  var data = BanqueListeModele(page: "0");
  var token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1X2lkIjoiNjZkNzE5MDk3NWQ5MGE3YmMyMjgwYjkxIiwiaWV3IjoxNzI2MTM3ODQyNTY1LCJ0b2tlbiI6ImY2YzQ4YjcwZjUzNzRiZjM2MjAyYzk1MWJkZDYyNTU5N2Q2YWFjMmZkOTgyNWU2NjA4OTRmMjY0ZmVlMTE5ZGQiLCJpYXQiOjE3MjYxMzc4NDIsImV4cCI6MTcyNjM5NzA0Mn0.q1L06t0q3pv6JpDb52azAY001B6tIaHc6KHw3lFzG64';
  // impl.authenticate(data);
  impl.recuperationListeBanque(token);
}
