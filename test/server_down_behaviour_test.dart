// Server yiqilganda kassa qanday ishlashi — UCHDAN-UCHGA testlar.
//
// Nega bu testlar soxta (mock) emas, HAQIQIY HTTP server bilan: biz aynan
// tarmoq qatlamidagi xulqni tekshirmoqchimiz — 500 javob, javobsiz osilib
// qolgan ulanish, ulanishning rad etilishi. Bularni mock bilan ishonchli
// takrorlab bo'lmaydi: 2026-09-02 dagi to'xtash sabablaridan biri aynan
// GET so'rovida timeout yo'qligi edi, buni faqat haqiqiy osilgan ulanish
// ko'rsatib beradi.
//
// Testlar lokal `HttpServer` ko'taradi va `HttpOverrides` orqali ilovaning
// barcha so'rovlarini o'sha serverga yo'naltiradi. Ya'ni `ApiProvider` ning
// o'zi, o'zgartirilmagan holda sinovdan o'tadi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/util_functions.dart';

/// Test serverining xulqi.
enum ServerMode {
  /// Normal ishlayotgan server.
  ok,

  /// Server yiqilgan — 500 qaytaradi.
  error500,

  /// Server javob BERMAYDI: ulanish ochiq qoladi, javob kelmaydi.
  /// Yiqilgan serverda eng xavfli holat — ilova cheksiz kutishi mumkin.
  hang,

  /// Server so'rovni rad etdi (biznes xatosi) — server TIRIK.
  unauthorized401,

  /// Server QISMAN ishlayapti: xodimlar ro'yxatini beradi, lekin rollarni
  /// bermaydi (500). Eng xavfli holat — yarim yozilgan ma'lumot.
  partialEmployees,

  /// Server SOG'LOM, lekin bitta so'rov (chek yuborish) unda xatoga olib
  /// keladi — faqat `order_pos` 500 qaytaradi.
  poisonedOrderPos,
}

/// Chegaraga yetilgach `BackendHealth` serverning tirikligini TEKSHIRIB
/// ko'radi (tasdiqlovchi so'rov) va qarorni shundan keyin qabul qiladi.
/// Bu asinxron bo'lgani uchun testlar qarorni kutishi kerak.
Future<void> _waitDown({
  Duration timeout = const Duration(seconds: 15),
}) async {
  final Stopwatch sw = Stopwatch()..start();
  while (!BackendHealth.isDown && sw.elapsed < timeout) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HttpServer server;

  ServerMode mode = ServerMode.ok;
  int hits = 0;

  /// Serverga kelgan so'rovlar: "PATH BODY". Tartibni tekshirish uchun.
  final List<String> requestLog = [];

  const Map<String, String> headers = {'Content-Type': 'application/json'};

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('server_down_test');
    Hive.init(tempDir.path);

    void reg<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
    }

    reg(27, LogModelAdapter());
    reg(0, EmployeeAdapter());
    reg(2, EmployeeAccessAdapter());
    reg(101, EmployeeUserAdapter());
    reg(102, EmployeeRoleAdapter());

    await Hive.openBox<dynamic>('prefs');
    await Hive.openBox<LogModel>('logs');
    await Hive.openBox<LogModel>('tg_logs');
    await Hive.openBox<Employee>('employees');

    // Testda Telegramga haqiqiy xabar ketmasin.
    await Pref.setBool(PrefKeys.isSendToTelegram, false);

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      hits++;
      String body = '';
      try {
        body = await utf8.decoder.bind(request).join();
      } catch (_) {}
      requestLog.add('${request.uri.path} $body');
      if (mode == ServerMode.poisonedOrderPos) {
        final bool poisoned = request.uri.path.contains('order_pos');
        request.response.statusCode = poisoned ? 500 : 200;
        request.response.write(poisoned
            ? '{"message":"cannot process this order"}'
            : '{"message":"Success"}');
        await request.response.close();
        return;
      }
      if (mode == ServerMode.partialEmployees) {
        if (request.uri.path.contains('role_with_permissions')) {
          request.response.statusCode = 500;
          request.response.write('{"message":"Internal Server Error"}');
        } else {
          request.response.statusCode = 200;
          request.response.write(
              '{"employees":[{"user":{"id":"u-1","first_name":"Yangi",'
              '"pass_code":"9999"},"role":{"id":"r-1","name":"Kassir"}}]}');
        }
        await request.response.close();
        return;
      }
      switch (mode) {
        case ServerMode.ok:
          request.response.statusCode = 200;
          request.response.write('{"message":"Success"}');
          await request.response.close();
          break;
        case ServerMode.error500:
          request.response.statusCode = 500;
          request.response.write('{"message":"Internal Server Error"}');
          await request.response.close();
          break;
        case ServerMode.unauthorized401:
          request.response.statusCode = 401;
          request.response.write('{"message":"Unauthorized"}');
          await request.response.close();
          break;
        case ServerMode.hang:
          // Ataylab hech narsa qilmaymiz: ulanish ochiq, javob yo'q.
          break;
      }
    });

    _RedirectHttpOverrides.targetPort = server.port;
    HttpOverrides.global = _RedirectHttpOverrides();

    // Tasdiqlovchi (probe) so'rov ham shu test serveriga borishi kerak —
    // odatda buni `main()` sozlaydi, testda `main()` ishlamaydi.
    BackendHealth.configureProbeUrl(ApiProvider.baseUrlINVAN2);
  });

  tearDownAll(() async {
    HttpOverrides.global = null;
    await server.close(force: true);
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() {
    BackendHealth.reset();
    BackendHealth.autoProbe = false; // haqiqiy taymer testda kerak emas
    BackendHealth.now = DateTime.now;
    BackendHealth.internetCheck = () async => true;
    mode = ServerMode.ok;
    hits = 0;
    requestLog.clear();
  });

  tearDown(() {
    BackendHealth.reset();
    BackendHealth.autoProbe = true;
    BackendHealth.now = DateTime.now;
  });

  group('Server 500 qaytaradi', () {
    test('ketma-ket 500 lar kassani oflayn rejimga o\'tkazadi', () async {
      mode = ServerMode.error500;

      for (int i = 0; i < BackendHealth.failureThreshold; i++) {
        final HttpResult res = await ApiProvider.getResponse(
            path: 'api/v1/shift_statuses', headers: headers);
        expect(res.isSuccess, isFalse);
      }

      await _waitDown();
      expect(BackendHealth.isDown, isTrue,
          reason: 'server yiqilgani aniqlanishi kerak');
      expect(
        requestLog.where((r) => r.contains('shift_statuses')).length,
        greaterThanOrEqualTo(BackendHealth.failureThreshold),
      );
    });

    test('oflayn rejimda so\'rovlar serverga UMUMAN yuborilmaydi', () async {
      mode = ServerMode.error500;
      for (int i = 0; i < 3; i++) {
        await ApiProvider.getResponse(path: 'api/v1/cashbox', headers: headers);
      }
      await _waitDown();
      expect(BackendHealth.isDown, isTrue);
      final int hitsWhenDown = hits;

      final Stopwatch sw = Stopwatch()..start();
      for (int i = 0; i < 20; i++) {
        final HttpResult res =
            await ApiProvider.getResponse(path: 'api/v1/cashbox', headers: headers);
        expect(res.statusCode, BackendHealth.serverDownStatusCode);
        expect(res.isSuccess, isFalse);
      }
      sw.stop();

      expect(hits, hitsWhenDown,
          reason: '20 ta so\'rov serverga umuman bormasligi kerak');
      expect(sw.elapsedMilliseconds, lessThan(1000),
          reason: 'kassir har amalda kutmasligi kerak — javob darhol keladi');
    });

    test('POST ham, PUT ham xuddi shunday darvozadan o\'tmaydi', () async {
      mode = ServerMode.error500;
      for (int i = 0; i < 3; i++) {
        await ApiProvider.postResponse(
            path: 'api/v1/order_pos', body: '{}', headers: headers);
      }
      await _waitDown();
      expect(BackendHealth.isDown, isTrue);
      final int hitsWhenDown = hits;

      final HttpResult post = await ApiProvider.postResponse(
          path: 'api/v1/order_pos', body: '{}', headers: headers);
      final HttpResult put = await ApiProvider.putResponse(
          path: 'api/v1/order_pos', body: '{}', headers: headers);

      expect(post.statusCode, BackendHealth.serverDownStatusCode);
      expect(put.statusCode, BackendHealth.serverDownStatusCode);
      expect(hits, hitsWhenDown);
    });
  });

  group('Server javob bermaydi (osilib qoladi)', () {
    test(
      'GET cheksiz kutmaydi — timeout bilan tugaydi',
      () async {
        mode = ServerMode.hang;

        final Stopwatch sw = Stopwatch()..start();
        final HttpResult res = await ApiProvider.getResponse(
            path: 'api/v1/employee?limit=100', headers: headers);
        sw.stop();

        expect(res.isSuccess, isFalse);
        expect(res.statusCode, -1, reason: 'timeout kodi');
        expect(sw.elapsed.inSeconds, lessThan(25),
            reason: 'ilgari bu so\'rov CHEKSIZ osilib qolardi — '
                'startup shu sababdan muzlardi');
        expect(BackendHealth.consecutiveFailures, 1);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'javobsiz server ham kassani oflayn rejimga o\'tkazadi',
      () async {
        mode = ServerMode.hang;
        for (int i = 0; i < BackendHealth.failureThreshold; i++) {
          await ApiProvider.getResponse(
              path: 'api/v1/current_company', headers: headers);
        }
        // Tasdiqlovchi so'rov ham javobsiz serverga boradi — u timeout
        // bilan tugagach qaror qabul qilinadi.
        await _waitDown();
        expect(BackendHealth.isDown, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });

  group('Server umuman ulanmaydi', () {
    test('ulanish rad etilsa ham oflayn rejimga o\'tadi', () async {
      // Hech kim tinglamayotgan portga yo'naltiramiz.
      final int realPort = _RedirectHttpOverrides.targetPort;
      final ServerSocket dead =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final int deadPort = dead.port;
      await dead.close();
      _RedirectHttpOverrides.targetPort = deadPort;

      try {
        for (int i = 0; i < BackendHealth.failureThreshold; i++) {
          final HttpResult res = await ApiProvider.getResponse(
              path: 'api/v1/shop/1', headers: headers);
          expect(res.isSuccess, isFalse);
        }
        await _waitDown();
        expect(BackendHealth.isDown, isTrue);
      } finally {
        _RedirectHttpOverrides.targetPort = realPort;
      }
    });
  });

  group('Server TIRIK, lekin so\'rovni rad etadi', () {
    test('401 lar kassani oflayn rejimga tashlamaydi', () async {
      mode = ServerMode.unauthorized401;

      for (int i = 0; i < 10; i++) {
        final HttpResult res = await ApiProvider.getResponse(
            path: 'api/v1/current_company', headers: headers);
        expect(res.statusCode, 401);
      }

      expect(BackendHealth.isUp, isTrue,
          reason: 'javob bergan server — ishlayotgan server; noto\'g\'ri '
              'token butun kassani oflayn qilib qo\'ymasligi kerak');
      expect(hits, 10, reason: 'so\'rovlar to\'silmasligi kerak');
    });
  });

  group('Server tiklanishi', () {
    test('tiklangach so\'rovlar yana o\'tadi va navbat qo\'zg\'aladi',
        () async {
      int recovered = 0;
      BackendHealth.onRecovered = () => recovered++;

      mode = ServerMode.error500;
      for (int i = 0; i < 3; i++) {
        await ApiProvider.getResponse(path: 'api/v1/cashbox', headers: headers);
      }
      await _waitDown();
      expect(BackendHealth.isDown, isTrue);

      // Server tiklandi, lekin ilova buni hali bilmaydi.
      mode = ServerMode.ok;
      final HttpResult blocked =
          await ApiProvider.getResponse(path: 'api/v1/cashbox', headers: headers);
      expect(blocked.statusCode, BackendHealth.serverDownStatusCode,
          reason: 'tekshiruv oralig\'i hali o\'tmagan');

      // 30 soniya o'tdi — endi bitta tekshiruv so'rovi o'tkaziladi.
      final DateTime future =
          DateTime.now().add(const Duration(seconds: 31));
      BackendHealth.now = () => future;

      final HttpResult res =
          await ApiProvider.getResponse(path: 'api/v1/cashbox', headers: headers);

      expect(res.isSuccess, isTrue);
      expect(BackendHealth.isUp, isTrue);
      expect(recovered, 1,
          reason: 'navbatdagi cheklar/smena shu callback bilan yuboriladi');
    });

    test('kassir qo\'lda bosgan amal darvozadan darhol o\'tadi', () async {
      mode = ServerMode.error500;
      for (int i = 0; i < 3; i++) {
        await ApiProvider.getResponse(path: 'api/v1/cashbox', headers: headers);
      }
      await _waitDown();
      expect(BackendHealth.isDown, isTrue);
      mode = ServerMode.ok;

      // Oddiy so'rov — to'siladi.
      final HttpResult blocked =
          await ApiProvider.getResponse(path: 'api/v1/cashbox', headers: headers);
      expect(blocked.statusCode, BackendHealth.serverDownStatusCode);

      // Login (force: true) — o'tadi.
      final HttpResult login = await ApiProvider.postResponse(
          path: 'auth/login', body: '{}', headers: headers, force: true);
      expect(login.isSuccess, isTrue,
          reason: 'kassir "Kirish" bosganda javobsiz qolmasligi kerak');
      expect(BackendHealth.isUp, isTrue);
    });
  });

  // Foydalanuvchi savoli (2026-09-02): "bitta sotuv 500 qaytarsa, uni qayta
  // yuborganda yana 500 qaytishi mumkin — shunda kassa oflayn bo'lib
  // qoladimi yoki chek 'rad etilgan' deb hisoblanadimi?"
  group('Bitta so\'rov 500 beradi, server esa SOG\'LOM', () {
    test('kassa oflayn rejimga O\'TMAYDI', () async {
      mode = ServerMode.poisonedOrderPos;

      // Xuddi ketmagan chekni qayta-qayta yuborgandek.
      for (int i = 0; i < 5; i++) {
        final HttpResult res = await ApiProvider.postResponse(
            path: 'api/v1/order_pos', body: '{}', headers: headers);
        expect(res.statusCode, 500);
      }

      // Tasdiqlovchi so'rov serverga boradi va 200 oladi.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(BackendHealth.isUp, isTrue,
          reason: 'server javob beryapti — muammo aynan shu so\'rovda; '
              'butun kassani uzib qo\'yish xato bo\'lardi');
      expect(BackendHealth.lastFalseAlarm, isNotNull);
      expect(BackendHealth.lastFalseAlarm!.paths,
          contains('api/v1/order_pos'));
    });

    test('bunday chek RAD ETILGAN deb belgilanadi (kassir ko\'rishi uchun)',
        () async {
      mode = ServerMode.poisonedOrderPos;
      final HttpResult res = await ApiProvider.postResponse(
          path: 'api/v1/order_pos', body: '{}', headers: headers);
      expect(res.statusCode, 500);

      // Server tirik javob beryapti → ayb chekda.
      expect(await BackendHealth.isDocumentRejection(res.statusCode), isTrue,
          reason: 'aks holda buzuq chek abadiy qayta yuborilaverar va '
              'kassir muammoni umuman ko\'rmasdi');
    });

    test('server O\'CHGANDA esa xuddi shu 500 rad etish HISOBLANMAYDI',
        () async {
      mode = ServerMode.error500; // hamma so'rov 500 — server yiqilgan
      final HttpResult res = await ApiProvider.postResponse(
          path: 'api/v1/order_pos', body: '{}', headers: headers);
      expect(res.statusCode, 500);

      expect(await BackendHealth.isDocumentRejection(res.statusCode), isFalse,
          reason: 'outage paytida sog\'lom cheklar navbatdan chiqib '
              'ketmasligi kerak');
    });

    test('boshqa so\'rovlar bemalol ishlayveradi', () async {
      mode = ServerMode.poisonedOrderPos;
      for (int i = 0; i < 4; i++) {
        await ApiProvider.postResponse(
            path: 'api/v1/order_pos', body: '{}', headers: headers);
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final HttpResult other = await ApiProvider.getResponse(
          path: 'api/v1/shift_statuses', headers: headers);
      expect(other.isSuccess, isTrue,
          reason: 'smena ochish kabi amallar to\'silmasligi kerak');
    });
  });

  group('Server QISMAN ishlaganda xodim ruxsatlari', () {
    test('rollar 500 bersa lokal baza TEGILMAYDI', () async {
      final Box<Employee> box = Hive.box<Employee>('employees');
      await box.clear();

      // Eskidan ishlayotgan xodim — ruxsatlari bilan.
      final Employee old = Employee(
        user: EmployeeUser(id: 'u-1', firstName: 'Eski', passCode: '1111'),
        role: EmployeeRole(id: 'r-1', name: 'Kassir'),
        access: EmployeeAccess(creatNewSale: true, receiptHistory: true),
      );
      await box.put('u-1', old);

      mode = ServerMode.partialEmployees;
      final String? error = await UtilFunctions.fullUpdateEmployee();

      expect(error, isNotNull, reason: 'yangilanish yiqilgani aytilishi kerak');
      expect(box.length, 1);
      final Employee kept = box.get('u-1')!;
      expect(kept.user?.passCode, '1111',
          reason: 'eski (ishlaydigan) ma\'lumot saqlanib qolishi kerak');
      expect(kept.access?.creatNewSale, isTrue,
          reason: 'RUXSATLAR YO\'QOLMASLIGI KERAK — ilgari shu yerda '
              'access=null bo\'lib qolar va kassir sotolmay qolardi');
    });
  });

  group('Smena navbati — server o\'chgan kun stsenariysi', () {
    setUp(() async {
      await Pref.setString(PrefKeys.openedDate, '');
      await Pref.setString(PrefKeys.closedDate, '');
      await Pref.setInt(PrefKeys.openedCount, 0);
      await Pref.setInt(PrefKeys.closedCount, 0);
    });

    test('ertalab oflayn ochilgan + kechqurun oflayn yopilgan smena — '
        'serverga AVVAL ochish, KEYIN yopish ketadi', () async {
      // Server o'chgan kun: ikkalasi ham navbatda qoldi.
      await Pref.setString(PrefKeys.openedDate, '2026-09-02 09:00:00');
      await Pref.setInt(PrefKeys.openedCount, 1);
      await Pref.setString(PrefKeys.closedDate, '2026-09-02 21:00:00');
      await Pref.setInt(PrefKeys.closedCount, 1);

      // Ertasiga server ko'tarildi.
      mode = ServerMode.ok;
      await ShiftSyncQueue.flush(reason: 'test');

      final List<String> shiftCalls =
          requestLog.where((r) => r.contains('shift_pos')).toList();
      expect(shiftCalls.length, 2, reason: 'ikkalasi ham yuborilishi kerak');
      expect(shiftCalls.first.contains('"method":"open"'), isTrue,
          reason: 'ochilmagan smenani yopib bo\'lmaydi — tartib muhim');
      expect(shiftCalls.last.contains('"method":"close"'), isTrue);

      expect(ShiftSyncQueue.hasPending, isFalse,
          reason: 'ikkalasi ketgach navbat bo\'shashi kerak');
    });

    test('oldingi smena yopilishi navbatda, keyin yangi smena ochilgan — '
        'AVVAL yopish ketadi', () async {
      await Pref.setString(PrefKeys.closedDate, '2026-09-02 08:00:00');
      await Pref.setInt(PrefKeys.closedCount, 1);
      await Pref.setString(PrefKeys.openedDate, '2026-09-02 09:00:00');
      await Pref.setInt(PrefKeys.openedCount, 1);

      await ShiftSyncQueue.flush(reason: 'test');

      final List<String> shiftCalls =
          requestLog.where((r) => r.contains('shift_pos')).toList();
      expect(shiftCalls.length, 2);
      expect(shiftCalls.first.contains('"method":"close"'), isTrue);
      expect(shiftCalls.last.contains('"method":"open"'), isTrue);
    });

    test('server hali ham o\'chiq bo\'lsa navbat SAQLANADI', () async {
      await Pref.setString(PrefKeys.openedDate, '2026-09-02 09:00:00');
      await Pref.setInt(PrefKeys.openedCount, 1);
      await Pref.setString(PrefKeys.closedDate, '2026-09-02 21:00:00');
      await Pref.setInt(PrefKeys.closedCount, 1);

      mode = ServerMode.error500;
      await ShiftSyncQueue.flush(reason: 'test');

      expect(ShiftSyncQueue.hasPendingOpen, isTrue);
      expect(ShiftSyncQueue.hasPendingClose, isTrue,
          reason: 'yuborilmagan yopish yo\'qolmasligi kerak');

      // Birinchi qadam (ochish) yiqilgach ikkinchisi urinilmasligi kerak:
      // ochilmagan smenani yopishga urinish server uchun ma'nosiz.
      final List<String> shiftCalls =
          requestLog.where((r) => r.contains('shift_pos')).toList();
      expect(shiftCalls.length, 1);
    });
  });
}

/// Ilovaning barcha HTTP so'rovlarini lokal test serveriga yo'naltiradi.
///
/// `ApiProvider` manzili `const` — uni testdan o'zgartirib bo'lmaydi.
/// Shuning uchun kod emas, TRANSPORT almashtiriladi: ilova o'zi
/// o'zgartirilmagan holda sinovdan o'tadi.
class _RedirectHttpOverrides extends HttpOverrides {
  static int targetPort = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _RedirectHttpClient(super.createHttpClient(context), () => targetPort);
}

class _RedirectHttpClient implements HttpClient {
  _RedirectHttpClient(this._inner, this._port);

  final HttpClient _inner;
  final int Function() _port;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _inner.openUrl(
        method,
        url.replace(scheme: 'http', host: '127.0.0.1', port: _port()),
      );

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set badCertificateCallback(
          bool Function(X509Certificate cert, String host, int port)? cb) =>
      _inner.badCertificateCallback = cb;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  String? get userAgent => _inner.userAgent;

  /// Qolgan a'zolar bu testda ishlatilmaydi.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
