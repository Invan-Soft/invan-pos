import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/utils/constants/constants.dart';

import '../../utils/helpers/prefs.dart';

class SupplierApi {
  static Future<HttpResult> searchSuppliers({
    required String search,
    int limit = 10,
    int page = 1,
  }) async {
    final token = Pref.getString(PrefKeys.token, "not initialized");

    final headers = {
      'Content-Type': 'application/json',
      'Accept-version': '1.0.0',
      'Accept-user': 'employee',
      'Authorization': "Bearer $token",
      'timezone': "-300",
    };

    HttpResult response = await ApiProvider.postResponse(
      path: "api/v1/suppliers?search=$search&limit=$limit&page=$page",
      headers: headers,
    );

    return response;
  }
}