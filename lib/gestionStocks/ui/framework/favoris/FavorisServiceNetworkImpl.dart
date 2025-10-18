import 'dart:io';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/DactumFavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/favoris/FavorisModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/favoris/FavorisBanqueNetworkService.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../business/model/favoris/SupprimerFavorisModel.dart';

class FavorisNetworkServiceImpl implements FavorisBanqueNetworkService {
  String baseURL;

  FavorisNetworkServiceImpl(this.baseURL);

  @override
  
  
  Future<Map<String, dynamic>> ajouterFavoris(String authBearer, FavorisModele favorite) async {
    try {
      debugPrint("📤 Toggling favorite: ${favorite.blood_bank_id}");

      final response = await postWithDio(
        '/eblood-connect/blood-bank-favory',
        body: {
          'blood_bank_id': favorite.blood_bank_id,
        },
      );

      // Check if the response was successful
      if (response.success != true) {
        debugPrint("❌ Backend returned error: ${response.message}");
        throw Exception(response.message ?? 'Erreur lors de l\'opération');
      }

      // Extract action and message from response
      final data = response.data as Map<String, dynamic>? ?? {};
      final action = data['action'] ?? 'added';
      final message = response.message ?? 'Opération réussie';

      debugPrint("✅ Favorite $action: $message");

      return {
        'action': action,
        'message': message,
        'data': data,
      };
    } catch (e) {
      debugPrint("❌ Error toggling favorite: $e");
      throw Exception('Erreur lors de l\'opération : $e');
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
  
  
  Future<List<DactumFavorisModel>?> recuperationFavorisBanque(String authBarear) async {
    try {
      debugPrint("📥 Fetching favorites list");

      final response = await getWithDio(
        '/eblood-connect/blood-bank-favory',
        queryParams: {'page': '0'},
      );

      debugPrint("✅ Favorites response: ${response.message}");

      var data = response.data as List? ?? [];
      var responseFinal = data.map((e) => DactumFavorisModel.fromJson(e)).toList();

      debugPrint("✅ Parsed ${responseFinal.length} favorites");
      return responseFinal;
    } catch (e) {
      debugPrint("❌ Error fetching favorites: $e");
      throw Exception('Erreur lors de la récupération des favoris : $e');
    }
  }

  @override
  Future<SupprimerFavorisModel> removeFavorite(String id, String authBearer) async {
    try {
      debugPrint("🗑️ Removing favorite: $id");

      final response = await deleteWithDio(
        '/eblood-connect/blood-bank-favory',
        queryParams: {'favorite_id': id},
      );

      debugPrint("✅ Favorite removed successfully: ${response.message}");

      // Return a success model
      return SupprimerFavorisModel(
        statusCode: response.statusCode ?? 200,
        success: response.success,
        sms: response.message ?? 'Favori supprimé avec succès',
      );
    } catch (e) {
      debugPrint("❌ Error removing favorite: $e");
      throw Exception('Erreur lors de la suppression du favori : $e');
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
