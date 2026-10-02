// Smena navbati — "haqiqiy serverga o'xshash" stend.
//
// Nima uchun: smena ochish/yopishning serverga yetishi kassaning eng nozik
// joyi. Kassir har xil ketma-ketlik qiladi (ochdi-yopdi-ochdi...), tarmoq esa
// istalgan paytda uzilishi, server yiqilishi, javob yo'qolishi mumkin.
//
// Stend:
// - lokal HTTP server kassa holatini (ochiq/yopiq) ESLAYDI va noto'g'ri
//   o'tishni (ochiq kassani ochish, yopiq kassani yopish) RAD ETADI — xuddi
//   haqiqiy backend kabi. Rad etish kodi sozlanadi (400/409/500/200/403),
//   chunki haqiqiy server aynan qaysi kodni qaytarishi jonli tekshirilmagan;
// - uzilishlar qo'lda beriladi: server 500, internet yo'q (ulanish uziladi),
//   Wi-Fi login sahifasi (200 + HTML), token eskirgan (401), javob yo'qolishi
//   (server bajardi, lekin javob kassaga yetmadi);
// - ilovaning HAQIQIY kodi ishlaydi: ShiftSingleton4.openShift,
//   ShiftSingleton4.syncCloseToServer, ShiftSyncQueue, ShiftApi4, ApiProvider,
//   BackendHealth. Faqat transport lokal serverga yo'naltiriladi.
//
// Asosiy talab — har qanday ketma-ketlikdan keyin, aloqa tiklangach:
// 1. navbat bo'sh (hech narsa tiqilib qolmagan);
// 2. serverdagi kassa holati kassadagi bilan bir xil;
// 3. server qabul qilgan amallar = kassir bajargan amallar: aynan shu
//    tartibda, aynan shu vaqtlar bilan, har biri BIR martadan.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

/// Tarmoq / server holati.
enum _Net {
  /// Hammasi ishlaydi.
  up,

  /// Server yiqilgan — har so'rovga 500.
  down500,

  /// Internet yo'q — ulanish javobsiz uziladi.
  internetOff,

  /// Wi-Fi login sahifasi: har so'rovga 200 + HTML.
  captivePortal,

  /// Token eskirgan — har so'rovga 401.
  unauthorized,
}

/// Kassa holatini eslaydigan soxta backend.
class _FakeBackend {
  late HttpServer _http;

  _Net net = _Net.up;

  /// Noto'g'ri o'tishga (ochiq kassani ochish / yopiq kassani yopish) server
  /// javobi. 200 — "idempotent" server: xato demaydi, holat o'zgarmaydi.
  int rejectStatus = 400;

  /// Keyingi ochish/yopish BAJARILADI, lekin javob kassaga yetmaydi.
  bool loseNextResponse = false;

  /// Keyingi ochish/yopish BAJARILMAYDI va shu status qaytadi — server
  /// bir lahzaga yiqildi (qayta ishga tushyapti), so'ng darhol tirildi.
  int? failNextMutationWith;

  /// Server ochishni DOIMIY rad etadi (masalan validatsiya xatosi) — kassa
  /// yopiq bo'lsa ham.
  bool refuseOpens = false;

  /// Backend'da o'chirilgan kassirlar: ularning ochish/yopishiga haqiqiy
  /// server 500 "sql: no rows in result set" qaytaradi (jonli dev sinovi).
  final Set<String> unknownUsers = {};

  /// cashbox_id → serverda ochiqmi.
  final Map<String, bool> open = {};

  /// Server qabul qilgan amallar: `open@vaqt@kassa`.
  final List<String> accepted = [];

  int get port => _http.port;

  Future<void> start() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen(_handle);
  }

  Future<void> stop() => _http.close(force: true);

  void reset() {
    net = _Net.up;
    rejectStatus = 400;
    loseNextResponse = false;
    failNextMutationWith = null;
    refuseOpens = false;
    unknownUsers.clear();
    open
      ..clear()
      ..['kassa-1'] = false;
    accepted.clear();
  }

  Future<void> _handle(HttpRequest req) async {
    final String body = await utf8.decoder.bind(req).join();
    switch (net) {
      case _Net.internetOff:
        await _drop(req);
        return;
      case _Net.down500:
        await _reply(req, 500, '{"message":"Internal Server Error"}');
        return;
      case _Net.unauthorized:
        await _reply(req, 401, '{"message":"Unauthorized"}');
        return;
      case _Net.captivePortal:
        await _reply(req, 200, '<html><body>Wi-Fi login</body></html>');
        return;
      case _Net.up:
        break;
    }

    final String path = req.uri.path;
    if (path.endsWith('shift_statuses')) {
      final List<Map<String, dynamic>> list = open.entries
          .map((e) => <String, dynamic>{
                'cashbox_id': e.key,
                'cashbox_name': 'Kassa ${e.key}',
                'status': e.value ? 'open' : 'closed',
                'opened_by_pos': e.value,
                'opened_by_web': false,
                'opened_by_user_id': e.value ? 'kimdir' : '',
              })
          .toList();
      await _reply(req, 200, jsonEncode(list));
      return;
    }

    if (path.endsWith('shift_pos')) {
      final Map<String, dynamic> data = jsonDecode(body);
      final String cashbox = '${data['cashbox_id']}';
      final bool wantsOpen = data['method'] == 'open';
      final String at =
          wantsOpen ? '${data['opened_at']}' : '${data['closed_at']}';
      final bool isOpen = open[cashbox] ?? false;
      final int? fail = failNextMutationWith;
      if (fail != null) {
        failNextMutationWith = null;
        await _reply(req, fail, '{"message":"temporarily unavailable"}');
        return;
      }
      if (wantsOpen && refuseOpens) {
        await _reply(req, 400, '{"message":"validation failed"}');
        return;
      }
      if (unknownUsers.contains('${data['user_id']}')) {
        await _reply(req, 500,
            '{"error":"rpc error: code = Unknown desc = sql: no rows in result set"}');
        return;
      }
      if (wantsOpen == isOpen) {
        await _reply(
          req,
          rejectStatus,
          wantsOpen
              ? '{"message":"cashbox already open"}'
              : '{"message":"cashbox is not open"}',
        );
        return;
      }
      open[cashbox] = wantsOpen;
      accepted.add('${data['method']}@$at@$cashbox');
      if (loseNextResponse) {
        loseNextResponse = false;
        await _drop(req);
        return;
      }
      await _reply(req, 200, '{"message":"Success"}');
      return;
    }

    await _reply(req, 200, '{"message":"Success"}');
  }

  static Future<void> _reply(HttpRequest req, int status, String body) async {
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(body);
    await req.response.close();
  }

  /// Javobsiz uzish: ulanish yopiladi, kassa javob olmaydi.
  static Future<void> _drop(HttpRequest req) async {
    final Socket socket =
        await req.response.detachSocket(writeHeaders: false);
    socket.destroy();
  }
}

/// Ilovaning barcha HTTP so'rovlarini lokal serverga yo'naltiradi.
class _ToLocal extends HttpOverrides {
  _ToLocal(this.port);

  final int port;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _LocalClient(super.createHttpClient(context), port);
}

class _LocalClient implements HttpClient {
  _LocalClient(this._inner, this._port);

  final HttpClient _inner;
  final int _port;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _inner.openUrl(
      method, url.replace(scheme: 'http', host: '127.0.0.1', port: _port));

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `ShiftSingleton4.openShift` kontekstdan foydalanmaydi.
class _FakeContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final _FakeBackend backend = _FakeBackend();
  final BuildContext ctx = _FakeContext();
  final DateFormat fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  DateTime simTime = DateTime.utc(2026, 10, 2, 3);

  /// Kassir kassada bajargan amallar: `open@vaqt@kassa`.
  final List<String> posLog = [];

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('shift_queue_scenarios');
    Hive.init(tempDir.path);

    void reg<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
    }

    reg(27, LogModelAdapter());
    reg(0, EmployeeAdapter());
    reg(2, EmployeeAccessAdapter());
    reg(101, EmployeeUserAdapter());
    reg(102, EmployeeRoleAdapter());
    reg(30, ShiftModelHiveAdapter());
    reg(31, CashDrawerHiveAdapter());
    reg(32, SalesSummaryHiveAdapter());
    reg(33, PaysHiveAdapter());

    await Hive.openBox<dynamic>('prefs');
    await Hive.openBox<LogModel>('logs');
    await Hive.openBox<LogModel>('tg_logs');
    await Hive.openBox<Employee>('employees');
    await Hive.openBox<ShiftModelHive>('shifts');

    // Testda Telegramga haqiqiy xabar ketmasin.
    await Pref.setBool(PrefKeys.isSendToTelegram, false);

    await backend.start();
    HttpOverrides.global = _ToLocal(backend.port);
    BackendHealth.configureProbeUrl(ApiProvider.baseUrlINVAN2);
  });

  tearDownAll(() async {
    ShiftSingleton4.clock = DateTime.now;
    ShiftSyncQueue.now = DateTime.now;
    BackendHealth.reset();
    BackendHealth.autoProbe = true;
    HttpOverrides.global = null;
    await backend.stop();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  void setNet(_Net net) {
    backend.net = net;
    BackendHealth.internetCheck = () async => net != _Net.internetOff;
  }

  /// Server/internet tiklandi va `BackendHealth` buni sezdi (ilovada buni
  /// fon tekshiruvi qiladi).
  void recovered() {
    setNet(_Net.up);
    BackendHealth.reset();
  }

  /// Fonda ketayotgan yuborishlar tugashi uchun.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  /// Aloqa tiklangach ilova navbatni oxirigacha yuboradi.
  Future<void> deliverAll() async {
    recovered();
    final Stopwatch sw = Stopwatch()..start();
    while (ShiftSyncQueue.hasPending && sw.elapsed.inSeconds < 10) {
      // Ilovada `BackendHealth` fon tekshiruvi (har 30 soniyada) server
      // tirikligini o'zi aniqlaydi va holatni `up` qiladi. Testda fon
      // tekshiruvi o'chiq — eskirgan tasdiqlovchi so'rov holatni `down`
      // qilib qo'yishi mumkin, shuning uchun o'sha tiklanishni shu yerda
      // qaytaramiz.
      BackendHealth.reset();
      await ShiftSyncQueue.flush(reason: 'test-final');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await settle();
  }

  Future<void> resetWorld() async {
    await settle();
    backend.reset();
    BackendHealth.reset();
    BackendHealth.autoProbe = false;
    BackendHealth.now = DateTime.now;
    BackendHealth.internetCheck = () async => true;
    await Pref.setString(PrefKeys.shiftSyncQueue, '');
    await Pref.setString(PrefKeys.openedDate, '');
    await Pref.setString(PrefKeys.closedDate, '');
    await Pref.setInt(PrefKeys.openedCount, 0);
    await Pref.setInt(PrefKeys.closedCount, 0);
    await Pref.setBool(PrefKeys.shiftsOpened, false);
    await Pref.setString(PrefKeys.activatedPosId, 'kassa-1');
    await Pref.setString(PrefKeys.userId, 'kassir-1');
    await Pref.setString(PrefKeys.token, 'test-token');
    await Hive.box<ShiftModelHive>('shifts').clear();
    simTime = DateTime.utc(2026, 10, 2, 3);
    ShiftSingleton4.clock = () => simTime;
    ShiftSyncQueue.now = DateTime.now;
    posLog.clear();
  }

  String kassa() => Pref.getString(PrefKeys.activatedPosId, '');

  bool posOpen() => Pref.getBool(PrefKeys.shiftsOpened, false);

  /// Kassir "Smena ochish"ni bosdi (`OpenShiftProvider.openShift` kabi).
  Future<bool?> cashierOpens() async {
    simTime = simTime.add(const Duration(minutes: 7));
    final bool? result =
        await ShiftSingleton4.openShift(ctx, startingCash: 0);
    await Pref.setBool(PrefKeys.shiftsOpened, result ?? false);
    if (result == true) posLog.add('open@${fmt.format(simTime)}@${kassa()}');
    return result;
  }

  /// Kassir "Smena yopish"ni bosdi (`OpenShiftProvider` oqimi: internet
  /// bo'lsa avval navbat yuboriladi, keyin yopiladi).
  Future<void> cashierCloses() async {
    simTime = simTime.add(const Duration(minutes: 7));
    if (await BackendHealth.isUsable() && ShiftSyncQueue.hasPending) {
      await ShiftSyncQueue.flush(reason: 'before-close');
    }
    await ShiftSingleton4.syncCloseToServer(
      closedAt: fmt.format(simTime),
      userId: Pref.getString(PrefKeys.userId, ''),
      cashboxId: kassa(),
    );
    posLog.add('close@${fmt.format(simTime)}@${kassa()}');
    expect(posOpen(), isFalse,
        reason: 'yopish kassada HAR DOIM bajarilishi kerak');
  }

  void expectConsistent([String label = '']) {
    expect(ShiftSyncQueue.hasPending, isFalse,
        reason: '$label\nnavbat tiqilib qoldi: ${ShiftSyncQueue.describe()}');
    expect(backend.open[kassa()] ?? false, posOpen(),
        reason: '$label\nserverdagi va kassadagi smena holati farq qiladi');
    expect(backend.accepted, posLog,
        reason: '$label\nserver qabul qilgan amallar kassir amallariga '
            'teng emas');
  }

  setUp(resetWorld);

  group('Aniq stsenariylar', () {
    test('server ertalabdan o\'chiq: ochish → yopish → ochish → yopish — '
        'server qaytgach to\'rttalasi tartib bilan yetadi', () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(backend.accepted, isEmpty);
      expect(ShiftSyncQueue.pendingCount, 4);

      await deliverAll();
      expectConsistent();
      expect(backend.accepted.length, 4);
    });

    test('internet yo\'q: xuddi shu ketma-ketlik', () async {
      setNet(_Net.internetOff);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      await deliverAll();
      expectConsistent();
    });

    test('ertalab server ishlagan → o\'chdi → yopish → yana ochish → server '
        'qaytdi (foydalanuvchi savoli)', () async {
      expect(await cashierOpens(), isTrue);
      expect(backend.open['kassa-1'], isTrue, reason: 'onlayn ochildi');

      setNet(_Net.down500);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);

      await deliverAll();
      expectConsistent();
    });

    test('server ertalabdan o\'chiq, kunduzi qaytdi, kechqurun yopildi — '
        'kechki yopish oflayn ochilishdan KEYIN yetadi', () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);

      // Server qaytdi, lekin navbat hali yuborilmadi (trigger kechikdi).
      recovered();
      await cashierCloses();

      await deliverAll();
      expectConsistent();
    });

    test('Wi-Fi login sahifasi (200 + HTML) — kassa oflayndagidek ishlaydi',
        () async {
      setNet(_Net.captivePortal);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(backend.accepted, isEmpty);

      await deliverAll();
      expectConsistent();
    });

    test('onlayn ochishning JAVOBI yo\'qoldi (server ochdi, kassa bilmadi) — '
        'takror yuborilmaydi, yopish to\'g\'ri yetadi', () async {
      backend.loseNextResponse = true;
      expect(await cashierOpens(), isTrue);
      expect(backend.open['kassa-1'], isTrue);
      expect(ShiftSyncQueue.pendingCount, 1,
          reason: 'javob kelmagani uchun ochish navbatga tushadi');

      await cashierCloses();
      await deliverAll();
      expectConsistent();
    });

    test('navbatdan yuborishda javob yo\'qoldi — server holatidan "bajarilgan" '
        'deb aniqlanadi, takror yuborilmaydi, qolganlari shu zahoti yetadi',
        () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);

      recovered();
      backend.loseNextResponse = true;
      await ShiftSyncQueue.flush(reason: 'backend-recovered');
      expect(ShiftSyncQueue.pendingCount, 0);
      expectConsistent();
    });

    test('yopishning javobi yo\'qoldi (onlayn) — kassa yopiq, server yopiq',
        () async {
      expect(await cashierOpens(), isTrue);
      backend.loseNextResponse = true;
      await cashierCloses();
      expect(backend.open['kassa-1'], isFalse);
      expect(ShiftSyncQueue.pendingCount, 1);

      await deliverAll();
      expectConsistent();
    });

    test('token eskirdi (401): yopish kassada bajariladi va saqlanadi; '
        'navbatda yetmagan voqea bor — ochish ham lokal bajariladi; token '
        'yangilangach hammasi yetadi', () async {
      expect(await cashierOpens(), isTrue);
      setNet(_Net.unauthorized);
      await cashierCloses();
      expect(ShiftSyncQueue.pendingCount, 1);

      // Server bizning yopilishimizni hali bilmaydi ("ochiq" deydi) — uning
      // eskirgan holatiga ishonib kassirni to'xtatib bo'lmaydi.
      expect(await cashierOpens(), isTrue);
      expect(ShiftSyncQueue.pendingCount, 2);

      await deliverAll();
      expectConsistent();
    });

    test('token eskirdi (401), navbat BO\'SH — ochish bloklanadi (dizayn: '
        'server tirik, lekin rad etyapti, lokal ochib yashirilmaydi)',
        () async {
      setNet(_Net.unauthorized);
      expect(await cashierOpens(), isFalse);
      expect(ShiftSyncQueue.hasPending, isFalse);
      expect(posOpen(), isFalse);
    });

    test('server ochilmagan kassani "ochiq" ko\'rsatyapti, navbat bo\'sh — '
        'ochish bloklanadi va sabab ko\'rsatiladi (o\'zgarmagan xulq)',
        () async {
      backend.open['kassa-1'] = true; // masalan, web orqali ochilgan
      expect(await cashierOpens(), isNull);
      expect(ShiftSyncQueue.hasPending, isFalse);
    });

    for (final int status in [409, 422, 500]) {
      test('server noto\'g\'ri o\'tishni $status bilan rad etsa ham navbat '
          'tiqilmaydi', () async {
        backend.rejectStatus = status;
        setNet(_Net.down500);
        expect(await cashierOpens(), isTrue);
        await cashierCloses();

        recovered();
        backend.loseNextResponse = true; // birinchi voqea takror ketadi
        await ShiftSyncQueue.flush(reason: 'backend-recovered');

        await deliverAll();
        expectConsistent();
      });
    }

    test('server takrorga 200 qaytarsa (idempotent) ham hammasi izchil',
        () async {
      backend.rejectStatus = 200;
      backend.loseNextResponse = true;
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);
      await deliverAll();
      expectConsistent();
    });

    test('server takrorni 403 bilan rad etsa ham — kassa holati allaqachon '
        'mosligi serverdan tekshiriladi, navbat tiqilmaydi', () async {
      backend.rejectStatus = 403;
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      recovered();
      backend.loseNextResponse = true;
      await ShiftSyncQueue.flush(reason: 'backend-recovered');
      // Kassa sotishda davom etadi, keyingi ochish/yopish ham yetadi.
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      await deliverAll();
      expectConsistent();
    });

    for (final int status in [500, 502, 503, 404]) {
      test('server bir lahza $status qaytardi va DARHOL tirildi — haqiqiy '
          'voqea tashlab yuborilmaydi (tasodifiy testda topilgan)', () async {
        setNet(_Net.down500);
        expect(await cashierOpens(), isTrue);
        await cashierCloses();
        expect(await cashierOpens(), isTrue);

        recovered();
        backend.failNextMutationWith = status; // birinchi voqea bajarilmaydi
        await ShiftSyncQueue.flush(reason: 'backend-recovered');
        expect(ShiftSyncQueue.pendingCount, 3,
            reason: 'server tirik chiqdi, lekin ochish unda AKS ETMAGAN — '
                'voqea navbatda qolishi shart');

        await deliverAll();
        expectConsistent();
      });
    }

    test('server ochishni DOIMIY rad etadi (holat mos emas) — navbat kutadi, '
        'hech narsa yo\'qolmaydi, kassa ishlashda davom etadi', () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      recovered();
      backend.refuseOpens = true;
      await ShiftSyncQueue.flush(reason: 'backend-recovered');
      expect(ShiftSyncQueue.pendingCount, 2,
          reason: 'ochish serverda yo\'q — tashlab yuborilmaydi');

      // Kassir bemalol ishlayveradi.
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(ShiftSyncQueue.pendingCount, 4);
      expect(backend.accepted, isEmpty);

      // Backend tuzatildi.
      backend.refuseOpens = false;
      await deliverAll();
      expectConsistent();
    });

    test('kassir backend\'da O\'CHIRILGAN (server 500 "sql: no rows") — '
        'voqea 1 soat kutadi, so\'ng hisobot bilan olib tashlanadi; navbat '
        'tiqilib qolmaydi', () async {
      DateTime clock = DateTime.now();
      ShiftSyncQueue.now = () => clock;

      setNet(_Net.down500);
      await Pref.setString(PrefKeys.userId, 'ochirilgan-kassir');
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      await Pref.setString(PrefKeys.userId, 'kassir-1');
      final List<String> poisoned = List<String>.of(posLog);

      recovered();
      backend.unknownUsers.add('ochirilgan-kassir');
      for (int i = 0; i < 6; i++) {
        await ShiftSyncQueue.flush(reason: 'receipts-uploaded');
        clock = clock.add(const Duration(minutes: 5));
      }
      expect(ShiftSyncQueue.pendingCount, 2,
          reason: '1 soat o\'tmaguncha haqiqiy voqea tashlanmaydi');
      expect(ShiftSyncQueue.pending.first.failures, greaterThanOrEqualTo(5));

      // Kassa baribir ishlaydi (to'g'ri kassir bilan).
      expect(await cashierOpens(), isTrue);

      clock = clock.add(const Duration(minutes: 61));
      await deliverAll();

      expect(ShiftSyncQueue.hasPending, isFalse,
          reason: 'zaharli voqea navbatni abadiy to\'smasligi kerak');
      expect(backend.open['kassa-1'], posOpen());
      expect(backend.accepted,
          posLog.where((e) => !poisoned.contains(e)).toList(),
          reason: 'faqat o\'chirilgan kassirning amallari yetmaydi');
    });

    test('tez-tez uzilish: har amaldan keyin tarmoq holati almashadi',
        () async {
      final List<_Net> pattern = [
        _Net.down500,
        _Net.up,
        _Net.internetOff,
        _Net.up,
        _Net.captivePortal,
        _Net.down500,
        _Net.up,
        _Net.internetOff,
      ];
      for (int i = 0; i < 16; i++) {
        final _Net net = pattern[i % pattern.length];
        if (net == _Net.up) {
          recovered();
        } else {
          setNet(net);
        }
        if (posOpen()) {
          await cashierCloses();
        } else {
          expect(await cashierOpens(), isTrue, reason: 'qadam $i ($net)');
        }
      }
      await deliverAll();
      expectConsistent();
    });

    test('kassir navbat yuborilayotgan PAYTDA smenani yopadi', () async {
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      expect(await cashierOpens(), isTrue);

      recovered();
      final Future<void> background =
          ShiftSyncQueue.flush(reason: 'backend-recovered');
      await cashierCloses(); // fon yuborish tugashini kutmasdan
      await background;

      await deliverAll();
      expectConsistent();
    });

    test('kassa boshqa kassaga qayta aktivlashtirildi — eski amallar o\'z '
        'kassasiga ketadi', () async {
      backend.open['kassa-2'] = false;
      setNet(_Net.down500);
      expect(await cashierOpens(), isTrue);
      await cashierCloses();

      await Pref.setString(PrefKeys.activatedPosId, 'kassa-2');
      expect(await cashierOpens(), isTrue);

      await deliverAll();
      expect(ShiftSyncQueue.hasPending, isFalse);
      expect(backend.accepted, posLog);
      expect(backend.open['kassa-1'], isFalse);
      expect(backend.open['kassa-2'], isTrue);
    });

    test('har amal o\'z kassiri nomidan ketadi (kassir almashdi)', () async {
      final List<String> users = [];
      setNet(_Net.down500);
      await Pref.setString(PrefKeys.userId, 'ali');
      expect(await cashierOpens(), isTrue);
      await cashierCloses();
      await Pref.setString(PrefKeys.userId, 'vali');
      expect(await cashierOpens(), isTrue);

      users.addAll(ShiftSyncQueue.pending.map((e) => e.userId));
      expect(users, ['ali', 'ali', 'vali']);

      await deliverAll();
      expectConsistent();
    });

    test('ko\'p amal: 30 marta ochish/yopish internetsiz — hammasi yetadi',
        () async {
      setNet(_Net.internetOff);
      for (int i = 0; i < 15; i++) {
        expect(await cashierOpens(), isTrue);
        await cashierCloses();
      }
      expect(ShiftSyncQueue.pendingCount, 30);
      await deliverAll();
      expectConsistent();
    });
  });

  group('Tasodifiy stsenariylar', () {
    // Odatda 100; og'ir tekshiruv uchun:
    // flutter test test/shift_queue_scenarios_test.dart \
    //   --dart-define=SHIFT_FUZZ_SEEDS=2000
    const int seeds =
        int.fromEnvironment('SHIFT_FUZZ_SEEDS', defaultValue: 100);
    // Bitta muvaffaqiyatsiz holatni qayta ko'rish uchun:
    // --dart-define=SHIFT_FUZZ_SEED=247 --dart-define=SHIFT_FUZZ_REJECT=500
    const int onlySeed = int.fromEnvironment('SHIFT_FUZZ_SEED');
    const int onlyReject = int.fromEnvironment('SHIFT_FUZZ_REJECT');

    test(
        'TASODIFIY: 4 xil server xulqi × $seeds ta ketma-ketlik × 25 qadam — '
        'har doim izchil', () async {
      int runs = 0;
      for (final int rejectStatus in [400, 409, 500, 200]) {
        if (onlyReject != 0 && rejectStatus != onlyReject) continue;
        for (int seed = 1; seed <= seeds; seed++) {
          if (onlySeed != 0 && seed != onlySeed) continue;
          await resetWorld();
          backend.rejectStatus = rejectStatus;
          final Random rnd = Random(seed * 1000 + rejectStatus);
          final List<String> trace = [];

          for (int step = 0; step < 25; step++) {
            final int roll = rnd.nextInt(100);
            if (roll < 35) {
              if (posOpen()) {
                trace.add('yopish');
                await cashierCloses();
              } else {
                trace.add('ochish');
                final _Net net = backend.net;
                final bool? result = await cashierOpens();
                // 401 da ikkala natija ham dizayn bo'yicha: navbat bo'sh va
                // server "tirik" bo'lsa bloklanadi, aks holda lokal ochiladi.
                // Boshqa har qanday holatda ochish bloklanmasligi SHART.
                if (net != _Net.unauthorized) {
                  expect(result, isTrue,
                      reason: 'ochish bloklanmasligi kerak ($net): '
                          '${trace.join(', ')}');
                }
              }
            } else if (roll < 45) {
              trace.add('server-500');
              setNet(_Net.down500);
            } else if (roll < 55) {
              trace.add('internet-yoq');
              setNet(_Net.internetOff);
            } else if (roll < 59) {
              trace.add('wifi-login');
              setNet(_Net.captivePortal);
            } else if (roll < 63) {
              trace.add('401');
              setNet(_Net.unauthorized);
            } else if (roll < 80) {
              trace.add('tiklandi');
              recovered();
              if (rnd.nextBool()) {
                await ShiftSyncQueue.flush(reason: 'backend-recovered');
              }
            } else if (roll < 84) {
              trace.add('javob-yoqoladi');
              backend.loseNextResponse = true;
            } else if (roll < 88) {
              final int status = [500, 502, 404][rnd.nextInt(3)];
              trace.add('bir-lahza-$status');
              backend.failNextMutationWith = status;
            } else if (roll < 95) {
              trace.add('flush');
              await ShiftSyncQueue.flush(reason: 'receipts-uploaded');
            } else {
              trace.add('yopishni-yuborish');
              BackendHealth.markUserInitiatedAction();
              await ShiftSyncQueue.flush(reason: 'manual');
            }
          }

          await deliverAll();
          expectConsistent('rad etish=$rejectStatus seed=$seed\n'
              'qadamlar: ${trace.join(', ')}');
          runs++;
        }
      }
      if (onlySeed == 0 && onlyReject == 0) expect(runs, 4 * seeds);
    }, timeout: const Timeout(Duration(hours: 2)));
  });
}
