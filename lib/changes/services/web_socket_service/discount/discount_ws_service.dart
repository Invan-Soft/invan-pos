// ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/product_price_edit_response.dart';
import 'package:invan2/changes/services/web_socket_service/urls/urls.dart';
import 'package:provider/provider.dart';

import '../../../../alice_service.dart';
import '../../../../features/features.dart';
import '../../../../features/get_discounts/get_discounts.dart';
import '../../../../features/get_products/singletons/items_singleton.dart';
import '../../../../features/hive_repository/hive_boxes.dart';
import '../../../../utils/constants/constants.dart';
import '../../../../utils/helpers/helpers.dart';
import '../../../models/product/item_model.dart';
import '../../api/result_http_model.dart';
import '../../get_items_service.dart';

class DiscountWsService {
  DiscountWsService._();

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
              "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=1000&offset=1&type=15,16,17&is_read=false&start_date=$startDate&end_date=$endDate"),
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));
await LogHelper.logRequest(method: "GET", path: "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=1000&offset=1&type=15,16,17&is_read=false&start_date=$startDate&end_date=$endDate", statusCode: response.statusCode,response: response.body);
    alice.onHttpResponse(response);
    if (kDebugMode) {
      print('☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️ - Discount Get - ☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️');
    }
    if (response.statusCode == 200) {
      if (jsonDecode(utf8.decode(response.bodyBytes))['notifications'] !=
          null) {
        List notification =
            jsonDecode(utf8.decode(response.bodyBytes))['notifications'];

        for (var ws in notification) {
          if (ws['id'] != null) {
            if (ws['type'] == 15) {
              DiscountItem discountItem = DiscountItem.fromJson(ws['data']);
              DiscountService.createDiscount(discountItem);
            }
            if (ws['type'] == 16) {
              DiscountItem discountItem = DiscountItem.fromJson(ws['data']);
              DiscountService.updateDiscount(discountItem);
            }
            if (ws['type'] == 17) {
              DiscountService.deleteDiscount(ws['data']['id']);
            }
          }
        }
      }
    }
  }
}
