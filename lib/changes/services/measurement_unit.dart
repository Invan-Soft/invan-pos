import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import '../../utils/constants/constants.dart';
import '../../utils/helpers/helpers.dart';

class MeasurementUnitSer {
  static Future<HttpResult> mesunit() async {
    final token = Pref.getString(PrefKeys.token, 'not initialized');
    final headers = <String, String>{
      "timezone": "-300",
      "Authorization": "Bearer $token",
    };
    final result = await ApiProvider.getResponse(
      path: 'api/v1/measurement_unit?limit=10&page=1',
      headers: headers,//AppConstants.getHeaders()
    );
    return result;
  }
  
}
