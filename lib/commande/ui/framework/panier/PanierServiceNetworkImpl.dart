import 'dart:convert';
import 'dart:io';
import 'package:eblood_bank_mak_app/commande/business/model/PanierModel.dart';
import 'package:eblood_bank_mak_app/commande/business/model/PanierReponseModel.dart';
import 'package:eblood_bank_mak_app/commande/business/model/RecupererPanierResponseModel.dart';
import 'package:flutter/foundation.dart';
import '../../../business/model/panier/SuppressionPanierResponseModel.dart';
import '../../../business/service/panier/PanierNetworkService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../apps/config/api/dio_client.dart';

class PanierServiceNetworkImpl implements PanierNetworkService {
  String baseURL;

  PanierServiceNetworkImpl(this.baseURL);

  @override
  Future<PanierReponseModel?> ajouterPanier(
      PanierModel data, String authBearer) async {
    try {
      debugPrint("📤 Adding to cart: blood_bag_id=${data.blood_bag_id}, quantity=${data.quantity}");
      debugPrint("   Full PanierModel payload: ${data.toJson()}");
      debugPrint("   Auth bearer present: ${authBearer.isNotEmpty}");

      final response = await postWithDio(
        '/eblood-connect/cart/add',
        body: {
          'blood_bank_id': data.blood_bank_id,
          'blood_bag_id': data.blood_bag_id,
          'quantity': data.quantity,
        },
      );

      // Check if the response was successful
      if (response.success != true) {
        debugPrint("❌ Backend returned error: ${response.message}");
        throw Exception(response.message ?? 'Erreur lors de l\'ajout au panier');
      }

      debugPrint("✅ Added to cart successfully");
  debugPrint("   Backend response: success=${response.success}, statusCode=${response.statusCode}, message=${response.message}");
  debugPrint("   Backend raw data: ${response.data}");

      // Create response model from top-level response fields
      var responseFinal = PanierReponseModel(
        sms: response.message ?? 'Item added to cart successfully',
        statusCode: response.statusCode ?? 200,
        success: response.success,
      );
      return responseFinal;
    } catch (e) {
      debugPrint("❌ Error adding to cart: $e");
      throw Exception('Erreur lors de l\'ajout au panier : $e');
    }
  }

  @override
  Future<RecupererPanierResponseModel> recuperationListePanier(
      String authBearer) async {
    try {
      debugPrint("📥 Fetching cart");

      final response = await getWithDio(
        '/eblood-connect/cart',
      );

      debugPrint("✅ Cart response: ${response.message}");

      // Extract cart object from response.data
      var cartData = response.data as Map<String, dynamic>? ?? {};

      // Extract cart_items array from cart object
      var cartItems = cartData['cart_items'] as List<dynamic>? ?? [];

      // Extract currency from backend response (defaults to CDF if not provided)
      String currencyCode = cartData['currency_code']?.toString() ?? 'CDF';
      String currencySymbol = cartData['currency_symbol']?.toString() ?? 'CDF';

      String refCurrencyId = cartData['ref_currency_id']?.toString() ?? '';
      debugPrint("\ud83d\udd0e Cart ref_currency_id from backend: '$refCurrencyId'");

      debugPrint("📦 Cart has ${cartItems.length} items");
      debugPrint("💰 Currency: $currencyCode ($currencySymbol)");

      // Transform each cart item to match CartItemPanierModel structure
      var transformedCartItems = cartItems.map((item) {
        // Transform blood_bag_info to match BloodBagInfoPanierModel
        var bloodBagInfo = item['blood_bag_info'] as Map<String, dynamic>? ?? {};
        var transformedBloodBagInfo = {
          '_id': bloodBagInfo['identifier'] ?? '',
          'is_activated': true,
          'identifier': bloodBagInfo['identifier'] ?? '',
          'createdAt': DateTime.now().toIso8601String(),
          'blood_type_id': '',
          'blood_rhesus_id': '',
          'blood_volume_id': '',
          'blood_type_info': {},
          'blood_rhesus_info': {},
          'blood_volume_info': {},
        };

        // Transform blood_bank_info to match BloodBankInfoPanierModel
        var bloodBankInfo = item['blood_bank_info'] as Map<String, dynamic>? ?? {};
        var transformedBloodBankInfo = {
          '_id': bloodBankInfo['blood_bank_id']?.toString() ?? '',
          'identifier': bloodBankInfo['blood_bank_id']?.toString() ?? '',
          'blood_bank_name': bloodBankInfo['name'] ?? '',
          'blood_bank_logo': '',
          'town_info': {
            '_id': '',
            'identifier': '',
            'town_name': bloodBankInfo['location'] ?? '',
            'createdAt': DateTime.now().toIso8601String(),
          },
          'longitude': bloodBankInfo['longitude']?.toString() ?? '',  // Convert double to string
          'latitude': bloodBankInfo['latitude']?.toString() ?? '',    // Convert double to string
          'createdAt': DateTime.now().toIso8601String(),
        };

        return {
          '_id': item['cart_item_id']?.toString() ?? '',
          'currency_id': '',  // Not provided by backend
          'blood_bag_id': item['blood_bag_id']?.toString() ?? '',
          'blood_bank_id': item['blood_bank_id']?.toString() ?? '',
          'price': (item['unit_price'] ?? 0).toInt(),
          'quantity': item['quantity'] ?? 0,
          'currency': currencyCode,  // Use currency from backend
          'blood_bag_info': transformedBloodBagInfo,
          'blood_bank_info': transformedBloodBankInfo,
        };
      }).toList();

      // Transform cart object to match DatumModel structure
      var transformedCart = {
        '_id': cartData['id']?.toString() ?? '',
        'identifier': cartData['identifier'] ?? '',
        'createdAt': cartData['created_at'] ?? DateTime.now().toIso8601String(),
        'cart_items': transformedCartItems,
        'currency': currencyCode,  // Use currency from backend
        'ref_currency_id': refCurrencyId,

        'total_cart_blood_bags': cartItems.length,
        'total_price': cartItems.fold<double>(0, (sum, item) => sum + (item['total_price'] ?? 0)).toInt(),
        'total_fees': cartData['total_fees']?.toDouble() ?? 0.0,  // Get from backend
      };

      // Transform to match RecupererPanierResponseModel structure
      // RecupererPanierResponseModel expects data to be a list of carts
      var transformedResponse = {
        'status_code': response.statusCode ?? 200,
        'success': response.success,
        'perpage': 1,  // We have 1 cart
        'max': 1,
        'data': [transformedCart],  // Wrap cart in array
      };

      var responseFinal = RecupererPanierResponseModel.fromJson(transformedResponse);

      return responseFinal;
    } catch (e) {
      debugPrint("❌ Error fetching cart: $e");
      throw Exception('Erreur lors de la récupération du panier : $e');
    }
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
      String cartId, String cartItemId, String authBearer) async {
    try {
      debugPrint("🗑️ [NETWORK] Removing from cart:");
      debugPrint("   cartId type: ${cartId.runtimeType}, value: '$cartId'");
      debugPrint("   cartItemId type: ${cartItemId.runtimeType}, value: '$cartItemId'");
      debugPrint("   cartId isEmpty: ${cartId.isEmpty}");
      debugPrint("   cartItemId isEmpty: ${cartItemId.isEmpty}");

      final queryParams = {
        'cart_id': cartId,
        'cart_item_id': cartItemId,
      };
      debugPrint("   queryParams: $queryParams");

      final response = await deleteWithDio(
        '/eblood-connect/cart/remove',
        queryParams: queryParams,
      );

      // Check if the response was successful
      if (response.success != true) {
        debugPrint("❌ Backend returned error: ${response.message}");
        throw Exception(response.message ?? 'Erreur lors de la suppression');
      }

      debugPrint("✅ Removed from cart successfully");

      // Create response model from top-level response fields (not from response.data)
      return SuppressionPanierResponseModel(
        sms: response.message ?? 'Item removed from cart successfully',
        statusCode: response.statusCode ?? 200,
        success: response.success,
      );
    } catch (e) {
      debugPrint("❌ Error removing from cart: $e");
      throw Exception('Erreur lors de la suppression : $e');
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
