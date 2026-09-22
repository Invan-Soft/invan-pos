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

  /// Ayni paytda serverga ketayotgan cheklar (`externalId`). Onlayn vozvrat
  /// (`ReturnBloc`) chekni ObjectBox'ga `uploaded=false` bilan yozib, darhol
  /// o'zi yuboradi; xuddi shu lahzada tarmoq hodisasi `flush` ni ishga
  /// tushirsa, o'sha chek ikki marta POST bo'lardi. Shu to'plam buni to'sadi.
  static final Set<String> _inFlight = <String>{};

  /// Serverga so'rov (testda soxtasi qo'yiladi).
  static Future<HttpResult> Function(ReceiptModel4 refund) sendRequest =
      ReceiptApi4.receiptCreateGrouppForRefund;

  /// `uploaded`/`rejected` bayroqlarini saqlash (testda soxtasi qo'yiladi).
  static void Function(ReceiptModel4 refund) persist = _persistDefault;

  static void _persistDefault(ReceiptModel4 refund) {
    MyObjectbox.saleStore
        .box<ReceiptModel4>()
        .put(refund, mode: PutMode.update);
  }

  /// Testlar uchun: bog'liqliklarni ishlab chiqarish holatiga qaytarish.
  static void resetForTest() {
    sendRequest = ReceiptApi4.receiptCreateGrouppForRefund;
    persist = _persistDefault;
    _inFlight.clear();
    _inProgress = false;
  }

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
    try {
      for (final ReceiptModel4 refund in pending) {
        // Onlayn vozvrat shu lahzada o'zi yuborayotgan chek — tegilmaydi.
        if (_inFlight.contains(refund.externalId)) continue;
        final RefundUploadResult result =
            await uploadOne(refund, reason: reason);

        // Server yiqilgan yoki tarmoq uzilgan — bu rad etish EMAS.
        // Chekni navbatda qoldiramiz va butun tsiklni to'xtatamiz:
        // qolganlari ham xuddi shu xatoga uchraydi.
        if (result.status == RefundUploadStatus.pending) break;
      }
    } finally {
      _inProgress = false;
    }
  }

  /// Bitta qaytarish chekini serverga yuboradi va natijani ObjectBox'ga
  /// yozadi. `flush` (navbat) va `ReturnBloc` (onlayn vozvrat) ikkalasi shu
  /// metoddan foydalanadi — qoida bitta joyda:
  ///
  /// * 200/201/409 → `uploaded`; 409 — server "bu qaytarish menda bor" dedi.
  /// * 5xx / tarmoq / darvoza → `pending`; chek navbatda qoladi.
  /// * 4xx (yoki 5xx-u server tirik) → `rejected`; qayta yuborish foydasiz,
  ///   kassir cheklar ekranidan qo'lda ko'rib chiqadi.
  ///
  /// Chek ObjectBox'da allaqachon saqlangan bo'lishi kerak (`id != 0`).
  static Future<RefundUploadResult> uploadOne(
    ReceiptModel4 refund, {
    required String reason,
  }) async {
    final String key = refund.externalId;
    if (_inFlight.contains(key)) {
      // Boshqa yo'l (navbat yoki bloc) aynan shu chekni yuborayotgan
      // bo'lsa ikkinchi POST qilinmaydi. Natijani o'sha yo'l DB'ga yozadi;
      // bu chaqiruvchi uchun chek hozircha "navbatda".
      return const RefundUploadResult(RefundUploadStatus.pending);
    }
    _inFlight.add(key);
    try {
      return await _send(refund, reason: reason);
    } finally {
      _inFlight.remove(key);
    }
  }

  static Future<RefundUploadResult> _send(
    ReceiptModel4 refund, {
    required String reason,
  }) async {
    final HttpResult res = await sendRequest(refund);

    if (res.statusCode == 200 ||
        res.statusCode == 201 ||
        res.statusCode == 409) {
      refund.uploaded = true;
      refund.rejected = false;
      persist(refund);
      if (kDebugMode) {
        debugPrint('RefundUploadQueue: ${refund.externalId} yuborildi '
            '($reason)');
      }
      return const RefundUploadResult(RefundUploadStatus.uploaded);
    }

    // Sotuv cheklaridagi bilan bir xil qoida: 5xx bo'lsa serverning
    // o'zidan so'raymiz — tirik bo'lsa ayb hujjatda, o'lgan bo'lsa
    // navbatda qoldiramiz.
    final bool rejected =
        await BackendHealth.isDocumentRejection(res.statusCode);

    if (!rejected) {
      if (kDebugMode) {
        debugPrint('RefundUploadQueue: ${refund.externalId} navbatda qoldi, '
            'server javob bermayapti (status ${res.statusCode}, $reason)');
      }
      return RefundUploadResult(RefundUploadStatus.pending,
          error: res.getError);
    }

    // Server tirik va hujjatni qabul qilmadi — qayta yuborish foydasiz,
    // chek qo'lda ko'rib chiqilishi kerak.
    refund.rejected = true;
    persist(refund);
    LogRepository.addLog(
      "Qaytarish server tomonidan rad etildi: ${res.getError}",
      where: "RefundUploadQueue.uploadOne ($reason)",
      file: "refund_upload_queue.dart",
      method: "POST",
      path: "api/v1/refund_for_pos_new",
      statusCode: res.statusCode,
      checkNo: refund.externalId,
      createdDate: refund.createdDate,
      success: false,
    );
    return RefundUploadResult(RefundUploadStatus.rejected,
        error: res.getError);
  }
}

enum RefundUploadStatus { uploaded, pending, rejected }

class RefundUploadResult {
  final RefundUploadStatus status;

  /// Server xabari (`pending`/`rejected` da), kassirga ko'rsatish uchun.
  final String? error;

  const RefundUploadResult(this.status, {this.error});
}
