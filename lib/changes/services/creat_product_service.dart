import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/utils/utils.dart';

class CreatProductService {
  static Future<HttpResult> skuGenerate() async {
    final result = await ApiProvider.postResponse(
      path: 'api/v1/sku_generate',
      headers: AppConstants.getHeaders(),
    );
    return result;
  }

  static Future<HttpResult> productCreate(dynamic data) async {
    final result = await ApiProvider.postResponse(
      path: 'api/v1/product',
      headers: AppConstants.getHeaders(),
      body: data,
    );
    return result;
  }

  static Future<HttpResult> productGet(String id) async {
    final result = await ApiProvider.getResponse(
      path: 'api/v1/product/$id',
      headers: AppConstants.getHeaders(),
    );
    return result;
  }

  static Future<HttpResult> productOldGet(String sku) async {
    String shopId = Pref.getString(PrefKeys.storeId, "");
    final result = await ApiProvider.postResponse(
      path:
          'api/v1/products?page=1&search=$sku&limit=10&active_for_sale=all&sort_by=&shop_ids=$shopId',
      headers: AppConstants.getHeaders(),
    );
    return result;
  }
}
