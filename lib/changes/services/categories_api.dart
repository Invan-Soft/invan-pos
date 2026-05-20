import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/app_constants.dart';

class CategoriesApi {
  static Future<HttpResult> categoryFind() async {
    final result = await ApiProvider.getResponse(
      path: 'api/v1/category_for_product?limit=500&page=1',
      headers: AppConstants.getHeaders(),
    );
    return result;
  }
}
