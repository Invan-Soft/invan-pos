/*
    @author Suxrob Sattorov, 2/11/2025, 9:11 PM
*/

import 'dart:convert';

import '../../../alice_service.dart';
import 'package:http/http.dart' as http;

import '../../../changes/services/log_helper.dart';
import '../../../utils/utils.dart';
import 'tasnif_response_model.dart';

class TasnifService {
  static Future<Map<String, dynamic>?> getPackageCodes() async {
    String url =
        'https://tasnif.soliq.uz/api/cl-api/integration-mxik/get/information?mxikCode=${Pref.getString(PrefKeys.mxikCode, '')}';
    try {
      http.Response response = await http.get(Uri.parse(url));
      await LogHelper.logRequest(method: "Get", path: url, statusCode: response.statusCode,response: response.body);

      alice?.onHttpResponse(response);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<void> setPackageCode() async {
    Map<String, dynamic>? httpResult = await getPackageCodes();
    if (httpResult != null) {
      TasnifResponseModel tasnifResponseModel =
          TasnifResponseModel.fromJson(httpResult);
      if (tasnifResponseModel.data != null &&
          tasnifResponseModel.data!.isNotEmpty &&
          tasnifResponseModel.data![0].packages != null) {
        for (Packages packages in tasnifResponseModel.data![0].packages!) {
          if (packages.nameLat == 'dona') {
            await Pref.setString(
                PrefKeys.packageCode, packages.code?.toString() ?? '');
          }
        }
      }
    }
  }
}
