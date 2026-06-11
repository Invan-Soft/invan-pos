import 'dart:io';

import 'package:shell/shell.dart';

/// OFD server manzillarini avtomatik yangilash.
///
/// Soliq 2026-yil 1-maydan boshlab eski OFD domenlarini (ofd1..ofd4.yt.uz)
/// o'chiradi. FiscalDriveAPI config faylida eski manzillar qolib ketsa,
/// servis ularga ulanishga urinib timeout kutadi (sotuv sekinlashadi) yoki
/// 1-maydan keyin cheklar umuman yuborilmaydi.
///
/// Bu sinf ilova ishga tushganda BIR MARTA tekshiradi: agar config'da eski
/// manzil bo'lsa, [server] bo'limini faqat yangi manzillar (s0..s2.ofd.uz)
/// bilan qayta yozadi va FiscalDriveAPI jarayonini qayta ishga tushiradi
/// (NSSM uni avtomatik tiklaydi — kompyuterni restart qilish shart emas).
///
/// MUHIM: `C:\Program Files` ga yozish va jarayonni o'chirish admin huquqini
/// talab qiladi. Ilova admin sifatida ishlamasa, yozish "access denied" bilan
/// tugaydi — bu holat log faylga yoziladi (jim o'tib ketmaydi).
class OfdConfigMigrator {
  /// Config fayli ehtimoliy joylashuvlari (screenshot'dan tasdiqlangan birinchisi).
  static const List<String> _configPaths = [
    r'C:\Program Files\FiscalDriveAPI\config',
    r'C:\Program Files (x86)\FiscalDriveAPI\config',
  ];

  /// 1-maydan keyin o'chiriladigan eski OFD hostlari.
  static const List<String> _oldHosts = [
    'ofd1.yt.uz',
    'ofd2.yt.uz',
    'ofd3.yt.uz',
    'ofd4.yt.uz',
  ];

  /// Yangi (yagona to'g'ri) OFD hostlari.
  static const List<String> _newHosts = [
    's0.ofd.uz',
    's1.ofd.uz',
    's2.ofd.uz',
  ];

  /// [server] bo'limiga yoziladigan yakuniy qatorlar.
  static const List<String> _newServerLines = [
    'address.4 = s0.ofd.uz:3447',
    'address.5 = s1.ofd.uz:3447',
    'address.6 = s2.ofd.uz:3447',
  ];

  /// FiscalDriveAPI jarayoni nomi (NSSM bilan boshqariladi).
  static const String _processName = 'fiscal-drive-api.exe';

  /// Tekshirish log fayli — kassa kompyuterida natijani ko'rish uchun.
  static const String _logPath =
      r'C:\ProgramData\InVanPos2\cache\ofd_migration.log';

  /// Ilova startup'ida chaqiriladi. Hech qachon exception otmaydi —
  /// xatolar log'ga yoziladi, ilova ishini to'xtatmaydi.
  static Future<void> migrateIfNeeded() async {
    if (!Platform.isWindows) return;

    try {
      final file = _findConfig();
      if (file == null) {
        await _log('config fayli topilmadi (FiscalDriveAPI o\'rnatilmaganmi?)');
        return;
      }

      final original = await file.readAsString();

      if (!_hasOldHosts(original)) {
        await _log('eski manzil yo\'q — o\'zgartirish shart emas: ${file.path}');
        return;
      }

      final updated = _rewriteServerSection(original);
      if (updated == original) {
        await _log('[server] bo\'limi topilmadi — qo\'lda tekshirish kerak');
        return;
      }

      // Avval zaxira nusxa (xato bo'lsa qaytarish uchun).
      try {
        await File('${file.path}.bak').writeAsString(original);
      } catch (e) {
        await _log('ogohlantirish: zaxira nusxa yozilmadi: $e');
      }

      // Asosiy yozuv — admin bo'lmasa shu yerda "access denied" beradi.
      await file.writeAsString(updated);
      await _log('config YANGILANDI: ${file.path}');

      final restarted = await _restartFiscalService();
      await _log(restarted
          ? 'FiscalDriveAPI jarayoni qayta ishga tushirildi'
          : 'ogohlantirish: jarayon qayta ishga tushmadi (admin yo\'qmi?)');
    } catch (e) {
      await _log('XATO: $e');
    }
  }

  static File? _findConfig() {
    for (final path in _configPaths) {
      final f = File(path);
      if (f.existsSync()) return f;
    }
    return null;
  }

  static bool _hasOldHosts(String content) {
    return _oldHosts.any((h) => content.contains(h));
  }

  /// Faqat [server] bo'limini qayta yozadi. Boshqa hamma narsaga
  /// (factory_id, [api], [qrcode], izohlar) tegmaydi.
  static String _rewriteServerSection(String content) {
    final lines = content.split('\n');

    final headerIdx =
        lines.indexWhere((l) => l.trim().toLowerCase() == '[server]');
    if (headerIdx == -1) return content; // [server] yo'q — tegmaymiz

    // Bo'lim oxiri: keyingi [bolim] yoki fayl oxiri.
    int endIdx = lines.length;
    for (int i = headerIdx + 1; i < lines.length; i++) {
      final t = lines[i].trim();
      if (t.startsWith('[') && t.endsWith(']')) {
        endIdx = i;
        break;
      }
    }

    final before = lines.sublist(0, headerIdx + 1);
    final body = lines.sublist(headerIdx + 1, endIdx);
    final after = lines.sublist(endIdx);

    // Eski va mavjud yangi address qatorlarini olib tashlaymiz
    // (yangilarini kanonik holatda qayta qo'shamiz). Izoh va boshqa
    // sozlamalar saqlanadi.
    final preserved = <String>[];
    for (final line in body) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final isOld = _oldHosts.any((h) => t.contains(h));
      final isNew = _newHosts.any((h) => t.contains(h));
      if (isOld || isNew) continue;
      preserved.add(line);
    }

    final newBody = <String>[...preserved, ..._newServerLines];

    return [...before, ...newBody, '', ...after].join('\n');
  }

  /// FiscalDriveAPI jarayonini o'chiradi — NSSM uni yangi config bilan
  /// avtomatik qayta ishga tushiradi. Kompyuter restart talab qilinmaydi.
  static Future<bool> _restartFiscalService() async {
    try {
      final shell = Shell();
      final out = await shell.startAndReadAsString(
        'cmd',
        arguments: ['/c', 'taskkill', '/F', '/IM', _processName],
      );
      // taskkill muvaffaqiyatda "SUCCESS"/"УСПЕХ" beradi.
      return out.toUpperCase().contains('SUCCESS') ||
          out.toUpperCase().contains('УСПЕ') ||
          out.toUpperCase().contains('PID');
    } catch (e) {
      await _log('jarayonni o\'chirishda xato: $e');
      return false;
    }
  }

  static Future<void> _log(String message) async {
    final line = '${DateTime.now().toIso8601String()}  $message';
    // ignore: avoid_print
    print('[OfdConfigMigrator] $line');
    try {
      final f = File(_logPath);
      await f.create(recursive: true);
      await f.writeAsString('$line\n', mode: FileMode.append);
    } catch (_) {
      // Log faylga yozolmasa ham ilova ishini to'xtatmaymiz.
    }
  }
}
