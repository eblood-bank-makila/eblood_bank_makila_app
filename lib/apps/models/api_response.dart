import 'package:eblood_bank_mak_app/apps/models/auth_model.dart';
import 'package:eblood_bank_mak_app/apps/models/user_model.dart';
import 'package:flutter/material.dart';
// import 'package:ebloodbankauth/model/auth_model.dart';
// import 'package:ebloodbankauth/model/user_model.dart';

class IApiResponse {
  final bool success;
  final bool? redirectToMfa;
  final String? message;
  final dynamic data;
  final String? accessToken;
  final String? refreshToken;
  final TMfaModel? defaultMfa;
  final TUserModel? user;
  final String? username;
  final List<TMfaModel>? mfas;
  final int? max;
  final int? limit;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  IApiResponse({
    required this.success,
    this.message,
    this.redirectToMfa,
    this.data,
    this.statusCode,
    this.meta,
    this.accessToken,
    this.refreshToken,
    this.defaultMfa,
    this.username,
    this.user,
    this.mfas,
    this.max,
    this.limit,
  });

  factory IApiResponse.fromData(dynamic responseData) {
    // debugPrint("---> \n\n\n ${responseData} ---\n\n\n",
    //     wrapWidth: 1024);
    if (responseData is Map<String, dynamic>) {
      List<TMfaModel> modelList = [];
      if (responseData.containsKey('mfas') && responseData['mfas'] != null) {
        //  debugPrint(
        //     "---> \n\n\n LOOP MFA ${responseData['mfas']} ---\n\n\n",
        //   );
        for (var mfa in responseData['mfas']) {
          // debugPrint(
          //   "---> \n\n\n LOOP MFA ELEM :  ${mfa} ---\n\n\n",
          // );
          debugPrint("---> \n\n\n LOOP MFA TYPE ${mfa.runtimeType} ---\n\n\n",
              wrapWidth: 1024);
          if (mfa != null) {
            modelList.add(TMfaModel.fromJson(mfa));
          }
        }
      }
      return IApiResponse(
        success: responseData.containsKey('success') &&
                responseData['success'] != null
            ? responseData['success'] == true
            : (responseData.containsKey('status_code') &&
                    responseData['status_code'] != null
                ? responseData['status_code'] >= 200 &&
                        responseData['status_code'] < 300
                    ? true
                    : false
                : false),
        message: responseData.containsKey('message') &&
                responseData['message'] != null
            ? responseData['message']
            : '',
        data: responseData.containsKey('data') && responseData['data'] != null
            ? responseData['data']
            : null,
        statusCode: responseData.containsKey('status_code') &&
                responseData['status_code'] != null
            ? responseData['status_code']
            : (responseData.containsKey('success') &&
                    responseData['success'] == true
                ? 200
                : 0),
        max: responseData.containsKey('max') && responseData['max'] != null
            ? responseData['max']
            : 0,
        limit:
            responseData.containsKey('limit') && responseData['limit'] != null
                ? responseData['limit']
                : 0,
        accessToken: responseData.containsKey('access_token') &&
                responseData['access_token'] != null
            ? responseData['access_token']
            : "",
        refreshToken: responseData.containsKey('refresh_token') &&
                responseData['refresh_token'] != null
            ? responseData['refresh_token']
            : "",
        username: responseData.containsKey('username') &&
                responseData['username'] != null
            ? responseData['username']
            : "",
        redirectToMfa: responseData.containsKey('redirect_to_mfa') &&
                responseData['redirect_to_mfa'] != null
            ? responseData['redirect_to_mfa']
            : false,
        defaultMfa: responseData.containsKey('default_mfa') &&
                responseData['default_mfa'] != null
            ? tMfaModelFromJson(responseData['default_mfa'])
            : TMfaModel.empty(),
        user: responseData.containsKey('user') && responseData['user'] != null
            ? tUserModelFromJson(responseData['user'])
            : TUserModel.empty(),
        mfas: modelList,
      );
    }

    // If response is not a map, create a default response
    return IApiResponse(
      success: false,
      data: responseData,
    );
  }

  factory IApiResponse.error(String message, {int? statusCode}) {
    return IApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  @override
  String toString() => '''
    {
      "success": $success,
      "message": "$message",
      "redirectToMfa": $redirectToMfa,
      "data": $data,
      "statusCode": $statusCode,
      "meta": $meta,
      "accessToken": "$accessToken",
      "refreshToken": "$refreshToken",
      "defaultMfa": $defaultMfa,
      "username": "$username",
      "mfas": $mfas,
      "max": $max,
      "limit": $limit
    }
  ''';
}
