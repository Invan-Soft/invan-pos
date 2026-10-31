// VP930 kamerasidan ro'yxatdan o'tkazish QR'ini o'qish (2026-10-31).
//
// Kaftpay namunaviy kassasidan (`app/scanner.py` `_read_qr_real`,
// `native/palm_frame.cpp`):
//   pf_open()                                 0 — ok (<0 bizniki, >0 SDK)
//   pf_grab(buf, len, &w, &h, timeout_ms)     0 — BGR888 kadr buf'da
//   pf_close()
// Har kadrda QR qidiriladi (kamera ko'zgu tasvir berishi mumkin — teskarisi
// ham), `PPENROLL:` topilsa — tayyor. Namunada OpenCV, bizda `zxing2` (toza
// Dart). Kamera va kaft skaneri bitta qurilma: kaft skanidan OLDIN [stop]
// kutiladi (pf_close).
//
// Barcode skaner ham ishlayveradi — qaysi biri birinchi o'qisa.
// `palm_frame.dll` SDK papkasida bo'lmasa — faqat barcode skaner.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:zxing2/qrcode.dart';

/// Bitta kadr natijasi (isolate'dan qaytadi).
class KaftpayQrFrame {
  const KaftpayQrFrame(this.code, [this.text]);

  /// `pf_grab` kodi (0 — kadr olindi).
  final int code;

  /// Kadrdagi QR matni (topilmasa null).
  final String? text;
}

abstract class KaftpayQrReader {
  /// null — ishlatsa bo'ladi; aks holda sabab.
  String? get unavailableReason;

  /// `PPENROLL:` QR matni; vaqt tugasa yoki [stop] — null. Kamera ochilmasa
  /// — [KaftpayScannerException].
  Future<String?> read({Duration timeout = const Duration(seconds: 60)});

  /// O'qishni to'xtatadi; kamera yopilgach tugaydi (shundan keyin kaft
  /// skaneri qurilmani olishi mumkin).
  Future<void> stop();

  static KaftpayQrReader create({required String sdkDir}) => Platform.isWindows
      ? KaftpaySdkQrReader(sdkDir: sdkDir)
      : const _NoQrReader();
}

class _NoQrReader implements KaftpayQrReader {
  const _NoQrReader();

  @override
  String? get unavailableReason => KaftpayLang.t(
      'VP930 QR faqat Windows kassada', 'QR через VP930 — только на Windows');

  @override
  Future<String?> read(
          {Duration timeout = const Duration(seconds: 60)}) async =>
      null;

  @override
  Future<void> stop() async {}
}

class KaftpaySdkQrReader implements KaftpayQrReader {
  KaftpaySdkQrReader({
    required this.sdkDir,
    Future<int> Function(String sdkDir)? open,
    Future<KaftpayQrFrame> Function(String sdkDir, int timeoutMs)? grab,
    Future<void> Function(String sdkDir)? close,
    DateTime Function()? now,
  })  : _open = open ?? _openInIsolate,
        _grab = grab ?? _grabInIsolate,
        _close = close ?? _closeInIsolate,
        _now = now ?? DateTime.now;

  static const String frameDll = 'palm_frame.dll';

  /// Bitta kadrni kutish (ms).
  static const int grabTimeoutMs = 1000;

  final String sdkDir;
  final Future<int> Function(String) _open;
  final Future<KaftpayQrFrame> Function(String, int) _grab;
  final Future<void> Function(String) _close;
  final DateTime Function() _now;

  bool _stopRequested = false;
  Future<void>? _running;

  @override
  String? get unavailableReason {
    if (!Platform.isWindows) return const _NoQrReader().unavailableReason;
    final dll = File('$sdkDir${Platform.pathSeparator}$frameDll');
    if (!dll.existsSync()) {
      return KaftpayLang.t('VP930 QR o\'qimaydi: $frameDll topilmadi',
          'VP930 не читает QR: нет $frameDll');
    }
    return null;
  }

  @override
  Future<String?> read({Duration timeout = const Duration(seconds: 60)}) async {
    final previous = _running;
    if (previous != null) await previous;
    _stopRequested = false;
    final done = Completer<void>();
    _running = done.future;
    try {
      final int code;
      try {
        code = await _open(sdkDir);
      } catch (e) {
        throw KaftpayScannerException(KaftpayLang.t(
            'VP930 kamerasi yuklanmadi: $e',
            'Камера VP930 не загрузилась: $e'));
      }
      if (code != 0) {
        throw KaftpayScannerException(KaftpayLang.t(
            'VP930 kamerasi ochilmadi (kod $code)',
            'Камера VP930 не открылась (код $code)'));
      }
      try {
        final until = _now().add(timeout);
        while (!_stopRequested && _now().isBefore(until)) {
          final KaftpayQrFrame f;
          try {
            f = await _grab(sdkDir, grabTimeoutMs);
          } catch (_) {
            break;
          }
          if (_stopRequested) break;
          final text = f.text?.trim();
          if (text != null && isEnrollQr(text)) return text;
          // Oqim yo'q (-6) — kamera yopilgan; qayta urinish foydasiz.
          if (f.code == -6) break;
          // Xato kodida darhol qaytsa — protsessorni band qilmaslik uchun.
          if (f.code != 0) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        }
        return null;
      } finally {
        try {
          await _close(sdkDir);
        } catch (_) {
          // yopilmasa ham — keyingi pf_open -5 qaytaradi, kassir ko'radi.
        }
      }
    } finally {
      _running = null;
      done.complete();
    }
  }

  @override
  Future<void> stop() {
    _stopRequested = true;
    return _running ?? Future<void>.value();
  }

  /// Namunadagi kabi faqat ro'yxatdan o'tkazish QR'i (boshqa QR — e'tiborsiz).
  static bool isEnrollQr(String text) =>
      text.toUpperCase().startsWith('PPENROLL:');

  static Future<int> _openInIsolate(String sdkDir) =>
      Isolate.run(() => _pfOpenNative(sdkDir));

  static Future<KaftpayQrFrame> _grabInIsolate(String sdkDir, int timeoutMs) =>
      Isolate.run(() => _pfGrabNative(sdkDir, timeoutMs));

  static Future<void> _closeInIsolate(String sdkDir) =>
      Isolate.run(() => _pfCloseNative(sdkDir));
}

// ─── QR dekodlash (sof, test qilinadi) ───────────────────────────────────────

/// BGR888 kadrdagi QR matni (topilmasa null). [step] — kichraytirish:
/// telefon skanerga yaqin ko'rsatiladi, QR katta — har 2-piksel yetadi va
/// 4 barobar tez. Ko'zgu tasvir ham tekshiriladi.
String? decodeKaftpayQr(Uint8List bgr, int width, int height, {int step = 2}) {
  if (width <= 0 || height <= 0 || bgr.length < width * height * 3) {
    return null;
  }
  final w = width ~/ step;
  final h = height ~/ step;
  final gray = Int8List(w * h);
  final mirror = Int8List(w * h);
  for (var y = 0; y < h; y++) {
    final src = y * step * width;
    final dst = y * w;
    for (var x = 0; x < w; x++) {
      final i = (src + x * step) * 3;
      final l = (bgr[i] * 29 + bgr[i + 1] * 150 + bgr[i + 2] * 77) >> 8;
      gray[dst + x] = l;
      mirror[dst + (w - 1 - x)] = l;
    }
  }
  final hints = DecodeHints()..put(DecodeHintType.tryHarder);
  for (final data in [gray, mirror]) {
    try {
      final bitmap = BinaryBitmap(HybridBinarizer(_GrayLuminance(data, w, h)));
      return QRCodeReader().decode(bitmap, hints: hints).text;
    } catch (_) {
      // topilmadi / o'qilmadi — keyingi variant.
    }
  }
  return null;
}

class _GrayLuminance extends LuminanceSource {
  _GrayLuminance(this._data, int width, int height) : super(width, height);

  final Int8List _data;

  @override
  Int8List getRow(int y, Int8List? row) {
    final out = (row == null || row.length < width) ? Int8List(width) : row;
    out.setRange(0, width, _data, y * width);
    return out;
  }

  @override
  Int8List getMatrix() => _data;
}

// ─── Native (Windows) ────────────────────────────────────────────────────────

typedef _GrabC = Int32 Function(
    Pointer<Uint8>, Int32, Pointer<Int32>, Pointer<Int32>, Int32);
typedef _GrabDart = int Function(
    Pointer<Uint8>, int, Pointer<Int32>, Pointer<Int32>, int);

/// Kadr buferi: VP930 RGB — 720×1024×3; zaxira bilan.
const int _frameBufferBytes = 4 * 1024 * 1024;

DynamicLibrary _frames(String sdkDir) =>
    openKaftpaySdkLibrary(sdkDir, KaftpaySdkQrReader.frameDll);

int _pfOpenNative(String sdkDir) => _frames(sdkDir)
    .lookupFunction<Int32 Function(), int Function()>('pf_open')();

void _pfCloseNative(String sdkDir) => _frames(sdkDir)
    .lookupFunction<Void Function(), void Function()>('pf_close')();

/// Isolate ichida: bitta kadr → QR. Qurilma holati DLL'da (jarayon bo'yicha
/// global) — pf_open boshqa isolate'da bo'lgani muammo emas.
KaftpayQrFrame _pfGrabNative(String sdkDir, int timeoutMs) {
  final grab = _frames(sdkDir).lookupFunction<_GrabC, _GrabDart>('pf_grab');
  final buf = malloc<Uint8>(_frameBufferBytes);
  final w = calloc<Int32>();
  final h = calloc<Int32>();
  try {
    final code = grab(buf, _frameBufferBytes, w, h, timeoutMs);
    if (code != 0) return KaftpayQrFrame(code);
    final width = w.value, height = h.value;
    final size = width * height * 3;
    if (width <= 0 || height <= 0 || size > _frameBufferBytes) {
      return const KaftpayQrFrame(-7);
    }
    final bgr = buf.asTypedList(size);
    // Kichraytirilganda topilmasa (QR kichik / uzoq) — to'liq o'lchamda.
    return KaftpayQrFrame(
        0,
        decodeKaftpayQr(bgr, width, height) ??
            decodeKaftpayQr(bgr, width, height, step: 1));
  } finally {
    malloc.free(buf);
    calloc.free(w);
    calloc.free(h);
  }
}
