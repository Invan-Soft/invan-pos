/*
    @author Suxrob Sattorov, 1/25/2025, 2:04 PM
*/

import '../../features/get_discounts/get_discounts.dart';
import '../../features/hive_repository/hive_boxes.dart';
import '../../utils/utils.dart';
import 'api/api_provider.dart';
import 'api/result_http_model.dart';
import 'app_constants.dart';

class DiscountService {
  static final box = HiveBoxes.getDiscounts();

  /// OrderingProvider4 bu callbackni o'rnatadi.
  /// Discountlar tozalanganda chaqiriladi.
  static void Function()? onDiscountsCleared;

  static Future<HttpResult> findDiscounts() async {
    final shopId = Pref.getString(PrefKeys.storeId, 'not initialized');
    final token = Pref.getString(PrefKeys.token, 'not initialized');
    final posId = Pref.getString(PrefKeys.activatedPosId, 'not initialized');
    final acceptService = Pref.getString(PrefKeys.acceptService, 'not initialized');
    // ignore: avoid_print
    print('=== DISCOUNT REQUEST ===');
    // ignore: avoid_print
    print('shop_ids (storeId):   $shopId');
    // ignore: avoid_print
    print('Authorization token:  $token');
    // ignore: avoid_print
    print('Accept-Id (posId):    $posId');
    // ignore: avoid_print
    print('Accept-Service:       $acceptService');
    // ignore: avoid_print
    print('========================');
    final url = 'api/v1/company_discounts_for_pos?shop_ids=$shopId';
    final response = await ApiProvider.getResponse(
      path: url,
      headers: AppConstants.getHeaders(),
    );
    return response;
  }


  static Future<String?> discounts() async {
    HttpResult httpResult = await DiscountService.findDiscounts();

    if (httpResult.isSuccess) {
      DiscountsResponse discountsResponse =
          DiscountsResponse.fromJson(httpResult.result);

      await box.clear();

      if (discountsResponse.data != null) {
        for (var discountItem in discountsResponse.data!) {
          await box.put(discountItem.id, discountItem);
        }
      }

      // Agar discountlar yo'q bo'lsa, OrderingProvider4 ga xabar ber
      if (box.isEmpty) {
        onDiscountsCleared?.call();
      }

      return null;
    } else {
      return httpResult.getError;
    }
  }

  static Future<void> createDiscount(DiscountItem discount) async {
    await box.put(discount.id, discount);
  }

  static Future<void> updateDiscount(DiscountItem discount) async {
    if (box.containsKey(discount.id)) {
      await box.put(discount.id, discount);
    }
  }

  static Future<void> deleteDiscount(String id) async {
    await box.delete(id);
  }
}
