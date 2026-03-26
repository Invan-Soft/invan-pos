import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class OrganizationService {
  static Future<HttpResult> getOrganization() async {
    String token = Pref.getString(PrefKeys.token, "not initialized");
    var headers = {
      "timezone": "-300",
      "Authorization": "Bearer $token",
    };
    HttpResult httpResult = await ApiProvider.getResponse(
        path: "api/v1/current_company", headers: headers);

    return httpResult;
  }

  static Future<HttpResult> getPayments(String posId) async {
    String token = Pref.getString(PrefKeys.token, "not initialized");
    var headers = {
      "timezone": "-300",
      "Authorization": "Bearer $token",
    };
    HttpResult httpResult = await ApiProvider.getResponse(
        path: "api/v1/cashbox/$posId", headers: headers);
    return httpResult;
  }

  static Future<HttpResult> getStoreFields(String storeId) async {
    String token = Pref.getString(PrefKeys.token, "not initialized");
    var headers = {
      "timezone": "-300",
      "Authorization": "Bearer $token",
    };
    HttpResult httpResult = await ApiProvider.getResponse(
        path: "api/v1/shop/$storeId", headers: headers);
    return httpResult;
  }
}
