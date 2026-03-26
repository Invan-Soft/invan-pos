import 'package:intl/intl.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class SearchReceiptService {
  static Future<HttpResult> getReceiptss(String receiptNo) async {
    String token = Pref.getString(PrefKeys.token, "not initialized");
    String acceptId =
        Pref.getString(PrefKeys.activatedPosId, "not initialized");

    var headers = {
      'Accept-version': '1.0.0',
      'Accept-user': 'employee',
      'timezone': '-300',
      'Authorization': "Bearer $token",
      'Accept-id': acceptId,
    };

    HttpResult httpResult = await ApiProvider.getResponse(
        path: "api/v1/order?search=$receiptNo&limit=30&page=1",
        headers: headers);
    return httpResult;
  }
}
