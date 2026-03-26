
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';

class CompanyAppsService{
  static Future<HttpResult> getCompanyApps(String token)async{
    final headers = <String, String>{
      "timezone": "-300",
      "Authorization": "Bearer $token",
    };
    final result = ApiProvider.getResponse(path: 'api/v1/company_apps', headers: headers);
    return result;
  }

}