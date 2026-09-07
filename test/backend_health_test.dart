// BackendHealth — server yiqilganini aniqlash testlari.
//
// Nega kerak: bu klass kassaning oflayn rejimga o'tish qarorini qabul
// qiladi. Xato tomonga og'sa oqibati og'ir bo'ladi — juda tez `down`
// bo'lsa ishlayotgan serverdan uzilib qolamiz (cheklar behuda navbatda
// qoladi), umuman `down` bo'lmasa esa kassir har amalda 30 soniya kutadi
// va smena ochilmaydi. Shuning uchun chegara, tiklanish va gate xulqi
// aniq mixlangan bo'lishi kerak.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/health/backend_health.dart';

void main() {
  setUp(() {
    BackendHealth.reset();
    BackendHealth.autoProbe = false; // testlarda haqiqiy taymer kerak emas
    BackendHealth.now = DateTime.now;
    BackendHealth.internetCheck = () async => true;
    // Standart: server haqiqatan o'chgan (tekshiruv ham yiqiladi).
    BackendHealth.probeRequest = () async => false;
  });

  tearDown(() {
    BackendHealth.reset();
    BackendHealth.autoProbe = true;
    BackendHealth.now = DateTime.now;
  });

  group('holatga o\'tish', () {
    test('boshlang\'ich holat — up', () {
      expect(BackendHealth.isUp, isTrue);
    });

    test('chegaradan kam xato holatni buzmaydi', () async {
      BackendHealth.recordFailure();
      BackendHealth.recordFailure();
      await pumpEventQueue();
      expect(BackendHealth.isUp, isTrue,
          reason: 'ikkita xato — tasodifiy uzilish bo\'lishi mumkin');
    });

    test('3 xato + tekshiruv ham yiqilsa — down', () async {
      await _forceDown();
      expect(BackendHealth.isDown, isTrue);
      expect(BackendHealth.downSince, isNotNull);
    });

    test('oradagi muvaffaqiyat hisobni noldan boshlaydi', () async {
      BackendHealth.recordFailure();
      BackendHealth.recordFailure();
      BackendHealth.recordSuccess();
      BackendHealth.recordFailure();
      BackendHealth.recordFailure();
      await pumpEventQueue();
      expect(BackendHealth.isUp, isTrue,
          reason: 'hisob nolga tushgani uchun yana 3 ta xato kerak');
    });

    test('bitta muvaffaqiyat down holatidan chiqaradi', () async {
      await _forceDown();
      BackendHealth.recordSuccess();
      expect(BackendHealth.isUp, isTrue);
      expect(BackendHealth.downSince, isNull);
    });

    test('tiklanganda onRecovered chaqiriladi', () async {
      int calls = 0;
      BackendHealth.onRecovered = () => calls++;
      await _forceDown();
      expect(calls, 0);
      BackendHealth.recordSuccess();
      expect(calls, 1, reason: 'navbatlarni yuborish shu yerdan qo\'zg\'aladi');
    });
  });

  // Foydalanuvchi savolidan kelib chiqqan guruh (2026-09-02):
  // "500 aynan bitta API'dan kelsa-chi? Masalan bitta chek qayta-qayta
  //  500 bersa — butun kassa oflayn bo'lib qoladimi?"
  group('bitta "buzuq" so\'rov butun kassani uzib qo\'ymaydi', () {
    test('server tirik ekan — 3 ta 500 dan keyin ham oflayn rejimga o\'tmaydi',
        () async {
      // Tekshiruv so'rovi muvaffaqiyatli: server javob beryapti.
      BackendHealth.probeRequest = () async => true;

      for (int i = 0; i < 5; i++) {
        BackendHealth.recordFailure(path: 'api/v1/order_pos');
      }
      await pumpEventQueue();

      expect(BackendHealth.isUp, isTrue,
          reason: 'muammo aynan shu so\'rovda — server sog\'lom');
      expect(BackendHealth.consecutiveFailures, 0,
          reason: 'hisob nolga tushirilib, kuzatuv yangidan boshlanadi');
    });

    test('yolg\'on trevoga qayd etiladi — qaysi endpoint muammoli', () async {
      BackendHealth.probeRequest = () async => true;
      for (int i = 0; i < 3; i++) {
        BackendHealth.recordFailure(path: 'api/v1/order_pos');
      }
      await pumpEventQueue();

      expect(BackendHealth.lastFalseAlarm, isNotNull);
      expect(BackendHealth.lastFalseAlarm!.paths, contains('api/v1/order_pos'));
    });

    test('server haqiqatan o\'lgan bo\'lsa — oflayn rejimga o\'tadi', () async {
      BackendHealth.probeRequest = () async => false;
      for (int i = 0; i < 3; i++) {
        BackendHealth.recordFailure(path: 'api/v1/order_pos');
      }
      await pumpEventQueue();

      expect(BackendHealth.isDown, isTrue);
    });

    test('tekshiruvning o\'zi istisno tashlasa — oflayn deb hisoblanadi',
        () async {
      BackendHealth.probeRequest = () async => throw const SocketException('x');
      for (int i = 0; i < 3; i++) {
        BackendHealth.recordFailure();
      }
      await pumpEventQueue();

      expect(BackendHealth.isDown, isTrue);
    });
  });

  // Chek/qaytarish serverga ketmasa — u "rad etilgan" deb belgilanadimi?
  // Bu qaror og'ir: rad etilgan hujjat avtomatik navbatdan chiqadi va
  // faqat kassir qo'lda yuborsagina ketadi.
  group('hujjat rad etildimi (isDocumentRejection)', () {
    test('tarmoq xatolari rad etish EMAS — navbatda qoladi', () async {
      for (final int code in [-1, -2, BackendHealth.serverDownStatusCode]) {
        expect(await BackendHealth.isDocumentRejection(code), isFalse,
            reason: '$code — javob umuman kelmagan');
      }
    });

    test('4xx — rad etish (qayta yuborish foydasiz)', () async {
      for (final int code in [400, 401, 403, 404, 422]) {
        expect(await BackendHealth.isDocumentRejection(code), isTrue);
      }
    });

    // 409 ni chaqiruvchilar (UsrBloc, RefundUploadQueue) MUVAFFAQIYAT deb
    // hal qiladi — bu yerga umuman yetib kelmaydi. Test shuni mixlaydi:
    // agar kimdir 409 ni shu metodga uzatsa, u "rad etilgan" deb
    // belgilanib, serverda TURGAN chek kassada qizil bo'lib qolardi.
    test('409 chaqiruvchida hal qilinishi kerak — bu yerda 4xx sanaladi',
        () async {
      expect(await BackendHealth.isDocumentRejection(409), isTrue,
          reason: 'shuning uchun UsrBloc va RefundUploadQueue 409 ni '
              'bu metodga UZATMAYDI, o\'zi muvaffaqiyat deb qabul qiladi');
    });

    test('5xx + server TIRIK → ayb hujjatda, rad etilgan deb belgilanadi',
        () async {
      BackendHealth.probeRequest = () async => true;
      expect(await BackendHealth.isDocumentRejection(500), isTrue,
          reason: 'server ishlayapti, demak muammo aynan shu chekda — '
              'kassir uni "Rad etilgan cheklar" da ko\'rishi kerak');
    });

    test('5xx + server O\'LGAN → rad etish emas, navbatda qoladi', () async {
      BackendHealth.probeRequest = () async => false;
      expect(await BackendHealth.isDocumentRejection(500), isFalse,
          reason: 'outage paytida sog\'lom cheklar navbatdan '
              'chiqib ketmasligi kerak');
      expect(BackendHealth.isDown, isTrue,
          reason: 'to\'g\'ridan-to\'g\'ri dalil bor — chegara kutilmaydi');
    });

    test('server o\'lgani aniqlansa oflayn rejimga DARHOL o\'tadi', () async {
      BackendHealth.probeRequest = () async => false;
      expect(BackendHealth.isUp, isTrue);
      await BackendHealth.isDocumentRejection(503);
      expect(BackendHealth.isDown, isTrue);
    });

    test('server tirik chiqsa hisoblagich tozalanadi', () async {
      BackendHealth.probeRequest = () async => true;
      BackendHealth.recordFailure();
      BackendHealth.recordFailure();
      await BackendHealth.isDocumentRejection(500);
      expect(BackendHealth.consecutiveFailures, 0);
      expect(BackendHealth.isUp, isTrue);
    });
  });

  group('status kodlarini talqin qilish', () {
    test('5xx — server yiqilgani', () {
      for (final int code in [500, 502, 503, 504]) {
        expect(BackendHealth.isServerFailureStatus(code), isTrue,
            reason: '$code server tomonidagi yiqilish');
      }
    });

    test('ApiProvider ning manfiy kodlari ham yiqilish', () {
      for (final int code in [0, -1, -2]) {
        expect(BackendHealth.isServerFailureStatus(code), isTrue);
      }
    });

    test('4xx holatni BUZMAYDI — server tirik, shunchaki rad etdi', () {
      for (final int code in [400, 401, 403, 404, 409, 422]) {
        expect(BackendHealth.isServerFailureStatus(code), isFalse,
            reason: '$code javob bergan server ishlayotgan server');
      }
    });

    test('401 bir necha marta kelsa ham oflayn rejimga o\'tmaydi', () async {
      for (int i = 0; i < 10; i++) {
        BackendHealth.recordStatusCode(401);
      }
      await pumpEventQueue();
      expect(BackendHealth.isUp, isTrue,
          reason: 'noto\'g\'ri token butun kassani oflayn qilib qo\'ymasin');
    });

    test('ketma-ket 500 lar (va o\'lik server) oflayn rejimga o\'tkazadi',
        () async {
      for (int i = 0; i < 3; i++) {
        BackendHealth.recordStatusCode(500);
      }
      await pumpEventQueue();
      expect(BackendHealth.isDown, isTrue);
    });
  });

  group('tarmoq istisnolari', () {
    test('timeout va socket xatolari — yiqilish', () {
      expect(
          BackendHealth.isNetworkFailure(TimeoutException('yo\'q')), isTrue);
      expect(BackendHealth.isNetworkFailure(const SocketException('yo\'q')),
          isTrue);
    });

    test('boshqa xatolar serverning holatiga aloqador emas', () {
      expect(BackendHealth.isNetworkFailure(FormatException('json')), isFalse);
      expect(BackendHealth.isNetworkFailure(ArgumentError('x')), isFalse);
    });
  });

  group('so\'rov darvozasi (gate)', () {
    test('up holatida hamma so\'rov o\'tadi', () {
      expect(BackendHealth.allowRequest(), isTrue);
      expect(BackendHealth.allowRequest(), isTrue);
    });

    test('down holatida so\'rovlar to\'siladi', () async {
      await _forceDown();
      // Yiqilish paytida birinchi tekshiruv vaqti belgilanadi, shuning
      // uchun keyingi so'rov darhol o'tmasligi kerak.
      expect(BackendHealth.allowRequest(), isFalse,
          reason: 'kassir har amalda 30 soniya kutmasligi kerak');
    });

    test('har 30 soniyada bitta tekshiruv o\'tkaziladi', () async {
      final DateTime t0 = DateTime(2026, 9, 2, 10);
      BackendHealth.now = () => t0;
      await _forceDown();

      expect(BackendHealth.allowRequest(), isFalse);

      BackendHealth.now = () => t0.add(const Duration(seconds: 29));
      expect(BackendHealth.allowRequest(), isFalse);

      BackendHealth.now = () => t0.add(const Duration(seconds: 30));
      expect(BackendHealth.allowRequest(), isTrue, reason: 'half-open probe');

      // Tekshiruv o'tkazilgach yana yopiladi.
      expect(BackendHealth.allowRequest(), isFalse);
    });

    test('force — foydalanuvchi bosgan tugma doim o\'tadi', () async {
      await _forceDown();
      expect(BackendHealth.allowRequest(force: true), isTrue,
          reason: 'kassir o\'zi bosgan amal javobsiz qolmasin');
    });
  });

  group('isUsable', () {
    test('server down bo\'lsa internet tekshirilmaydi ham', () async {
      bool internetChecked = false;
      BackendHealth.internetCheck = () async {
        internetChecked = true;
        return true;
      };
      await _forceDown();

      expect(await BackendHealth.isUsable(), isFalse);
      expect(internetChecked, isFalse,
          reason: 'server yiqilgani ma\'lum — ping qilishning hojati yo\'q');
    });

    test('server up, internet yo\'q — foydalanib bo\'lmaydi', () async {
      BackendHealth.internetCheck = () async => false;
      expect(await BackendHealth.isUsable(), isFalse);
    });

    test('server up va internet bor — foydalanish mumkin', () async {
      BackendHealth.internetCheck = () async => true;
      expect(await BackendHealth.isUsable(), isTrue);
    });
  });
}

/// Serverni "o'lgan" deb belgilaydi: chegaragacha xato + tekshiruv ham yiqiladi.
Future<void> _forceDown() async {
  BackendHealth.probeRequest = () async => false;
  for (int i = 0; i < BackendHealth.failureThreshold; i++) {
    BackendHealth.recordFailure();
  }
  await pumpEventQueue();
}
