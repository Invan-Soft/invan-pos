// YagonaQr — smena (X/Z) hisoboti: alohida qator YO'Q, summa karta
// ("Plastik" = uzCard + humoCard) ichida.
//
// `ShiftSingleton4.getCurrentHiveShift` smenani ObjectBox'dagi cheklardan
// qayta hisoblaydi (`case 'yagonaqr'` → `uzCardPayment`).
//
// ObjectBox native kutubxonasi kerak (`libobjectbox.dylib` / `.so` / `.dll`
// loyiha ildizida yoki tizimda). Topilmasa testlar SKIP qilinadi. Mac'da:
//   cp build/macos/Build/Products/Debug/invan2.app/Contents/Frameworks/ObjectBox.framework/Versions/A/ObjectBox libobjectbox.dylib
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart' hide Box;
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/epay_fixtures.dart';
import 'support/provider_harness.dart';

Store? _tryOpenStore() {
  try {
    final dir = Directory.systemTemp.createTempSync('yagonaqr_shift_obx');
    return Store(getObjectBoxModel(), directory: dir.path);
  } catch (_) {
    return null;
  }
}

ReceiptModelPaymentType4 p(String name, String id, double v) =>
    ReceiptModelPaymentType4(name: name, payId: id, value: v);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Store? store = _tryOpenStore();

  group('Smena hisoboti: YagonaQr "Plastik" ichida', skip: store == null
      ? "ObjectBox kutubxonasi topilmadi (libobjectbox) — fayl boshidagi izohga qarang"
      : false, () {
    setUpAll(() async {
      await setUpPosTestEnv('yagonaqr_shift_report', withEmployee: false);
      if (!Hive.isAdapterRegistered(ShiftModelHiveAdapter().typeId)) {
        Hive.registerAdapter<ShiftModelHive>(ShiftModelHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(CashDrawerHiveAdapter().typeId)) {
        Hive.registerAdapter<CashDrawerHive>(CashDrawerHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(SalesSummaryHiveAdapter().typeId)) {
        Hive.registerAdapter<SalesSummaryHive>(SalesSummaryHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(PaysHiveAdapter().typeId)) {
        Hive.registerAdapter<PaysHive>(PaysHiveAdapter());
      }
      await Hive.openBox<ShiftModelHive>(HiveBoxNames.shifts);
      MyObjectbox.saleStore = store!;

      // Ochiq smena (Hive'da yozuv yo'q — getCurrentHiveShift tiklaydi).
      final opened = DateTime.now().subtract(const Duration(hours: 1));
      await Pref.setInt(PrefKeys.currentShiftKey, 7);
      await Pref.setInt(PrefKeys.shiftOpenedTime, opened.millisecondsSinceEpoch);
      await Pref.setBool(PrefKeys.shiftsOpened, true);
    });
    tearDownAll(() async {
      store?.close();
      await tearDownPosTestEnv();
    });

    test('naqd + YagonaQr, Uzcard, Humo + YagonaQr — YagonaQr uzCard ga qo\'shiladi',
        () {
      final box = MyObjectbox.saleStore.box<ReceiptModel4>();
      box.removeAll();
      box.putMany([
        receiptOf([row(realPrice: 100000)], [
          p('CASH', ids.cash, 30000),
          p('YAGONAQR', 'pay-yagona', 70000),
        ]),
        receiptOf([row(realPrice: 50000)], [p('UZCARD', ids.card, 50000)]),
        receiptOf([row(realPrice: 50000)], [
          p('HUMO', '@${ids.card}', 20000),
          p('YAGONAQR', 'pay-yagona', 30000),
        ]),
      ]);

      final s = ShiftSingleton4.getCurrentHiveShift()!.salesSummary!;
      expect(s.uzCard, 150000); // 50 000 Uzcard + 70 000 + 30 000 YagonaQr
      expect(s.humoCard, 20000);
      // "Plastik" (X hisobot ekrani va chop etiladigan "Пластик").
      expect((s.uzCard ?? 0) + (s.humoCard ?? 0), 170000);
      expect(s.card, 170000);
      expect(s.cash, 30000);
      expect(s.other, 0); // alohida qator / "Other" ga tushmaydi
      expect(s.grossSales, 200000);
    });

    test('nom normallashmagan eski chek: "YagonaQr" (registr farqi) — baribir Plastik',
        () {
      final box = MyObjectbox.saleStore.box<ReceiptModel4>();
      box.removeAll();
      box.put(receiptOf(
          [row(realPrice: 40000)], [p('YagonaQr', 'pay-yagona', 40000)]));

      final s = ShiftSingleton4.getCurrentHiveShift()!.salesSummary!;
      expect(s.uzCard, 40000); // switch nomni kichik harfga o'giradi
      expect(s.card, 40000);
      expect(s.other, 0);
    });

    test('nom normallashmagan, bo\'sh joyli ("Yagona QR") — "Other", lekin karta jamida',
        () {
      final box = MyObjectbox.saleStore.box<ReceiptModel4>();
      box.removeAll();
      box.put(receiptOf(
          [row(realPrice: 40000)], [p('Yagona QR', 'pay-yagona', 40000)]));

      final s = ShiftSingleton4.getCurrentHiveShift()!.salesSummary!;
      expect(s.other, 40000);
      expect(s.uzCard, 0);
      expect(s.card, 40000);
      expect(s.grossSales, 40000);
    });
  });
}
