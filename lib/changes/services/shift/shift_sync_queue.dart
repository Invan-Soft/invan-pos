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
      if (hasPendingClose) {
        final ShiftingModel res = await ShiftApi4.closeShift();
        final bool ok = res.statusCode == 200;
        if (kDebugMode) {
          print('ShiftSyncQueue: CLOSE flush ($reason) → ${res.statusCode}');
        }
        if (ok) {
          await Pref.setInt(PrefKeys.closedCount, 0);
          await Pref.setString(PrefKeys.closedDate, '');
        } else {
          await ShiftDiagnostics.report(
            issue: ShiftIssue.pendingCloseNotSynced,
            action: ShiftAction.close,
            detail: 'Navbatdagi yopishni yuborish urinishi ($reason) '
                'muvaffaqiyatsiz: status ${res.statusCode ?? "-"} / '
                '${res.message ?? "-"}. Navbatda qoldirildi.',
          );
        }
      }

      if (hasPendingOpen) {
        final HttpResult res = await ShiftApi4.openShift();
        final bool ok = res.statusCode == 200 || res.statusCode == 201;
        if (kDebugMode) {
          print('ShiftSyncQueue: OPEN flush ($reason) → ${res.statusCode}');
        }
        if (ok) {
          await Pref.setInt(PrefKeys.openedCount, 0);
          await Pref.setString(PrefKeys.openedDate, '');
        } else {
          await ShiftDiagnostics.report(
            issue: ShiftIssue.pendingOpenNotSynced,
            action: ShiftAction.open,
            detail: 'Navbatdagi ochishni yuborish urinishi ($reason) '
                'muvaffaqiyatsiz: status ${res.statusCode}. '
                'Navbatda qoldirildi.',
          );
        }
      }
    } finally {
      _inProgress = false;
    }
  }
}
