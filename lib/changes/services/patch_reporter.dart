/*
    Shorebird yangilanishlari haqida Telegram kanaliga hisobot.

    Maqsad: qaysi do'konning qaysi kassasi oxirgi build'ni (reliz yoki patch)
    olganini kuzatish.

    1. "Build olindi" — dastur yangi build'da ISHGA TUSHGANDA (yuklangani
       emas, haqiqatan ishlayotgani) har qurilma uchun BIR MARTA yuboriladi.
       Kalit: `<reliz versiyasi>#<patch raqami>`. Yuborilmasa (internet yo'q,
       kassa hali aktivatsiya qilinmagan) — keyingi tekshiruvda qayta
       uriniladi; muvaffaqiyatli yuborilgach kalit saqlanadi.
    2. Shorebird xatolari — faqat yangilanish yo'lidagi xatolar:
       - `update()` / `checkForUpdate()` xatosi (tarmoq uzilishi emas —
         oflayn kassa kanalni to'ldirmasin);
       - yuklangan patch ishga tushmadi (Shorebird uni yaroqsiz deb eski
         versiyaga qaytdi);
       - rollback (patch raqami kamaydi).
       Bir xil xato bir build uchun bir marta, kuniga ko'pi bilan
       [_dailyErrorCap] ta.

    Sotuvga ta'sir qilmaydi: barcha xatolar yutiladi, faqat `[PATCH-TG]` log.
    Debug yoki `shorebird release` siz build'da hech narsa qilmaydi
    (`PatchUpdater.start` ichidan chaqiriladi).
*/

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:invan2/changes/providers/settings_provider.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class PatchReporter {
  PatchReporter._();

  // @invan_update_monitor_bot → "Invan Shorebird Builds" kanali.
  // Bot faqat shu kanalda admin. Bo'sh bo'lsa hisobot o'chiq (faqat log).
  static const String _botToken =
      '8765885617:AAHQpp0sHIMoUyuQl1L_eFl_EsMjMeEX9hc';
  static const String _chatId = '-1003904407778';

  static bool get _configured => _botToken.isNotEmpty && _chatId.isNotEmpty;

  static const Duration _interval = Duration(minutes: 5);
  static const int _dailyErrorCap = 10;
  static const int _maxQueuedErrors = 20;

  static ShorebirdUpdater? _updater;
  static Timer? _timer;
  static bool _busy = false;
  static String? _version;

  /// `start` dan oldin (main() boshida, Hive ochilmasdan) yuz bergan xatolar
  /// ham shu yerda kutadi.
  static final List<PatchErrorReport> _errors = <PatchErrorReport>[];

  /// `PatchUpdater.start` dan — runApp'dan keyin, Hive ochiq.
  static void start(ShorebirdUpdater updater) {
    if (_timer != null) return;
    _updater = updater;
    _timer = Timer.periodic(_interval, (_) => _tick());
    // Ochilishda sotuvga xalaqit bermasin — biroz kutamiz.
    Timer(const Duration(seconds: 20), _tick);
    BackendHealth.status.addListener(_onConnectivityChanged);
  }

  static void _onConnectivityChanged() {
    if (BackendHealth.status.value == BackendStatus.up) _tick();
  }

  /// Shorebird yo'lidagi xato. Tarmoq uzilishi bo'lsa faqat log.
  static void error(String stage, Object error) {
    if (PatchReportLogic.isNetworkError(error)) return;
    if (_errors.length >= _maxQueuedErrors) return;
    _errors.add(PatchErrorReport(stage: stage, message: '$error'));
    if (_timer != null) unawaited(_tick());
  }

  static Future<void> _tick() async {
    final ShorebirdUpdater? updater = _updater;
    if (_busy || updater == null) return;
    _busy = true;
    try {
      // Aktivatsiyagacha do'kon/kassa nomi yo'q — keyinroq.
      if (Pref.getString(PrefKeys.storeName, '').isEmpty) return;
      final String version = _version ??= await _appVersion();
      if (version.isEmpty) return;

      final int? current = (await updater.readCurrentPatch())?.number;
      final int? next = (await updater.readNextPatch())?.number;
      final String currentKey = PatchReportLogic.buildKey(version, current);

      final List<PatchBootEvent> events = PatchReportLogic.bootEvents(
        version: version,
        current: current,
        next: next,
        lastReported: Pref.getString(PrefKeys.patchReportedBuild, ''),
        pending: Pref.getString(PrefKeys.patchPendingBuild, ''),
      );
      for (final PatchBootEvent event in events) {
        if (!await _send(_bootMessage(event, currentKey))) return;
        if (event.kind == PatchBootKind.notApplied) {
          await Pref.setString(PrefKeys.patchPendingBuild, '');
        } else {
          await Pref.setString(PrefKeys.patchReportedBuild, currentKey);
        }
      }

      // Diskda yangi patch kutmoqda — keyingi ochilishda u ishga tushmasa
      // "qo'llanmadi" deb xabar beriladi.
      final String pending = PatchReportLogic.pendingKey(
        version: version,
        current: current,
        next: next,
        previous: Pref.getString(PrefKeys.patchPendingBuild, ''),
      );
      await Pref.setString(PrefKeys.patchPendingBuild, pending);

      await _flushErrors(currentKey);
    } catch (e) {
      _log('tick xatosi: $e');
    } finally {
      _busy = false;
    }
  }

  static Future<void> _flushErrors(String buildKey) async {
    while (_errors.isNotEmpty) {
      final PatchErrorReport report = _errors.first;
      final Map<dynamic, dynamic> state = _errorState();
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final PatchErrorDecision decision = PatchReportLogic.errorDecision(
        state: state,
        buildKey: buildKey,
        today: today,
        signature: report.signature,
        dailyCap: _dailyErrorCap,
      );
      if (decision.send) {
        if (!await _send(_errorMessage(report, buildKey))) return;
        await Pref.setObject(PrefKeys.patchReportErrors, decision.newState);
      }
      _errors.removeAt(0);
    }
  }

  static Map<dynamic, dynamic> _errorState() {
    final dynamic raw = Pref.getObject(PrefKeys.patchReportErrors);
    return raw is Map ? raw : <dynamic, dynamic>{};
  }

  static Future<String> _appVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return '';
    }
  }

  // ---- Xabarlar ----

  static String _header() {
    final String org = Pref.getString(PrefKeys.organizationName, '-');
    final String store = Pref.getString(PrefKeys.storeName, '-');
    final String pos = Pref.getString(PrefKeys.posName, '-');
    final String computer =
        '${SettingsInnerSingleton.deviceData['computerName'] ?? '-'}';
    return '🏢 <b>Tashkilot:</b> ${_esc(org)}\n'
        '🏬 <b>Do\'kon:</b> ${_esc(store)}\n'
        '🖥 <b>Kassa:</b> ${_esc(pos)}\n'
        '💻 <b>Kompyuter:</b> ${_esc(computer)} (${Platform.operatingSystem})';
  }

  static String _time() =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  static String _bootMessage(PatchBootEvent event, String currentKey) {
    final String now = PatchReportLogic.describe(currentKey);
    switch (event.kind) {
      case PatchBootKind.installed:
        final String prev = event.previous.isEmpty
            ? '— (birinchi hisobot)'
            : PatchReportLogic.describe(event.previous);
        return '✅ <b>Yangi build olindi — muammo yo\'q</b>\n\n'
            '${_header()}\n\n'
            '📦 <b>Build:</b> ${_esc(now)}\n'
            '⬅️ <b>Oldingi:</b> ${_esc(prev)}\n'
            '🕒 ${_time()}';
      case PatchBootKind.rolledBack:
        return '⚠️ <b>Patch orqaga qaytarildi (rollback)</b>\n\n'
            '${_header()}\n\n'
            '📦 <b>Hozir:</b> ${_esc(now)}\n'
            '⬅️ <b>Oldin:</b> ${_esc(PatchReportLogic.describe(event.previous))}\n'
            '🕒 ${_time()}';
      case PatchBootKind.notApplied:
        return '❌ <b>Patch ishga tushmadi</b>\n'
            'Yuklangan edi, lekin dastur unda ochilmadi — Shorebird eski '
            'versiyaga qaytdi (yoki patch konsoldan bekor qilingan).\n\n'
            '${_header()}\n\n'
            '📥 <b>Yuklangan:</b> ${_esc(PatchReportLogic.describe(event.previous))}\n'
            '📦 <b>Ishlayapti:</b> ${_esc(now)}\n'
            '🕒 ${_time()}';
    }
  }

  static String _errorMessage(PatchErrorReport report, String buildKey) {
    final String message = report.message.length > 1500
        ? '${report.message.substring(0, 1500)}…'
        : report.message;
    return '❌ <b>Shorebird xatosi</b>\n\n'
        '${_header()}\n\n'
        '📦 <b>Build:</b> ${_esc(PatchReportLogic.describe(buildKey))}\n'
        '🔧 <b>Bosqich:</b> ${_esc(report.stage)}\n'
        '🕒 ${_time()}\n\n'
        '<pre>${_esc(message)}</pre>';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// `true` — Telegram qabul qildi.
  static Future<bool> _send(String text) async {
    if (!_configured) {
      _log('kanal sozlanmagan, yuborilmadi:\n$text');
      return false;
    }
    try {
      final http.Response response = await http.post(
        Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage'),
        body: <String, String>{
          'chat_id': _chatId,
          'text': text,
          'parse_mode': 'HTML',
          'disable_web_page_preview': 'true',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return true;
      _log('Telegram ${response.statusCode}: ${response.body}');
    } catch (e) {
      _log('yuborib bo\'lmadi: $e');
    }
    return false;
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[PATCH-TG] $message');
    unawaited(LogHelper.write(LogLevel.info, '[PATCH-TG] $message'));
  }
}

/// Navbatdagi xato hisoboti.
class PatchErrorReport {
  const PatchErrorReport({required this.stage, required this.message});

  final String stage;
  final String message;

  /// Takrorni aniqlash uchun — raqamlar (port, vaqt) olib tashlanadi.
  String get signature {
    final String m = message.replaceAll(RegExp(r'\d+'), '#');
    return '$stage|${m.length > 160 ? m.substring(0, 160) : m}';
  }
}

enum PatchBootKind {
  /// Yangi build ishga tushdi (yangi patch yoki yangi reliz).
  installed,

  /// Shu relizda patch raqami kamaydi.
  rolledBack,

  /// Yuklangan patch ishga tushmadi.
  notApplied,
}

class PatchBootEvent {
  const PatchBootEvent(this.kind, this.previous);

  final PatchBootKind kind;

  /// installed/rolledBack — oldingi hisobot qilingan build kaliti;
  /// notApplied — ishga tushmagan patch kaliti.
  final String previous;
}

class PatchErrorDecision {
  const PatchErrorDecision(this.send, this.newState);

  final bool send;
  final Map<dynamic, dynamic> newState;
}

/// Sof qarorlar (Shorebird/Hive/tarmoqsiz) — testlanadi.
class PatchReportLogic {
  PatchReportLogic._();

  /// `1.1.2+128` (patch yo'q) yoki `1.1.2+128#3`.
  static String buildKey(String version, int? patch) =>
      patch == null ? version : '$version#$patch';

  static String versionOf(String key) => key.split('#').first;

  static int? patchOf(String key) {
    final List<String> parts = key.split('#');
    return parts.length > 1 ? int.tryParse(parts[1]) : null;
  }

  /// Odam o'qiydigan ko'rinish: `1.1.2+128 · patch 3` / `1.1.2+128 · asl reliz`.
  static String describe(String key) {
    final int? patch = patchOf(key);
    return '${versionOf(key)} · ${patch == null ? 'asl reliz' : 'patch $patch'}';
  }

  /// Joriy ishga tushirish bo'yicha yuboriladigan xabarlar.
  static List<PatchBootEvent> bootEvents({
    required String version,
    required int? current,
    required int? next,
    required String lastReported,
    required String pending,
  }) {
    final List<PatchBootEvent> events = <PatchBootEvent>[];
    final String currentKey = buildKey(version, current);

    // Oldingi ochilishda diskda kutgan patch — endi u ham ishlamayapti, ham
    // navbatda emas, va undan yangisi ham ishlamayapti.
    final int? pendingPatch = patchOf(pending);
    if (pendingPatch != null &&
        versionOf(pending) == version &&
        next != pendingPatch &&
        (current == null || current < pendingPatch)) {
      events.add(PatchBootEvent(PatchBootKind.notApplied, pending));
    }

    if (lastReported != currentKey) {
      final int? lastPatch = patchOf(lastReported);
      final bool rolledBack = lastReported.isNotEmpty &&
          versionOf(lastReported) == version &&
          lastPatch != null &&
          (current == null || current < lastPatch);
      events.add(PatchBootEvent(
          rolledBack ? PatchBootKind.rolledBack : PatchBootKind.installed,
          lastReported));
    }
    return events;
  }

  /// Saqlanadigan "kutayotgan patch" kaliti. Bo'sh — kutayotgan yo'q.
  static String pendingKey({
    required String version,
    required int? current,
    required int? next,
    required String previous,
  }) {
    if (next != null && (current == null || next > current)) {
      return buildKey(version, next);
    }
    // Patch ishga tushdi (yoki yangi reliz) — kutish tugadi.
    final int? prevPatch = patchOf(previous);
    if (prevPatch == null || versionOf(previous) != version) return '';
    if (current != null && current >= prevPatch) return '';
    // Hali "qo'llanmadi" xabari yuborilmagan — saqlanadi.
    return previous;
  }

  /// Xatoni yuborish kerakmi va yangi holat.
  /// Holat: `{build, day, count, sigs: [..]}`.
  static PatchErrorDecision errorDecision({
    required Map<dynamic, dynamic> state,
    required String buildKey,
    required String today,
    required String signature,
    required int dailyCap,
  }) {
    final bool sameBuild = state['build'] == buildKey;
    final List<String> sigs = sameBuild
        ? List<String>.from((state['sigs'] as List?) ?? const <String>[])
        : <String>[];
    final int count =
        state['day'] == today ? (state['count'] as int? ?? 0) : 0;

    if (sigs.contains(signature) || count >= dailyCap) {
      return PatchErrorDecision(false, state);
    }
    return PatchErrorDecision(true, <String, dynamic>{
      'build': buildKey,
      'day': today,
      'count': count + 1,
      'sigs': <String>[...sigs, signature],
    });
  }

  /// Internet/server uzilishi — kassa oflayn ishlayotganda kutiladigan holat,
  /// kanalga yuborilmaydi.
  static bool isNetworkError(Object error) {
    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException ||
        error is HandshakeException ||
        error is http.ClientException) {
      return true;
    }
    if (error is UpdateException &&
        error.reason == UpdateFailureReason.installFailed) {
      return false;
    }
    final String m = '$error'.toLowerCase();
    const List<String> markers = <String>[
      'failed host lookup',
      'dns error',
      'error sending request',
      'connection refused',
      'connection reset',
      'connection closed',
      'network is unreachable',
      'timed out',
      'actively refused',
      'no route to host',
    ];
    return markers.any(m.contains);
  }
}
