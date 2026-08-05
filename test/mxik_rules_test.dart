// MXIK markirovka qoidalari — test.
//
// Bu funksiyalar Faza 1 da OrderingProvider4 dan `MxikRules` ga ko'chirildi.
// Ilgari `private` bo'lgani uchun to'g'ridan-to'g'ri testlab bo'lmasdi —
// ajratishning bevosita foydasi shu.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/marking/mxik_rules.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

ItemModel item({String? mxik, bool? isMarking}) {
  final m = ItemModel();
  m.mxikCode = mxik;
  m.isMarking = isMarking;
  return m;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('mxik_rules_test'));
  tearDownAll(tearDownPosTestEnv);

  group('isAlcoholMxik', () {
    test('024 (sigareta) ham alkogol ro\'yxatida', () {
      expect(MxikRules.isAlcoholMxik('02400000000000000'), isTrue);
    });

    test('02203..02208 alkogol', () {
      for (final p in ['02203', '02204', '02205', '02206', '02207', '02208']) {
        expect(MxikRules.isAlcoholMxik('${p}0000000000'), isTrue, reason: p);
      }
    });

    test('02202 alkogol EMAS', () {
      expect(MxikRules.isAlcoholMxik('02202001001000000'), isFalse);
    });

    test('bo\'sh satr', () {
      expect(MxikRules.isAlcoholMxik(''), isFalse);
    });
  });

  group('isMxikMarking', () {
    test('02009 / 02201 / 02202 markirovkali', () {
      expect(MxikRules.isMxikMarking('02009000000000000'), isTrue);
      expect(MxikRules.isMxikMarking('02201000000000000'), isTrue);
      expect(MxikRules.isMxikMarking('02202000000000000'), isTrue);
    });

    test('alkogol ham markirovkali', () {
      expect(MxikRules.isMxikMarking('02205000000000000'), isTrue);
    });

    test('tanish bo\'lmagan MXIK markirovkasiz', () {
      expect(MxikRules.isMxikMarking('01234567890123456'), isFalse);
    });
  });

  group('getProductType — MXIK -> product_type', () {
    test('024 -> 1 (sigareta)', () {
      expect(MxikRules.getProductType('02400000000000000'), '1');
    });

    test('02203 -> 3 (pivo)', () {
      expect(MxikRules.getProductType('02203000000000000'), '3');
    });

    test('02204..02208 -> 2 (alkogol, pivo emas)', () {
      for (final p in ['02204', '02205', '02206', '02207', '02208']) {
        expect(MxikRules.getProductType('${p}0000000000'), '2', reason: p);
      }
    });

    test('02009 / 02201 / 02202 -> 5 (ichimlik)', () {
      expect(MxikRules.getProductType('02009000000000000'), '5');
      expect(MxikRules.getProductType('02201000000000000'), '5');
      expect(MxikRules.getProductType('02202000000000000'), '5');
    });

    test('030 -> 4', () {
      expect(MxikRules.getProductType('03000000000000000'), '4');
    });

    test('085 -> 6', () {
      expect(MxikRules.getProductType('08500000000000000'), '6');
    });

    test('tanish bo\'lmagan -> bo\'sh', () {
      expect(MxikRules.getProductType('99999999999999999'), '');
    });

    test('024 tekshiruvi 02203 dan OLDIN — sigareta ustun', () {
      // Ikkalasi ham "02" bilan boshlanadi, lekin 024 birinchi tekshiriladi
      expect(MxikRules.getProductType('024'), '1');
    });
  });

  group('isProductMarkable — sozlamalarga bog\'liq', () {
    test('markCheckWithOfd o\'chiq: hech narsa markirovkali emas', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, false);

      expect(MxikRules.isProductMarkable(item(isMarking: true)), isFalse);
      expect(
        MxikRules.isProductMarkable(item(mxik: '02205000000000000')),
        isFalse,
      );
    });

    test('OFD yoqiq + product.isMarking = true -> markirovkali', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, false);

      // Avto-aniqlash o'chiq bo'lsa ham, aniq belgilangan mahsulot markirovkali
      expect(MxikRules.isProductMarkable(item(isMarking: true)), isTrue);
    });

    test('OFD yoqiq + avto-aniqlash o\'chiq -> MXIK tekshirilmaydi', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, false);

      expect(
        MxikRules.isProductMarkable(item(mxik: '02205000000000000')),
        isFalse,
      );
    });

    test('OFD yoqiq + avto-aniqlash yoqiq + MXIK ro\'yxatda -> markirovkali',
        () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);

      expect(
        MxikRules.isProductMarkable(item(mxik: '02205000000000000')),
        isTrue,
      );
    });

    test('MXIK atrofidagi probellar e\'tiborga olinmaydi', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);

      expect(
        MxikRules.isProductMarkable(item(mxik: '  02205000000000000  ')),
        isTrue,
      );
    });

    test('mxikCode null -> markirovkali emas', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);

      expect(MxikRules.isProductMarkable(item()), isFalse);
    });
  });

  group('resolveProductType / resolveProductPackage', () {
    setUp(() async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
    });

    test('markirovkali emas -> bo\'sh type va bo\'sh package', () {
      final p = item(mxik: '99999999999999999');

      expect(MxikRules.resolveProductType(p), '');
      expect(MxikRules.resolveProductPackage(p), '');
    });

    test('markirovkali + MXIK tanish -> o\'sha type, package KIZ', () {
      final p = item(mxik: '02205000000000000');

      expect(MxikRules.resolveProductType(p), '2');
      expect(MxikRules.resolveProductPackage(p), 'KIZ');
    });

    test('isMarking = true, lekin MXIK notanish -> default type 5', () {
      final p = item(mxik: '99999999999999999', isMarking: true);

      expect(MxikRules.resolveProductType(p), '5');
      expect(MxikRules.resolveProductPackage(p), 'KIZ');
    });
  });
}
