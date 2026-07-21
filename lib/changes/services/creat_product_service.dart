import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/utils/utils.dart';

class CreatProductService {
  static void _debugLog({
    required String label,
    required String method,
    required String path,
    required Map<String, String> headers,
    dynamic body,
    required HttpResult result,
  }) {
    if (!kDebugMode) return;
    final curl =
        StringBuffer("curl -X $method '${ApiProvider.baseUrlINVAN2}$path'");
    headers.forEach((k, v) => curl.write(" \\\n  -H '$k: $v'"));
    if (body != null) curl.write(" \\\n  -d '$body'");
    debugPrint('=== $label REQUEST ===\n$curl', wrapWidth: 4096);
    debugPrint(
        '=== $label RESPONSE (status: ${result.statusCode}, '
        'isSuccess: ${result.isSuccess}) ===\n${result.result}\n=== END $label ===',
        wrapWidth: 4096);
  }

  static Future<HttpResult> skuGenerate() async {
    final headers = AppConstants.getHeaders();
    final body = jsonEncode(
        {"product_type_id": "8b0bf29c-58e8-4310-8bb1-a1b9771f9c47"});
    final result = await ApiProvider.postResponse(
      path: 'api/v1/sku_generate',
      headers: headers,
      body: body,
    );
    _debugLog(
      label: 'SKU GENERATE',
      method: 'POST',
      path: 'api/v1/sku_generate',
      headers: headers,
      body: body,
      result: result,
    );
    return result;
  }

  static Future<HttpResult> productCreate(dynamic data) async {
    final headers = AppConstants.getHeaders();
    final result = await ApiProvider.postResponse(
      path: 'api/v1/product',
      headers: headers,
      body: data,
    );
    _debugLog(
      label: 'PRODUCT CREATE',
      method: 'POST',
      path: 'api/v1/product',
      headers: headers,
      body: data,
      result: result,
    );
    return result;
  }

  static Future<HttpResult> productGet(String id) async {
    final headers = AppConstants.getHeaders();
    final result = await ApiProvider.getResponse(
      path: 'api/v1/product/$id',
      headers: headers,
    );
    _debugLog(
      label: 'PRODUCT GET',
      method: 'GET',
      path: 'api/v1/product/$id',
      headers: headers,
      result: result,
    );
    return result;
  }

  static Future<HttpResult> productOldGet(String sku) async {
    String shopId = Pref.getString(PrefKeys.storeId, "");
    final headers = AppConstants.getHeaders();
    final path =
        'api/v1/products?page=1&search=$sku&limit=10&active_for_sale=all&sort_by=&shop_ids=$shopId';
    final result = await ApiProvider.postResponse(
      path: path,
      headers: headers,
    );
    _debugLog(
      label: 'PRODUCTS SEARCH (old get)',
      method: 'POST',
      path: path,
      headers: headers,
      result: result,
    );
    return result;
  }
}
