import 'package:eblood_bank_mak_app/stock_management/business/model/recherche/DatumRecherchePocheModel.dart';
import 'package:flutter/foundation.dart';
import '../../../business/service/recherche/RechercheListeNetworkService.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';

class RechercheListeNetworkServiceImpl implements RechercheListeNetworkService {
  String baseURL;

  RechercheListeNetworkServiceImpl(this.baseURL);

  @override
  Future<List<DatumRecherchePocheModel>> recuperationRechercheListeBanque(String searchKey, String authBearer) async {
    try {
      debugPrint('🔍 Searching blood bags with keyword: "$searchKey"');

      // Call the new backend endpoint using DioClient
      final response = await getWithDio(
        '/eblood-connect/blood-bags/search-simple',
        queryParams: {
          'search_key': searchKey,
          'page': 0,
          'limit': 50,
        },
      );

      debugPrint("📡 Search API response: ${response.message}");

      if (!response.success) {
        debugPrint("⚠️ Failed to search blood bags: ${response.message}");
        return <DatumRecherchePocheModel>[];
      }

      // Parse the response data
      final dynamic responseData = response.data;
      List<dynamic> items = <dynamic>[];

      if (responseData is List) {
        // Direct list response
        items = responseData;
      } else if (responseData is Map) {
        // Check for data key
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            items = data;
          }
        }
      }

      debugPrint("📊 Found ${items.length} blood bags");

      if (items.isEmpty) {
        debugPrint("⚠️ No blood bags found for search: $searchKey");
        return <DatumRecherchePocheModel>[];
      }

      // Parse items into DatumRecherchePocheModel
      final responseFinal = <DatumRecherchePocheModel>[];
      for (int i = 0; i < items.length; i++) {
        try {
          if (items[i] is Map) {
            final item = DatumRecherchePocheModel.fromJson(items[i] as Map<String, dynamic>);
            responseFinal.add(item);
          }
        } catch (e) {
          debugPrint("⚠️ Error parsing blood bag $i: $e");
          debugPrint("⚠️ Problematic data: ${items[i]}");
        }
      }

      debugPrint("✅ Successfully parsed ${responseFinal.length} blood bags");

      return responseFinal;
    } catch (e) {
      debugPrint("❌ Error searching blood bags: $e");
      return <DatumRecherchePocheModel>[];
    }
  }
}
