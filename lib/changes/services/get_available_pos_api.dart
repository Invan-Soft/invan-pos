import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';

class GetAvailablePosApi {
  static Future<HttpResult> getAvailablePoss({required String token}) async {
    final headers = <String, String>{
      'Accept-Version': '1.0.0',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-User': 'employee',
      'Accept-EmptyShow': '0',
      "timezone": "-300",
      "Authorization": "Bearer $token"
    };

    final response = await ApiProvider.getResponse(
      path: 'api/v1/cashbox',
      headers: headers,
    );
    return response;
  }
}
