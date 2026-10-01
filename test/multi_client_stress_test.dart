// Multi-klient stress-test — katta miqyosli tasodifiy stsenariylar.
//
// MAQSAD: 2026-09-30 access-bypass fix'idan keyin multi-klient holat mashinasi
// HAR QANDAY operatsiya ketma-ketligida buzilmasligini isbotlash. Minglab
// tasodifiy (seed'langan, takrorlanuvchi) qadamlar bajariladi va har qadamdan
// keyin quyidagi invariantlar tekshiriladi:
//
//   I1. Ro'yxat bo'sh bo'lmasa: _currentClient DOIM ro'yxatda (identity) va
//       getSelectedIndex uning real o'rniga teng.
//   I2. Ro'yxatdagi bo'sh savatli klient faqat _currentClient bo'lishi mumkin
//       (begona bo'sh slot qolmaydi).
//   I3. clientNumber'lar ro'yxat ichida unikal (tab'larda takror "Mijoz N" yo'q).
//   I4. Konservatsiya: hech bir klientning savati unga qaratilmagan operatsiya
//       natijasida O'ZGARMAYDI; mahsulotli klient hech qachon izsiz yo'qolmaydi.
//       (aynan kassir hiylasi shu invariantni buzardi)
//
// Har seed uchun kutilgan holat "shadow" modelda (identity-map) yuritiladi va
// provider bilan solishtiriladi. Xatolik chiqsa reason'da seed va qadam bor —
// aynan shu ketma-ketlikni lokal takrorlash mumkin.
//
// Hujjat: docs/sessions/2026-09-30-multi-klient-access-bypass-fix.md
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

/// Shadow model: har klient (identity) uchun kutilgan productId ro'yxati.
typedef Shadow = Map<SixClientModel4, List<String>>;

bool _inListOrCurrent(OrderingProvider4 p, SixClientModel4 c) =>
    identical(p.getCurrentClient, c) ||
    p.getSixClient4List.any((e) => identical(e, c));

void _checkInvariants(OrderingProvider4 p, Shadow shadow, String ctx) {
  final list = p.getSixClient4List;
  final current = p.getCurrentClient;

  if (list.isNotEmpty) {
    final idx = list.indexWhere((c) => identical(c, current));
    expect(idx, isNot(-1), reason: '$ctx: current ro\'yxatdan uzilgan');
    expect(p.getSelectedIndex, idx,
        reason: '$ctx: _index ($idx kutilgan) noto\'g\'ri');
    for (final c in list) {
      if (c.orderedProducts.isEmpty) {
        expect(identical(c, current), isTrue,
            reason: '$ctx: begona bo\'sh klient ro\'yxatda qolgan');
      }
    }
    final nums = list.map((c) => c.clientNumber).toList();
    expect(nums.toSet().length, nums.length,
        reason: '$ctx: clientNumber takrorlangan: $nums');
  }

  // Konservatsiya: mahsulotli klient izsiz yo'qolmasligi kerak
  for (final e in shadow.entries) {
    if (e.value.isNotEmpty) {
      expect(_inListOrCurrent(p, e.key), isTrue,
          reason:
              '$ctx: klient #${e.key.clientNumber} ${e.value} mahsulotlari '
              'bilan G\'OYIB bo\'ldi (kassir hiylasi qaytdi!)');
    }
  }

  // Har ko'rinadigan klient savati aynan kutilganidek
  final visible = <SixClientModel4>{...list, current};
  for (final c in visible) {
    final expected = shadow[c] ?? const <String>[];
    expect(c.orderedProducts.map((i) => i.productId).toList(), expected,
        reason: '$ctx: klient #${c.clientNumber} savati ruxsatsiz o\'zgargan');
  }

  // Ko'rinmay qolgan (to'langan/bo'sh chiqarilgan) klientlarni shadow'dan olib
  // tashlaymiz — ular faqat bo'sh holda chiqib ketishi mumkin edi (yuqorida
  // tekshirildi).
  shadow.removeWhere((c, _) => !_inListOrCurrent(p, c));
}

Future<void> _fuzzSeed(WidgetTester tester, int seed, int steps) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  final ctx = tester.element(find.byType(SizedBox));

  final rnd = Random(seed);
  final p = freshProvider();
  final Shadow shadow = Map.identity();
  shadow[p.getCurrentClient] = [];
  int productSeq = 0;

  List<String> sh(SixClientModel4 c) => shadow.putIfAbsent(c, () => []);

  for (int step = 0; step < steps; step++) {
    final roll = rnd.nextInt(100);
    final current = p.getCurrentClient;
    final list = p.getSixClient4List;
    String op;

    if (roll < 30) {
      // SKAN — joriy savatga mahsulot
      op = 'scan';
      final id = 'p${productSeq++}';
      current.orderedProducts.add(makeSoldItem(productId: id));
      sh(current).add(id);
    } else if (roll < 45 && list.length < 6) {
      // YANGI KLIENT (provider bo'sh savatda o'zi rad etadi)
      op = 'addClient';
      final hadItems = current.orderedProducts.isNotEmpty;
      p.addClient();
      if (hadItems) {
        sh(p.getCurrentClient); // yangi bo'sh klient shadow'ga
      } else {
        expect(identical(p.getCurrentClient, current), isTrue,
            reason: 'seed=$seed step=$step: bo\'sh savatda addClient '
                'holatni o\'zgartirmasligi kerak');
      }
    } else if (roll < 65 && list.isNotEmpty) {
      // KLIENT TANLASH — har qanday indeks, jumladan bo'sh/joriy klient
      final i = rnd.nextInt(list.length);
      op = 'select($i)';
      final target = list[i];
      p.selectClient(i);
      expect(identical(p.getCurrentClient, target), isTrue,
          reason: 'seed=$seed step=$step: tanlangan klient joriy bo\'lmadi');
    } else if (roll < 72) {
      // BUTUN SAVATNI BEKOR QILISH — ruxsat bilan
      op = 'cancelTrue';
      p.cancelOrdering(true);
      sh(current).clear();
    } else if (roll < 79) {
      // RUXSATSIZ BEKOR QILISH — test xodimida deleteS yo'q: rad etilishi shart
      op = 'cancelFalse';
      final result = p.cancelOrdering(false);
      if (current.orderedProducts.isNotEmpty) {
        expect(result, isFalse,
            reason: 'seed=$seed step=$step: ruxsatsiz cancelOrdering '
                'savatni tozalab yubordi (access bypass!)');
      }
    } else if (roll < 89 && current.orderedProducts.isNotEmpty) {
      // OXIRGI QATORNI O'CHIRISH
      op = 'removeLast';
      current.lastAddedIndex = current.orderedProducts.length - 1;
      p.removeLastAdded();
      sh(current).removeLast();
    } else if (roll < 97 && current.orderedProducts.isNotEmpty) {
      // TO'LOV — faqat joriy klient savati tozalanishi kerak
      op = 'pay';
      p.initPaymentPageValues(
        sixClientModel4: current,
        totalPrice: 1000,
        discountAmount: 0,
      );
      await p.pressPaymentButton(ctx);
      sh(current).clear();
    } else if (roll >= 97) {
      // SMENA TOZALASH — hammasi bo'shaydi
      op = 'clearAll';
      p.clearSixClient4List();
      shadow.clear();
      shadow[p.getCurrentClient] = [];
    } else {
      continue; // shart bajarilmagan variant — qadam tashlab ketiladi
    }

    _checkInvariants(p, shadow, 'seed=$seed step=$step op=$op');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('multi_client_stress_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() => Pref.setBool(PrefKeys.isRedDeleteActivated, false));

  group('Fuzz — tasodifiy operatsiyalar oqimi (har qadamda invariantlar)', () {
    for (final batch in [0, 1, 2]) {
      testWidgets('seed to\'plami ${batch + 1}/3 (10 seed x 300 qadam)',
          (tester) async {
        // Minglab qadamda [ACTIVITY] loglari konsolni bosmasligi uchun
        // vaqtincha o'chiriladi; test tugashidan OLDIN tiklanishi shart
        // (framework foundation o'zgaruvchilarini tekshiradi).
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {};
        try {
          for (int s = 0; s < 10; s++) {
            final seed = 1000 + batch * 10 + s;
            await _fuzzSeed(tester, seed, 300);
          }
        } finally {
          debugPrint = originalDebugPrint;
        }
      }, timeout: const Timeout(Duration(minutes: 5)));
    }
  });

  group('Deterministik chekka holatlar', () {
    test('bo\'sh klient tab\'ini KETMA-KET ikki marta bosish', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();

      p.selectClient(1);
      p.selectClient(1); // double-tap

      expect(p.getSixClient4List.length, 2);
      expect(p.getSelectedIndex, 1);
      expect(p.getSixClient4List[1], same(p.getCurrentClient));
      expect(p.getSixClient4List.first.orderedProducts.length, 1);
    });

    testWidgets('4 klientli hiyla varianti: bo\'sh 4-klient orqali to\'lov',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final p = freshProvider();
      // 3 ta to'la klient
      for (final id in ['a', 'b', 'c']) {
        p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: id));
        p.addClient();
      }
      // hozir 4-klient (bo'sh) joriy; kassir uni qayta bosdi
      p.selectClient(3);
      // skanladi va sotdi
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'x'));
      p.initPaymentPageValues(
        sixClientModel4: p.getCurrentClient,
        totalPrice: 5000,
        discountAmount: 0,
      );
      await p.pressPaymentButton(ctx);

      // Uchchala klient mahsulotlari joyida
      final products = p.getSixClient4List
          .map((c) => c.orderedProducts.map((i) => i.productId).join())
          .toList();
      expect(products, ['a', 'b', 'c']);
      expect(p.getCurrentClient, same(p.getSixClient4List.first));
      expect(p.getSelectedIndex, 0);
    });

    test('cancelOrdering(true) dan keyin boshqa klientga o\'tish', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));

      // joriy (2-klient) savati ruxsat bilan bekor qilindi — bo'sh, lekin joriy
      p.cancelOrdering(true);
      expect(p.getSixClient4List.length, 2);

      // 1-klientga qaytish — bo'shab qolgan 2-klient ro'yxatdan chiqadi
      p.selectClient(0);

      expect(p.getSixClient4List.length, 1);
      expect(p.getSelectedIndex, 0);
      expect(p.getCurrentClient.orderedProducts.first.productId, 'a');
    });

    test('6 klientgacha ketma-ket qo\'shish — raqamlar unikal va o\'suvchi',
        () {
      final p = freshProvider();
      for (int i = 0; i < 5; i++) {
        p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'p$i'));
        p.addClient();
      }
      expect(p.getSixClient4List.length, 6);
      expect(
        p.getSixClient4List.map((c) => c.clientNumber).toList(),
        [1, 2, 3, 4, 5, 6],
      );
      expect(p.getSelectedIndex, 5);
    });

    test('bo\'sh klientda skan qilib, orqaga qaytish — mahsulotlar o\'z '
        'joyida', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.selectClient(1); // bo'sh 2-klient joriy (ro'yxatda!)
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'x'));

      p.selectClient(0);
      expect(p.getCurrentClient.orderedProducts.first.productId, 'a');

      p.selectClient(1);
      expect(p.getCurrentClient.orderedProducts.first.productId, 'x');
      expect(p.getSixClient4List.length, 2);
    });
  });
}
