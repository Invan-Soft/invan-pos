import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/app_constants.dart';

class ServiceGetApi {
  static Future<HttpResult> serviceGet(String posId) async {
    // String acceptService =
    //     Pref.getString(PrefKeys.acceptService, 'not initialized');
    // final uri = 'service/get/$acceptService';
  
    var uri = 'api/v1/cheque/$posId';
    HttpResult httpResult = await ApiProvider.getResponse(
        path: uri, headers: AppConstants.getHeaders());
   
    return httpResult;
  }
}
