import 'package:eblood_bank_mak_app/apps/services/AuthApi.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/Authentification.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';
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
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurNetworkService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../utilisateurs/business/models/notification/SuppressionDatumNotificationModel.dart';

/// A new implementation of the UtilisateurNetworkService interface
/// that delegates core authentication functionality to AuthApi
class AuthApiAdapter implements UtilisateurNetworkService {
  final AuthApi _authApi = AuthApi.instance;
  final GetStorage _storage = GetStorage();
  final String baseURL;

  AuthApiAdapter(String initialBaseURL) 
      : baseURL = dotenv.env['BASE_URL'] ?? initialBaseURL {
    print("🔧 AuthApiAdapter initialized with baseURL: $baseURL");
  }

  @override
  Future<AuthentificationModel?> login(AuthenticateRequestBody data) async {
    try {
      final result = await _authApi.login(
        email: data.username,
        password: data.password,
      );

      if (result['success'] == true) {
        if (result['requiresMfa'] == true) {
          // MFA is required, return the temporary token
          return AuthentificationModel(
            token: _storage.read('mfa_access_token') ?? '',
            datetime: DateTime.now(),
            email: data.username,
          );
        } else {
          // No MFA required or MFA already completed
          return AuthentificationModel(
            token: _storage.read('auth_token') ?? '',
            datetime: DateTime.now(),
            email: data.username,
          );
        }
      } else {
        print("💥 Login failed: ${result['message']}");
        throw Exception(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      print("💥 Login error: $e");
      rethrow;
    }
  }

  @override
  Future<List<String>> recuperationNomUtilisateur(String name) async {
    // This method doesn't exist in AuthApi, so we'll implement it directly
    try {
      var res = await http
          .post(Uri.parse("$baseURL/api/getnameuser"), body: {"name": name});
      
      if (res.statusCode != 200) {
        return [];
      }
      
      List<dynamic> decodedResponse = json.decode(res.body) as List<dynamic>;
      List<String> nameList =
          decodedResponse.map((item) => item.toString()).toList();
      return nameList;
    } catch (e) {
      print("💥 Error in recuperationNomUtilisateur: $e");
      return [];
    }
  }

  @override
  Future<AuthentificationModel?> recuperationUtilisateur(String token) async {
    // This retrieves the user's authentication information
    try {
      var res = await http.get(Uri.parse("$baseURL/api/getuser"),
          headers: {"Authorization": "Bearer $token"});

      if (res.statusCode != 200) {
        return null;
      }

      var responseMap = json.decode(res.body) as Map<dynamic, dynamic>;
      var responseFinal = AuthentificationModel.fromJson(responseMap.cast<String, dynamic>());
      return responseFinal;
    } catch (e) {
      print("💥 Error in recuperationUtilisateur: $e");
      return null;
    }
  }

  @override
  Future<DatumCodeOtpModele?> recuperationUtilisateurOtp(String token) async {
    // Use the new getUserProfile method from AuthApi
    try {
      return await _authApi.getUserProfile();
    } catch (e) {
      print("💥 Error in recuperationUtilisateurOtp: $e");
      return null;
    }
  }

  @override
  Future<DatumCodeOtpModele?> verifyOtp(OtpModele data, String token) async {
    try {
      final String mfaType = _storage.read('mfa_type') ?? 'email';
      
      final result = await _authApi.validateOtp(
        otpCode: data.code,
        mfaType: mfaType,
      );
      
      if (result['success'] == true) {
        // After successful OTP validation, fetch user profile
        return await _authApi.getUserProfile();
      } else {
        throw Exception(result['message'] ?? 'OTP validation failed');
      }
    } catch (e) {
      print("💥 OTP verification error: $e");
      rethrow;
    }
  }

  @override
  Future<String> renvoiCode(String token) async {
    try {
      final String mfaType = _storage.read('mfa_type') ?? 'email';
      
      final result = await _authApi.resendOtp(mfaType: mfaType);
      
      if (result['success'] == true) {
        return result['message'] ?? 'OTP resent successfully';
      } else {
        return result['message'] ?? 'Failed to resend OTP';
      }
    } catch (e) {
      print("💥 OTP resend error: $e");
      return "Error: $e";
    }
  }

  @override
  Future<bool> deconnexion(String? token) async {
    return await _authApi.logout();
  }

  // Methods below still use the original implementation since they're not covered by AuthApi

  @override
  Future<OtpCodeReinitialiserModele?> verifyOtpPassword(
      OtpReinitialiserModele data, String token) async {
    try {
      var res = await http.post(Uri.parse("$baseURL/auth/check-otp-existance"),
          body: data.toJson(),
          headers: {
            "Authorization": "Bearer $token",
            "eblood-lockkeys":
                "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
          });
      
      if (res.statusCode != 200) {
        return null;
      }
      
      var reponseMap = json.decode(res.body);
      var reponseFinal = OtpCodeReinitialiserModele.fromJson(reponseMap);
      return reponseFinal;
    } catch (e) {
      print("💥 Error in verifyOtpPassword: $e");
      return null;
    }
  }

  @override
  Future<PasswordChangerModel?> changerPassword(
      ChangerPasswordModel data, String token) async {
    try {
      var res = await http.post(
        Uri.parse("$baseURL/data/users/reset-password"),
        body: json.encode(data.toJson()),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "eblood-lockkeys":
              "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
        },
      );

      if (res.statusCode != 200) {
        return null;
      }
      
      var responseMap = json.decode(res.body) as Map;
      
      if (responseMap['data'] != null) {
        return PasswordChangerModel.fromJson(responseMap['data']);
      } else {
        return null;
      }
    } catch (e) {
      print("💥 Error in changerPassword: $e");
      return null;
    }
  }

  @override
  Future<String> renvoiCodePassword(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseURL/auth/resent-otp"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "eblood-lockkeys":
              "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
        },
      );
      
      if (res.statusCode != 200) {
        return "Failed to resend code: ${res.statusCode}";
      }
      
      return res.body;
    } catch (e) {
      print("💥 Error in renvoiCodePassword: $e");
      return "Error: $e";
    }
  }

  @override
  Future<MotDePasseModele?> reinitialiserPassword(MotDePasseOublieModele data) async {
    try {
      var res = await http.post(Uri.parse("$baseURL/auth/c-username"),
          body: data.toJson(),
          headers: {
            "eblood-lockkeys":
                "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
          });
      
      if (res.statusCode != 200) {
        return null;
      }
      
      var reponseMap = json.decode(res.body) as Map;
      var reponseFinal = MotDePasseModele.fromJson(reponseMap['data']);
      return reponseFinal;
    } catch (e) {
      print("💥 Error in reinitialiserPassword: $e");
      return null;
    }
  }

  @override
  Future<ReinitialiserModele?> passwordReinitialiser(
      ReinitialiserPasswordModele data, String token) async {
    try {
      var response = await http.post(
        Uri.parse("$baseURL/auth/initiate-password"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "eblood-lockkeys":
              "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
        },
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode != 200) {
        return null;
      }
      
      var responseMap = json.decode(response.body) as Map<String, dynamic>;
      var responseFinal = ReinitialiserModele.fromJson(responseMap);
      return responseFinal;
    } catch (e) {
      print("💥 Error in passwordReinitialiser: $e");
      return null;
    }
  }

  @override
  Future<PasswordChangerModel?> passwordChanger(ChangerPasswordModel data) async {
    // Get token from storage
    final token = _storage.read('auth_token');
    if (token == null) {
      return null;
    }
    // Call the method to change the password
    return await changerPassword(data, token);
  }

  @override
  Future<List<DatumNotificationModel>?> recuperationNotification(String authBarear) async {
    try {
      var res = await http
          .get(Uri.parse("$baseURL/data/notifications?page=0"), headers: {
        "Authorization": "Bearer $authBarear",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      });
      
      if (res.statusCode != 200) {
        return [];
      }
      
      var reponseMap = json.decode(res.body) as Map;
      var data = reponseMap['data'] as List;
      var responseFinal =
          data.map((e) => DatumNotificationModel.fromJson(e)).toList();
      return responseFinal;
    } catch (e) {
      print("💥 Error in recuperationNotification: $e");
      return [];
    }
  }

  @override
  Future<SuppressionDatumNotificationModel> suppressionNotification(
      String _id, String authBarear) async {
    try {
      final res = await http
          .delete(Uri.parse("$baseURL/data/notifications/$_id"), headers: {
        "Authorization": "Bearer $authBarear",
        "Content-Type": "application/json",
        "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
      });
      
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception('Failed to delete notification: ${res.statusCode}');
      }
      
      return suppresionDatumNotificationModelFromJson(res.body);
    } catch (e) {
      print("💥 Error in suppressionNotification: $e");
      throw Exception('Error during notification deletion: $e');
    }
  }
}