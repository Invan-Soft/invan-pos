// ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../alice_service.dart';
import '../../../../features/features.dart';
import '../../../../features/get_products/singletons/items_singleton.dart';
import '../../../../utils/constants/constants.dart';
import '../../../../utils/helpers/helpers.dart';
import '../../log_helper.dart';
import '../urls/urls.dart';

class CategoriesWsService {
  CategoriesWsService._();

  static Future<void> getReceivedWS(bool mounted, BuildContext context,
      String startDate, String endDate) async {
    final token = Pref.getString(PrefKeys.token, 'not initialized');

    if (token.isEmpty || token == 'not initialized') {
      return;
    }

    String comId = Pref.getString(PrefKeys.orgID, "");
    final headers = <String, String>{
      "timezone": "-300",
      "Vary": "Origin",
      "Strict-Transport-Security": "Strict-Transport-Security",
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Authorization": "Bearer $token"
    };
    http.Response response = await http
        .get(
          Uri.parse(
              "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=1000&offset=1&type=10,11,12&is_read=false&start_date=$startDate&end_date=$endDate"),
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));
    await LogHelper.logRequest(method: "GET", path: "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=1000&offset=1&type=10,11,12&is_read=false&start_date=$startDate&end_date=$endDate" , statusCode: response.statusCode,response: response.body);

    alice.onHttpResponse(response);
    if (kDebugMode) {
      print('☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️ - Category Get - ☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️');
    }
    if (response.statusCode == 200) {
      if (jsonDecode(utf8.decode(response.bodyBytes))['notifications'] !=
          null) {
        List<String> deleteIds = [];
        List notification =
            jsonDecode(utf8.decode(response.bodyBytes))['notifications'];

        for (var ws in notification) {
          if (ws['id'] != null) {
            if (ws['type'] == 10) {
              CategoryData categoryData = CategoryData.fromJson(ws['data']);
              await CategorySingleton.putCategories([categoryData]);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 11) {
              CategoryData? categoryData = CategoryData.fromJson(ws['data']);
              await CategorySingleton.editCategory(categoryData);
              CategorySingleton.init();
              await ItemsSingleton.storeProducts();
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 12) {
              await CategorySingleton.deleteCategories(ws['data']['id']);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
              deleteIds.add(ws['id']);
            }
          }
        }
        if (deleteIds.isNotEmpty) {
          // await sendReceivedWS(deleteIds);
          deleteIds = [];
        }
      }
    }
  }
}
