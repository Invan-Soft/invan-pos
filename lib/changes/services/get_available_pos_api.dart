import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/shift_api_4.dart';

class GetAvailablePosApi {
  /// Smenasi ochiq (server tomonda) kassalarning cashbox_id to'plamini qaytaradi.
  /// GET api/v1/shift_statuses. Xato/internet bo'lsa bo'sh to'plam (filtrlamaymiz).
  static Future<Set<String>> getOpenShiftCashboxIds({String? token}) async {
    final Set<String> openIds = <String>{};
    try {
      final HttpResult res = await ShiftApi4.shiftStatusInvan2(token: token);
      if (!res.isSuccess || res.result is! List) return openIds;
      for (final dynamic c in (res.result as List)) {
        if (c is! Map) continue;
        final bool isOpen = c['status'] == 'open' ||
            c['status'] == 'opened' ||
            c['opened_by_web'] == true ||
            c['opened_by_pos'] == true;
        final dynamic id = c['cashbox_id'];
        if (isOpen && id != null && '$id'.isNotEmpty) {
          openIds.add('$id');
        }
      }
    } catch (_) {
      // jim: holat noma'lum bo'lsa bloklamaymiz
    }
    return openIds;
  }

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
