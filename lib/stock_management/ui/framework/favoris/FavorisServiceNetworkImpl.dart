import 'dart:io';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/favoris/DactumFavorisModel.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/favoris/FavorisModel.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/favoris/FavorisBanqueNetworkService.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

import '../../../business/model/favoris/SupprimerFavorisModel.dart';

class FavorisNetworkServiceImpl implements FavorisBanqueNetworkService {
  String baseURL;
  final GetStorage _storage = GetStorage();

  FavorisNetworkServiceImpl(this.baseURL);

  /// Sprint 13a — read the current user's id from the auth-cached
  /// `user_data` GetStorage entry, written by AuthApi/AuthService at
  /// login time. Throws if missing — Sprint 13a's three favorites
  /// endpoints all require user_id explicitly (no JWT-derived shortcut).
  String _currentUserId() {
    final userData = _storage.read('user_data');
    if (userData is Map) {
      final raw = userData['id'];
      if (raw != null && raw.toString().isNotEmpty) {
        return raw.toString();
      }
    }
    throw StateError(
      'Cannot toggle favorite: user_data not in GetStorage. '
      'Sprint 13a requires user_id in the request — log in first.',
    );
  }

  @override
  Future<Map<String, dynamic>> ajouterFavoris(String authBearer, FavorisModele favorite) async {
    try {
      debugPrint("📤 Toggling favorite: ${favorite.blood_bank_id}");

      // Sprint 13a — migrated to /api/v1/favorites/add-blood-bank-favorite.
      // The endpoint is idempotent (re-adding the same pair returns the
      // existing row, never 409) so the caller doesn't need to pre-check.
      final response = await postWithDio(
        '/favorites/add-blood-bank-favorite',
        body: {
          'user_id': _currentUserId(),
          'blood_bank_org_id': favorite.blood_bank_id,
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

      // Sprint 13a — migrated to GET /api/v1/favorites/list-blood-bank-favorites.
      // The endpoint enriches each row with blood_bank_name / latitude /
      // longitude / identifier joined from sys_health_structure, so
      // DactumFavorisModel can render directly.
      final response = await getWithDio(
        '/favorites/list-blood-bank-favorites',
        queryParams: {
          'user_id': _currentUserId(),
          'skip': '0',
          'limit': '50',
        },
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

  /// Sprint 13a — `id` is now the **blood-bank organisation id** (not the
  /// favorite row id). The new POST /api/v1/favorites/remove-blood-bank-
  /// favorite endpoint identifies the row by (user_id, blood_bank_org_id),
  /// so a caller that has the favorite row in hand should pass
  /// `dactumFavoris.blood_bank_org_id`. Idempotent: removing a non-
  /// existent favorite returns 200 with `removed=False`.
  @override
  Future<SupprimerFavorisModel> removeFavorite(String id, String authBearer) async {
    try {
      debugPrint("🗑️ Removing favorite (blood_bank_org_id=$id)");

      final response = await postWithDio(
        '/favorites/remove-blood-bank-favorite',
        body: {
          'user_id': _currentUserId(),
          'blood_bank_org_id': id,
        },
      );

      debugPrint("✅ Favorite remove response: ${response.message}");

      // Return a success model — Sprint 13a backend always 200s on
      // remove (the response.data carries `removed: bool` if the caller
      // wants to distinguish actual-delete from no-op).
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
