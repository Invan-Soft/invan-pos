import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/shift/shifting_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
import 'package:invan2/changes/services/shift_api_4.dart';
import 'package:invan2/utils/utils.dart';

/// Serverga yetkazilmagan smena ochish/yopish xabarlarining navbati.
///
/// Kassa oflayn ishlashi shart, shuning uchun smena avval **lokal** yopiladi va
/// serverga yuborish navbatga qo'yiladi (`closedDate` + `closedCount=1`,
/// `openedDate` + `openedCount=1`). Bu klass o'sha navbatni yuboradi.
///
/// Nima uchun alohida klass:
/// 1. Ilgari bu mantiq ikki joyda (app.dart va usr_bloc.dart) nusxalangan edi
///    va ikkalasida ham bir xil ikkita xato bor edi:
///    - navbat **ketmagan cheklar bo'lmasagina** yuborilardi (`_isBoxEmpty()`),
///      holbuki smena yopilishining cheklarga hech qanday aloqasi yo'q;
///    - so'rov natijasi tekshirilmasdan navbat tozalanardi — server javob
///      bermasa ham `closedDate=''` bo'lib, yopish **butunlay yo'qolardi**.
/// 2. Endi navbat faqat server tasdiqlagandan keyin tozalanadi va bir nechta
///    joydan (tarmoq tiklanganda, ilova ochilganda, cheklar yuklangandan
///    keyin) bemalol chaqirilishi mumkin.
class ShiftSyncQueue {
  ShiftSyncQueue._();

  static bool _inProgress = false;

  /// Navbatda kutayotgan yopish bormi.
  static bool get hasPendingClose =>
      Pref.getString(PrefKeys.closedDate, '').isNotEmpty &&
      Pref.getInt(PrefKeys.closedCount, 0) == 1;

  /// Navbatda kutayotgan ochish bormi.
  static bool get hasPendingOpen =>
      Pref.getString(PrefKeys.openedDate, '').isNotEmpty &&
      Pref.getInt(PrefKeys.openedCount, 0) == 1;

  static bool get hasPending => hasPendingClose || hasPendingOpen;

  /// Navbatni serverga yuborishga urinadi.
  ///
  /// Xavfsiz: navbat bo'sh bo'lsa yoki boshqa urinish ketayotgan bo'lsa
  /// darhol qaytadi, shuning uchun istalgan joydan chaqirish mumkin.
  /// Muvaffaqiyatsiz bo'lsa navbat **saqlanib qoladi** va keyingi chaqiruvda
  /// qayta urinilib ko'riladi.
  static Future<void> flush({required String reason}) async {
    if (_inProgress || !hasPending) return;
    _inProgress = true;

    try {
      // TARTIB MUHIM. Navbatda ochish ham, yopish ham turgan bo'lishi mumkin:
      // masalan server o'chgan paytda smena ertalab OCHILIB, kechqurun
      // YOPILGAN bo'lsa. Bunda serverga avval ochish, keyin yopish ketishi
      // shart — aks holda server "ochilmagan smenani yopyapsiz" deb rad etadi.
      //
      // Teskari holat ham bor: oldingi smenaning yopilishi navbatda qolgan
      // bo'lsa, yangi smena ochilishidan OLDIN o'sha yopilish ketishi kerak.
      //
      // Shuning uchun tartib qat'iy emas — vaqt belgilariga qarab aniqlanadi.
      if (_openBeforeClose()) {
        if (!await _flushOpen(reason)) return;
        await _flushClose(reason);
      } else {
        if (!await _flushClose(reason)) return;
        await _flushOpen(reason);
      }
    } finally {
      _inProgress = false;
    }
  }

  /// Navbatdagi ochish yopishdan OLDIN sodir bo'lganmi.
  ///
  /// Ikkalasi ham navbatda bo'lmasa javob ahamiyatsiz — mos `_flush*` metodi
  /// o'zi bo'sh navbatni o'tkazib yuboradi.
  static bool _openBeforeClose() {
    if (!hasPendingOpen) return false;
    if (!hasPendingClose) return true;
    final DateTime? opened =
        DateTime.tryParse(Pref.getString(PrefKeys.openedDate, ''));
    final DateTime? closed =
        DateTime.tryParse(Pref.getString(PrefKeys.closedDate, ''));
    if (opened == null || closed == null) return true; // noaniq — ochish oldin
    return opened.isBefore(closed);
  }

  /// `true` — yuborildi yoki navbatda yo'q edi; `false` — urinish yiqildi.
  static Future<bool> _flushOpen(String reason) async {
    if (!hasPendingOpen) return true;
    final HttpResult res = await ShiftApi4.openShift();
    final bool ok = res.statusCode == 200 || res.statusCode == 201;
    if (kDebugMode) {
      print('ShiftSyncQueue: OPEN flush ($reason) → ${res.statusCode}');
    }
    if (ok) {
      await Pref.setInt(PrefKeys.openedCount, 0);
      await Pref.setString(PrefKeys.openedDate, '');
      return true;
    }
    await ShiftDiagnostics.report(
      issue: ShiftIssue.pendingOpenNotSynced,
      action: ShiftAction.open,
      detail: 'Navbatdagi ochishni yuborish urinishi ($reason) '
          'muvaffaqiyatsiz: status ${res.statusCode}. '
          'Navbatda qoldirildi.',
    );
    return false;
  }

  /// `true` — yuborildi yoki navbatda yo'q edi; `false` — urinish yiqildi.
  static Future<bool> _flushClose(String reason) async {
    if (!hasPendingClose) return true;
    final ShiftingModel res = await ShiftApi4.closeShift();
    final bool ok = res.statusCode == 200;
    if (kDebugMode) {
      print('ShiftSyncQueue: CLOSE flush ($reason) → ${res.statusCode}');
    }
    if (ok) {
      await Pref.setInt(PrefKeys.closedCount, 0);
      await Pref.setString(PrefKeys.closedDate, '');
      return true;
    }
    await ShiftDiagnostics.report(
      issue: ShiftIssue.pendingCloseNotSynced,
      action: ShiftAction.close,
      detail: 'Navbatdagi yopishni yuborish urinishi ($reason) '
          'muvaffaqiyatsiz: status ${res.statusCode ?? "-"} / '
          '${res.message ?? "-"}. Navbatda qoldirildi.',
    );
    return false;
  }
}
