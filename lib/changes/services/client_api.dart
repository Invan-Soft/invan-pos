import 'dart:convert';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class ClientApi {
  static Future<HttpResult> clientByCardIdd(
      {required String cardId,
      required bool isSpecialClient,
      required String where}) async {
    final token = Pref.getString(PrefKeys.token, "not initialized");

    final headers = {
      'Content-Type': 'application/json',
      'Accept-version': '1.0.0',
      'Accept-user': 'employee',
      'Authorization': "Bearer $token",
      'timezone': "-300"
    };

    if (cardId.startsWith('+998')) {
      cardId = cardId.substring(4);
    }

    final path =
        "api/v1/clients_by_pos?search=$cardId&limit=10&page=1&is_default=$isSpecialClient";
    final fullUrl = "${ApiProvider.baseUrlINVAN2}$path";
    final curlHeaders =
        headers.entries.map((e) => "  -H '${e.key}: ${e.value}'").join(" \\\n");
    print(
        "[ClientApi.clientByCardIdd] so'rov (where: $where):\ncurl '$fullUrl' \\\n$curlHeaders");

    HttpResult response = await ApiProvider.getResponse(
      // path: "clients/search",
      path: path,
      headers: headers,
    );

    print(
        "[ClientApi.clientByCardIdd] javob: statusCode=${response.statusCode}, isSuccess=${response.isSuccess}, result=${response.result}");

    return response;
  }

  static Future<HttpResult> createClientt(ClientModel client) async {
    final token = Pref.getString(PrefKeys.token, 'not initialized');
    final headers = {
      "Accept-Version": '2.0.0',
      'Content-Type': 'application/json',
      'Authorization': "Bearer $token",
      'timezone': '-300',
    };
    HttpResult response = await ApiProvider.postResponse(
      path: "api/v1/client",
      headers: headers,
      body: jsonEncode(client.toApi()),
    );
    return response;
  }

  static Future<HttpResult> getClientGroup() async {
    final token = Pref.getString(PrefKeys.token, 'not initialized');
    final headers = {
      "Accept-Version": '2.0.0',
      'Content-Type': 'application/json',
      'Authorization': "Bearer $token",
      'timezone': '-300',
    };
    HttpResult response = await ApiProvider.getResponse(
        path: "api/v1/customer_group", headers: headers);
    return response;
  }
}
