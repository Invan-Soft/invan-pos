/*
    Serverga yetkazilmagan QAYTARISH (refund) cheklarining navbati.

    Nima uchun alohida navbat kerak: sotuv cheklari `UsrBloc._send` orqali
    guruhlab `api/v1/order_pos` ga ketadi, lekin qaytarish butunlay boshqa
    yo'ldan boradi — avval `api/v1/refund_for_pos_new`, keyin
    `api/v1/refund_order_items/{orderId}`.

    `ReceiptApi4.receiptCreateGroup` refund cheklarini `jsonListFromRefund`
    ro'yxatiga yig'adi-yu, uni HECH QAYERGA yubormaydi; `UsrBloc` esa 201
    javobidan keyin `isRefund == false` cheklarnigina `uploaded = true`
    qiladi. Ya'ni navbatga tushgan qaytarish o'z-o'zidan hech qachon
    yuborilmasdi — shuning uchun ilgari qaytarish faqat ONLAYN bajarilar,
    server javob bermasa umuman qilib bo'lmasdi.

    Endi qaytarish lokal bajariladi (fiskal chek chiqadi, ObjectBox'ga
    yoziladi) va serverga yuborish shu navbatga qo'yiladi.
*/

import 'package:flutter/foundation.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/receipt_api_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart';

class RefundUploadQueue {
  RefundUploadQueue._();

  static bool _inProgress = false;

  /// Navbatda kutayotgan qaytarishlar soni.
  static int get pendingCount {
    final query = _pendingQuery();
    final int count = query.count();
    query.close();
    return count;
  }

  static Query<ReceiptModel4> _pendingQuery({bool includeRejected = false}) {
    final condition = includeRejected
        ? ReceiptModel4_.isRefund.equals(true) &
            ReceiptModel4_.uploaded.equals(false)
        : ReceiptModel4_.isRefund.equals(true) &
            ReceiptModel4_.uploaded.equals(false) &
            ReceiptModel4_.rejected.equals(false);
    return MyObjectbox.saleStore.box<ReceiptModel4>().query(condition).build();
  }

  /// Navbatni serverga yuborishga urinadi.
  ///
  /// Xavfsiz: navbat bo'sh bo'lsa, boshqa urinish ketayotgan bo'lsa yoki
  /// server javob bermayotgan bo'lsa darhol qaytadi. Shuning uchun istalgan
  /// joydan (startup, tarmoq tiklanganda, server tiklanganda) chaqirsa
  /// bo'ladi.
  /// [includeRejected] — server ilgari rad etgan qaytarishlar ham
  /// yuborilsinmi. Faqat kassir QO'LDA "yangilash" bosganda `true` bo'ladi:
  /// avtomatik urinishlarda rad etilgan hujjatni qayta-qayta yuborish
  /// odatda yana o'sha xatoni beradi.
  static Future<void> flush({
    required String reason,
    bool includeRejected = false,
  }) async {
    if (_inProgress) return;
    if (!await BackendHealth.isUsable()) return;

    final query = _pendingQuery(includeRejected: includeRejected);
    final List<ReceiptModel4> pending = query.find();
    query.close();
    if (pending.isEmpty) return;

    _inProgress = true;
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    try {
      for (final ReceiptModel4 refund in pending) {
        final HttpResult res =
            await ReceiptApi4.receiptCreateGrouppForRefund(refund);

        // 409 — server "bu qaytarish menda bor" dedi, ya'ni muvaffaqiyat.
        if (res.statusCode == 200 ||
            res.statusCode == 201 ||
            res.statusCode == 409) {
          refund.uploaded = true;
          refund.rejected = false;
          box.put(refund, mode: PutMode.update);
          if (kDebugMode) {
            debugPrint('RefundUploadQueue: ${refund.externalId} yuborildi '
                '($reason)');
          }
          continue;
        }

        // Sotuv cheklaridagi bilan bir xil qoida: 5xx bo'lsa serverning
        // o'zidan so'raymiz — tirik bo'lsa ayb hujjatda, o'lgan bo'lsa
        // navbatda qoldiramiz.
        final bool rejected =
            await BackendHealth.isDocumentRejection(res.statusCode);

        if (!rejected) {
          // Server yiqilgan yoki tarmoq uzilgan — bu rad etish EMAS.
          // Chekni navbatda qoldiramiz va butun tsiklni to'xtatamiz:
          // qolganlari ham xuddi shu xatoga uchraydi.
          if (kDebugMode) {
            debugPrint('RefundUploadQueue: to\'xtatildi, server javob '
                'bermayapti (status ${res.statusCode})');
          }
          break;
        }

        // Server tirik va hujjatni qabul qilmadi — qayta yuborish foydasiz,
        // chek qo'lda ko'rib chiqilishi kerak.
        refund.rejected = true;
        box.put(refund, mode: PutMode.update);
        LogRepository.addLog(
          "Qaytarish server tomonidan rad etildi: ${res.getError}",
          where: "RefundUploadQueue.flush",
          file: "refund_upload_queue.dart",
          method: "POST",
          path: "api/v1/refund_for_pos_new",
          statusCode: res.statusCode,
          checkNo: refund.externalId,
          createdDate: refund.createdDate,
          success: false,
        );
      }
    } finally {
      _inProgress = false;
    }
  }
}
