// VP930 kaft skaneri — Windows `palm_wrapper.dll` (Kaftpay SDK) ustida.
//
// Protokol Kaftpay namunaviy kassasidan (`pp-pos-app` `palm.py`,
// `app/scanner.py`) va `palm_wrapper.cpp` dan:
//   palm_open()                                   0 — ok
//   palm_capture(ir[516], rgb[516], &palm_type, timeout_ms)
//       0 ok · 1 kaft topilmadi (vaqt tugadi) · 2 to'xtatildi (palm_stop)
//       -98 kaft topildi, lekin belgilar yaroqsiz ("kaftni tekis tuting")
//   palm_stop()  · palm_close()
// `palm_capture` bloklaydi (timeout + 5 s gacha) — shuning uchun alohida
// isolate'da. Har urinishda ochish → olish → yopish: ochiq handle'da qayta
// olish oldingi StopPalmCapture bilan poyga qilib "to'xtatildi" qaytaradi.
// SDK `config/` ni DLL yonidan o'zi topadi (GetModuleDir + "\config").
//
// Fayllar repo'da YO'Q (foydalanuvchi qarori 2026-10-30): skanerli
// kompyuterga alohida qo'yiladi, sukut — `KaftpaySettings.defaultSdkDir`.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';

/// Skan bosqichi — kassirga ko'rsatiladigan matn uchun.
enum KaftpayScanStage { waitingPalm, retrying, waitingDevice }

class KaftpayScannerException implements Exception {
  const KaftpayScannerException(this.message, {this.cancelled = false});

  final String message;

  /// Kassir "Bekor qilish" bosgan.
  final bool cancelled;

  @override
  String toString() => message;
}

abstract class KaftpayScanner {
  /// null — ishlatsa bo'ladi; aks holda sabab (kassirga).
  String? get unavailableReason;

  /// Kaftni oladi. [onStage] — kassirga xabar ("kaftni qo'ying", "yana
  /// bir bor"). Bekor qilinsa / olinmasa — [KaftpayScannerException].
  Future<KaftpayPalmScan> capture({
    void Function(KaftpayScanStage stage, String message)? onStage,
  });

  /// Joriy skanni to'xtatadi (natija tashlab yuboriladi).
  void cancel();

  static KaftpayScanner? _shared;
  static String? _sharedDir;

  /// Ilova bo'yicha bitta skaner (SDK papkasi o'zgarmaguncha): bekor
  /// qilingan skan isolate'i tugaguncha yangisi qurilmani band qilmasin.
  static KaftpayScanner shared({required String sdkDir}) {
    final s = _shared;
    if (s != null && _sharedDir == sdkDir) return s;
    _sharedDir = sdkDir;
    return _shared = create(sdkDir: sdkDir);
  }

  /// Platformaga mos skaner: Windows — SDK; boshqa platformada faqat debug
  /// rejimda sun'iy (UI oqimini sinash uchun; server uni `no_match` /
  /// `1109` bilan qaytaradi).
  static KaftpayScanner create({required String sdkDir}) {
    if (Platform.isWindows) return KaftpaySdkScanner(sdkDir: sdkDir);
    if (kDebugMode) return KaftpaySyntheticScanner();
    return _UnavailableScanner(KaftpayLang.t(
        'Kaft skaneri faqat Windows kassada ishlaydi',
        'Сканер ладони работает только на кассе Windows'));
  }
}

class _UnavailableScanner implements KaftpayScanner {
  const _UnavailableScanner(this.unavailableReason);

  @override
  final String unavailableReason;

  @override
  Future<KaftpayPalmScan> capture({
    void Function(KaftpayScanStage stage, String message)? onStage,
  }) =>
      Future.error(KaftpayScannerException(unavailableReason));

  @override
  void cancel() {}
}

/// Isolate'dan qaytadigan xom natija (faqat oddiy turlar — isolate'lar
/// orasida ko'chiriladi).
class KaftpayRawCapture {
  const KaftpayRawCapture({
    required this.stage,
    required this.code,
    this.ir,
    this.rgb,
    this.palmType = -1,
    this.loadError,
  });

  /// 'load' | 'open' | 'capture'.
  final String stage;
  final int code;
  final List<double>? ir;
  final List<double>? rgb;
  final int palmType;
  final String? loadError;

  bool get ok => stage == 'capture' && code == 0 && ir != null;
}

/// Natija → nima qilish (sof funksiya, test qilinadi).
enum KaftpayCaptureVerdict { ok, retry, fatal }

class KaftpayCaptureOutcome {
  const KaftpayCaptureOutcome(this.verdict, this.message);

  final KaftpayCaptureVerdict verdict;
  final String message;
}

KaftpayCaptureOutcome classifyKaftpayCapture(KaftpayRawCapture r) {
  const fatal = KaftpayCaptureVerdict.fatal;
  const retry = KaftpayCaptureVerdict.retry;
  final t = KaftpayLang.t;
  if (r.stage == 'load') {
    final why = r.loadError ?? t('noma\'lum xato', 'неизвестная ошибка');
    return KaftpayCaptureOutcome(
        fatal,
        t('Skaner dasturi yuklanmadi: $why',
            'ПО сканера не загрузилось: $why'));
  }
  if (r.stage == 'open') {
    switch (r.code) {
      case -1:
        return KaftpayCaptureOutcome(
            fatal,
            t('Kaft skaneri topilmadi: USB kabelini va WinUSB drayverini tekshiring',
                'Сканер ладони не найден: проверьте USB-кабель и драйвер WinUSB'));
      case -3:
        return KaftpayCaptureOutcome(
            fatal,
            t('Skaner ochilmadi — boshqa dastur ishlatayotgan bo\'lishi mumkin',
                'Сканер не открылся — возможно, его занимает другая программа'));
      default:
        return KaftpayCaptureOutcome(
            fatal,
            t('Skanerni ishga tushirib bo\'lmadi (kod ${r.code})',
                'Не удалось запустить сканер (код ${r.code})'));
    }
  }
  if (r.ok) {
    return const KaftpayCaptureOutcome(KaftpayCaptureVerdict.ok, '');
  }
  switch (r.code) {
    case 1:
      return KaftpayCaptureOutcome(
          retry,
          t(
              'Kaft topilmadi — kaftni sekin yaqinlashtiring, chiroq yashil '
                  'bo\'lganda qimirlamang',
              'Ладонь не найдена — медленно поднесите ладонь, при зелёном '
                  'свете не двигайте'));
    case 2:
      return KaftpayCaptureOutcome(
          retry,
          t('Skan to\'xtatildi — yana bir bor',
              'Сканирование прервано — ещё раз'));
    case -98:
      return KaftpayCaptureOutcome(
          retry,
          t('Kaftni ochiq, tekis va harakatsiz tuting',
              'Держите ладонь открытой, ровно и неподвижно'));
    case 0:
      // ok emas, lekin kod 0 — vektor yo'q.
      return KaftpayCaptureOutcome(
          retry, t('Skan sifatsiz — yana bir bor', 'Плохой скан — ещё раз'));
    default:
      return KaftpayCaptureOutcome(fatal,
          t('Skaner xatosi (kod ${r.code})', 'Ошибка сканера (код ${r.code})'));
  }
}

class KaftpaySdkScanner implements KaftpayScanner {
  KaftpaySdkScanner({
    required this.sdkDir,
    this.attempts = 3,
    this.timeoutMs = 12000,
    Future<KaftpayRawCapture> Function(String sdkDir, int timeoutMs)? runOnce,
    void Function(String sdkDir)? stop,
  })  : _runOnce = runOnce ?? _captureInIsolate,
        _stop = stop ?? _stopNative;

  static const String wrapperDll = 'palm_wrapper.dll';

  final String sdkDir;
  final int attempts;
  final int timeoutMs;
  final Future<KaftpayRawCapture> Function(String, int) _runOnce;
  final void Function(String) _stop;

  /// Oldingi (bekor qilingan) skan isolate'i hali ishlayotgan bo'lishi
  /// mumkin — qurilma bo'shaguncha yangisi boshlanmaydi.
  Future<void>? _inFlight;
  bool _cancelled = false;
  Completer<KaftpayRawCapture?>? _cancelSignal;

  @override
  String? get unavailableReason {
    if (!Platform.isWindows) {
      return KaftpayLang.t('Kaft skaneri faqat Windows kassada ishlaydi',
          'Сканер ладони работает только на кассе Windows');
    }
    final dll = File('$sdkDir${Platform.pathSeparator}$wrapperDll');
    if (!dll.existsSync()) {
      return KaftpayLang.t('Skaner dasturi topilmadi: ${dll.path}',
          'ПО сканера не найдено: ${dll.path}');
    }
    final config = Directory('$sdkDir${Platform.pathSeparator}config');
    if (!config.existsSync()) {
      return KaftpayLang.t(
          'Skaner modellari (config) topilmadi: ${config.path}',
          'Модели сканера (config) не найдены: ${config.path}');
    }
    return null;
  }

  /// Testlar uchun: tekshiruvsiz ([unavailableReason] fayl tizimiga qaraydi).
  @visibleForTesting
  bool skipAvailabilityCheck = false;

  @override
  Future<KaftpayPalmScan> capture({
    void Function(KaftpayScanStage stage, String message)? onStage,
  }) async {
    if (!skipAvailabilityCheck) {
      final reason = unavailableReason;
      if (reason != null) throw KaftpayScannerException(reason);
    }
    _cancelled = false;
    final signal = _cancelSignal = Completer<KaftpayRawCapture?>();
    const cancelled = KaftpayScannerException('Bekor qilindi', cancelled: true);
    final previous = _inFlight;
    if (previous != null) {
      onStage?.call(
          KaftpayScanStage.waitingDevice,
          KaftpayLang.t('Skaner bo\'shashini kutyapman...',
              'Жду, пока сканер освободится...'));
      await Future.any<void>([previous, signal.future]);
    }
    // VP930 chirog'i: oq — masofa to'g'ri emas, yashil — to'g'ri joy
    // (2026-10-31, Windows sinovi).
    var message = KaftpayLang.t(
        'Kaftni skanerga yaqinlashtiring — chiroq yashil bo\'lganda qimirlamang',
        'Поднесите ладонь к сканеру — при зелёном свете не двигайте');
    for (var i = 0; i < attempts; i++) {
      if (_cancelled) throw cancelled;
      onStage?.call(
          i == 0 ? KaftpayScanStage.waitingPalm : KaftpayScanStage.retrying,
          message);
      final run = _runOnce(sdkDir, timeoutMs).catchError((Object e) =>
          KaftpayRawCapture(stage: 'load', code: -1, loadError: '$e'));
      final inFlight = _inFlight = run.then((_) {});
      run.whenComplete(() {
        if (identical(_inFlight, inFlight)) _inFlight = null;
      });
      // Bekor qilinsa — darhol qaytamiz; isolate fonda tugaydi.
      final raw = await Future.any<KaftpayRawCapture?>([run, signal.future]);
      if (raw == null || _cancelled) throw cancelled;
      final outcome = classifyKaftpayCapture(raw);
      switch (outcome.verdict) {
        case KaftpayCaptureVerdict.ok:
          final scan = KaftpayPalmScan(
            ir: raw.ir!,
            rgb: raw.rgb,
            hand: KaftpayHand.fromSdk(raw.palmType),
          );
          if (scan.validate() == null) return scan;
          message = KaftpayLang.t(
              'Skan sifatsiz — kaftni yana bir bor qo\'ying',
              'Плохой скан — приложите ладонь ещё раз');
          break;
        case KaftpayCaptureVerdict.retry:
          message = outcome.message;
          break;
        case KaftpayCaptureVerdict.fatal:
          throw KaftpayScannerException(outcome.message);
      }
    }
    throw KaftpayScannerException(message);
  }

  @override
  void cancel() {
    _cancelled = true;
    final signal = _cancelSignal;
    if (signal != null && !signal.isCompleted) signal.complete(null);
    if (_inFlight != null) {
      try {
        _stop(sdkDir);
      } catch (_) {
        // to'xtatib bo'lmasa — isolate vaqt tugashi bilan o'zi tugaydi.
      }
    }
  }

  static Future<KaftpayRawCapture> _captureInIsolate(
          String sdkDir, int timeoutMs) =>
      Isolate.run(() => _captureOnceNative(sdkDir, timeoutMs));

  static void _stopNative(String sdkDir) {
    final lib = _openWrapper(sdkDir);
    lib.lookupFunction<Int32 Function(), int Function()>('palm_stop')();
  }
}

// ─── Native (Windows) ────────────────────────────────────────────────────────

typedef _SetDllDirectoryC = Int32 Function(Pointer<Utf16>);
typedef _SetDllDirectoryDart = int Function(Pointer<Utf16>);

/// palm_wrapper.dll importlari (palm_sdk.dll, dim_palm.dll, TNN.dll) SDK
/// papkasidan topilishi uchun avval DLL qidiruv yo'liga qo'shiladi
/// (namunadagi `os.add_dll_directory`).
DynamicLibrary _openWrapper(String sdkDir) {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final setDllDirectory =
      kernel32.lookupFunction<_SetDllDirectoryC, _SetDllDirectoryDart>(
          'SetDllDirectoryW');
  final dir = sdkDir.toNativeUtf16();
  try {
    setDllDirectory(dir);
  } finally {
    malloc.free(dir);
  }
  return DynamicLibrary.open('$sdkDir\\${KaftpaySdkScanner.wrapperDll}');
}

typedef _CaptureC = Int32 Function(
    Pointer<Float>, Pointer<Float>, Pointer<Int32>, Int32);
typedef _CaptureDart = int Function(
    Pointer<Float>, Pointer<Float>, Pointer<Int32>, int);

/// Isolate ichida: ochish → bitta skan → yopish.
KaftpayRawCapture _captureOnceNative(String sdkDir, int timeoutMs) {
  final DynamicLibrary lib;
  try {
    lib = _openWrapper(sdkDir);
  } catch (e) {
    return KaftpayRawCapture(stage: 'load', code: -1, loadError: '$e');
  }
  final open =
      lib.lookupFunction<Int32 Function(), int Function()>('palm_open');
  final close =
      lib.lookupFunction<Void Function(), void Function()>('palm_close');
  final capture = lib.lookupFunction<_CaptureC, _CaptureDart>('palm_capture');

  final ir = calloc<Float>(KaftpayPalmScan.vectorLength);
  final rgb = calloc<Float>(KaftpayPalmScan.vectorLength);
  final palmType = calloc<Int32>()..value = -1;
  try {
    final o = open();
    if (o != 0) return KaftpayRawCapture(stage: 'open', code: o);
    try {
      final r = capture(ir, rgb, palmType, timeoutMs);
      if (r != 0) return KaftpayRawCapture(stage: 'capture', code: r);
      return KaftpayRawCapture(
        stage: 'capture',
        code: 0,
        ir: List<double>.from(ir.asTypedList(KaftpayPalmScan.vectorLength)),
        rgb: List<double>.from(rgb.asTypedList(KaftpayPalmScan.vectorLength)),
        palmType: palmType.value,
      );
    } finally {
      close();
    }
  } finally {
    calloc.free(ir);
    calloc.free(rgb);
    calloc.free(palmType);
  }
}

// ─── Sun'iy (faqat debug, skanersiz) ─────────────────────────────────────────

/// Namunadagi `_lcg_vec` bilan bir xil deterministik vektor. Haqiqiy
/// serverda identify `no_match`, enroll `1109` beradi — faqat UI oqimi uchun.
class KaftpaySyntheticScanner implements KaftpayScanner {
  KaftpaySyntheticScanner({this.seed = 42});

  final int seed;
  bool _cancelled = false;

  static List<double> vector(int seed) {
    final out = <double>[];
    var s = seed;
    for (var i = 0; i < KaftpayPalmScan.vectorLength; i++) {
      s = (s * 1103515245 + 12345) & 0x7FFFFFFF;
      final v = (s / 0x7FFFFFFF) * 2 - 1;
      out.add((v * 1e6).round() / 1e6);
    }
    return out;
  }

  @override
  String? get unavailableReason => null;

  @override
  Future<KaftpayPalmScan> capture({
    void Function(KaftpayScanStage stage, String message)? onStage,
  }) async {
    _cancelled = false;
    onStage?.call(
        KaftpayScanStage.waitingPalm,
        KaftpayLang.t('SINOV: kaft o\'rniga sun\'iy vektor (skanersiz)',
            'ТЕСТ: вместо ладони — синтетический вектор (без сканера)'));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_cancelled) {
      throw const KaftpayScannerException('Bekor qilindi', cancelled: true);
    }
    return KaftpayPalmScan(ir: vector(seed), hand: KaftpayHand.right);
  }

  @override
  void cancel() => _cancelled = true;

  /// L2 norma (test uchun).
  static double norm(List<double> v) =>
      math.sqrt(v.fold<double>(0, (s, x) => s + x * x));
}
