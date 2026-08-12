// Adminkadan kelgan OFD holati va undan kelib chiqadigan sozlamalar — test.
//
// Talab: adminkada OFD o'chirilgan bo'lsa "naqd to'lov cheklovi" va "avto
// markirovkani aniqlash" ham amalda ishlamasligi va kassir tomonidan
// yoqilmasligi kerak.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/cashsale_setting_helper.dart';
import 'package:invan2/utils/helpers/marking_setting_helper.dart';
import 'package:invan2/utils/helpers/ofd_admin_setting.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('ofd_admin_setting_test', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    await Pref.setBool(PrefKeys.checkProductByCashsale, true);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
  });

  group('OfdAdminSetting.isEnabled', () {
    test('adminka OFD yoqqan -> true', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);

      expect(OfdAdminSetting.isEnabled, isTrue);
    });

    test('adminka OFD o\'chirgan -> false', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, false);

      expect(OfdAdminSetting.isEnabled, isFalse);
    });
  });

  group('OFD o\'chiq bo\'lsa bog\'liq sozlamalar ishlamaydi', () {
    setUp(() async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, false);
    });

    test('cashsale cheklovi o\'chiq, garchi o\'z kaliti true bo\'lsa ham',
        () async {
      await Pref.setBool(PrefKeys.checkProductByCashsale, true);

      expect(CashsaleSettingHelper.isEnabled, isFalse);
      expect(CashsaleSettingHelper.isEditable, isFalse);
    });

    test('markirovka avto-aniqlash o\'chiq, garchi o\'z kaliti true bo\'lsa ham',
        () async {
      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);

      expect(MarkingSettingHelper.isAutoDetectEnabled, isFalse);
      expect(MarkingSettingHelper.isEditable, isFalse);
    });
  });

  group('OFD yoqiq bo\'lsa kassir sozlamasi hal qiladi', () {
    test('ikkala sozlama yoqiq -> ikkalasi ham ishlaydi', () {
      expect(CashsaleSettingHelper.isEnabled, isTrue);
      expect(MarkingSettingHelper.isAutoDetectEnabled, isTrue);
      expect(CashsaleSettingHelper.isEditable, isTrue);
      expect(MarkingSettingHelper.isEditable, isTrue);
    });

    test('kassir o\'chirgan bo\'lsa ishlamaydi, lekin tahrirlanadi', () async {
      await Pref.setBool(PrefKeys.checkProductByCashsale, false);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, false);

      expect(CashsaleSettingHelper.isEnabled, isFalse);
      expect(MarkingSettingHelper.isAutoDetectEnabled, isFalse);
      // Adminkada OFD yoqiq — kassir ularni qayta yoqa oladi
      expect(CashsaleSettingHelper.isEditable, isTrue);
      expect(MarkingSettingHelper.isEditable, isTrue);
    });
  });

  group('syncDependentSettings (Activate/Update POS)', () {
    test('OFD o\'chirilgan -> ikkala sozlama diskda false ga tushadi',
        () async {
      await OfdAdminSetting.syncDependentSettings(false);

      expect(Pref.getBool(PrefKeys.checkProductByCashsale, true), isFalse);
      expect(Pref.getBool(PrefKeys.sellProductsWithMarking, true), isFalse);
    });

    test('OFD yoqilgan -> kassir tanlovi tegilmaydi', () async {
      await Pref.setBool(PrefKeys.checkProductByCashsale, false);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);

      await OfdAdminSetting.syncDependentSettings(true);

      expect(Pref.getBool(PrefKeys.checkProductByCashsale, true), isFalse);
      expect(Pref.getBool(PrefKeys.sellProductsWithMarking, false), isTrue);
    });

    test(
        'OFD qayta yoqilsa sozlamalar o\'chiq qoladi — kassir ongli yoqishi kerak',
        () async {
      await OfdAdminSetting.syncDependentSettings(false);
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await OfdAdminSetting.syncDependentSettings(true);

      expect(CashsaleSettingHelper.isEnabled, isFalse);
      expect(MarkingSettingHelper.isAutoDetectEnabled, isFalse);
      // lekin endi kassir ularni yoqa oladi
      expect(CashsaleSettingHelper.isEditable, isTrue);
      expect(MarkingSettingHelper.isEditable, isTrue);
    });
  });
}
