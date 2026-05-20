import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/app_constants.dart';

class VatUnit {
  static Future<HttpResult> vatUnit() async {
    final result = await ApiProvider.getResponse(
      path: 'api/v1/vat?search=&limit=undefined&page=1',
      headers: AppConstants.getHeaders(),
    );
    return result;
  }
}
