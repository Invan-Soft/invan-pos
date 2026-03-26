import 'dart:convert';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/app_constants.dart';

class AuthenticationApi {
  static Future<HttpResult> sendPhoneNumber(
    String phoneNumber,
    String password,
  ) async {
    final headers = <String, String>{
      "timezone": "-300",
      "Vary": "Origin",
      "Strict-Transport-Security": "Strict-Transport-Security",
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*"
    };
    final body = jsonEncode({
      'phone_number': phoneNumber,
      "password": password,
    });
    HttpResult res = await ApiProvider.postResponse(
      path: 'auth/login',
      headers: headers,
      body: body,
    );
    return res;
  }

  static Future<HttpResult> getShop(String token) async {
    final headers = <String, String>{
      "timezone": "-300",
      "Authorization": "Bearer $token",
    };
    HttpResult res = await ApiProvider.getResponse(
      path: 'api/v1/user/get_shops',
      headers: headers,
    );
    return res;
  }
  static Future<HttpResult> sendVerificationCodee(
      String phoneNumber,

      String verificationCode,
  ) async {
    final headers = <String, String>{
      'Accept-Version': AppConstants.acceptVersion,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-User': 'employee',
      'Accept-EmptyShow': '0',
    };
    final body = jsonEncode(<String, dynamic>{
      'phone_number': phoneNumber,
      'sms_code': int.parse(verificationCode),
    });

    HttpResult httpResult = await ApiProvider.postResponse(
      path: "user/login/verify",
      headers: headers,
      body: body,
    );
    return httpResult;
  }
}
