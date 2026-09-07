// ONKM (markirovka kodini tekshirish) so'rovi — tasnif.soliq.uz.
//
// Markirovkali tovar skanerlanganda KM haqiqiyligini soliq xizmatida
// tekshiradi. So'rov TANASI biznes uchun muhim: `kmIds`, `commitentTin`,
// `productCode` (MXIK) va `packageCode` noto'g'ri ketsa tekshiruv rad
// javob beradi va kassir tovarni sota olmaydi.
//
// `OrderingProvider4._markingCheck` dan ajratildi (Faza 9.5) — tana
// o'zgarmagan. So'rov tanasini yasash sof funksiya, shuning uchun
// to'g'ridan-to'g'ri testlanadi (ilgari tarmoq chaqiruvi ichida edi).

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';

class OnkmValidator {
  const OnkmValidator._();

  static const String endpoint =
      'https://tasnif.soliq.uz/api/cl-api/marking/validation-onkm';

  static const Map<String, String> headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Basic cmVhY3RNYXJraW5nVXNlcjpkM0BUNypacEwhYU4kOW1R'
  };

  /// ONKM so'rovining tanasi. Sof funksiya — testlanadi.
  ///
  /// [ownerTin] — do'kon INN si, [km] — skanerlangan markirovka kodi.
  static Map<String, dynamic> buildBody({
    required String ownerTin,
    required String km,
    required ItemModel item,
  }) {
    return {
      "ownerTin": ownerTin,
      "refund": 0,
      "products": [
        {
          "kmIds": [km],
          "commitentTin": item.commissionTin,
          "productCode": item.mxikCode,
          "packageCode": item.packageCode,
          "amount": 1
        }
      ]
    };
  }

  /// Javobni `HttpResult` ga o'giradi.
  ///
  /// Faqat 200 muvaffaqiyat hisoblanadi; qolgan kodlarda `isSuccess` false
  /// bo'lib, `statusCode` 1 bo'lib qoladi — chaqiruvchi 500 ni alohida
  /// (`response.statusCode` orqali) ko'radi.
  static HttpResult toResult(http.Response response) {
    if (response.statusCode == 200) {
      return HttpResult(
        statusCode: response.statusCode,
        isSuccess: true,
        result: jsonDecode(utf8.decode(response.bodyBytes)),
        reBytes: null,
      );
    }
    return HttpResult(
        statusCode: 1, isSuccess: false, result: null, reBytes: null);
  }

  /// KM ni ONKM da tekshiradi.
  ///
  /// [onResponse] — tarmoq debuggeri (Alice) uchun; ixtiyoriy.
  /// So'rov timeouti.
  ///
  /// Ilgari timeout umuman yo'q edi: soliq xizmati javob bermay qo'ysa
  /// (ulanish ochiq, javob yo'q) Future hech qachon tugamasdi va kassir
  /// markirovkali tovarni skanerlaganda `isLoading` holatida abadiy muzlab
  /// qolardi — chiqish yo'li yo'q edi. 10 soniya: bu kassirni kutdiradigan
  /// jonli yo'l, undan uzog'i savdo nuqtasida qabul qilib bo'lmaydi.
  static const Duration timeout = Duration(seconds: 10);

  static Future<http.Response> validate({
    required ItemModel item,
    required String km,
    required String ownerTin,
    void Function(http.Response response)? onResponse,
  }) async {
    final response = await http
        .post(
          Uri.parse(endpoint),
          body: jsonEncode(buildBody(ownerTin: ownerTin, km: km, item: item)),
          headers: headers,
        )
        .timeout(timeout);
    onResponse?.call(response);
    return response;
  }
}
