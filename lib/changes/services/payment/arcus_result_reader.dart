// Arcus2 (karta terminali) natijasini o'qish — faqat SHU operatsiyaga tegishli
// fayllarga ishonadi.
//
// Sabab (2026-10-20): Arcus2 INI papkasi topilmay, 999 bilan darhol chiqib
// ketganda yangi log/cheq.out yozilmadi. Eski kod `Logs` dagi oxirgi faylni va
// eski `cheq.out` ni o'qib, oldingi muvaffaqiyatli to'lovni yangi to'lov deb
// qabul qildi: terminalga so'rov bormasdan "ОДОБРЕНО" chiqdi va eski chek
// chop etildi. Endi fayl operatsiya boshlangandan keyin yozilgan bo'lishi shart.
//
// Yo'l ajratgichi `Platform.pathSeparator`: Windows'da `\` (avvalgidek
// `C:\Arcus2\Logs`), testlar macOS/Linux'da ham to'g'ri papkaga yozadi.

import 'dart:io';

import 'package:windows1251/windows1251.dart';

class ArcusRunResult {
  /// Shu operatsiya logi; yangi log bo'lmasa — tushuntirish matni.
  final String log;

  /// Shu operatsiya cheq.out matni; yangi bo'lmasa — bo'sh.
  final String receipt;

  /// Log shu operatsiya davomida yozilganmi. `false` bo'lsa natijaga
  /// ishonib bo'lmaydi — to'lov tasdiqlangan deb hisoblanmasligi kerak.
  final bool isFresh;

  const ArcusRunResult({
    required this.log,
    required this.receipt,
    required this.isFresh,
  });
}

class ArcusResultReader {
  const ArcusResultReader._();

  static const String defaultDir = r'C:\Arcus2';

  /// Fayl vaqti tizim soati bilan bir xil manbadan, lekin yaxlitlash
  /// (FAT/NTFS) farqi uchun kichik zaxira.
  static const Duration _tolerance = Duration(seconds: 2);

  static final String _sep = Platform.pathSeparator;

  /// Operatsiyani boshlashdan OLDIN chaqiriladi.
  static DateTime markStart() => DateTime.now();

  /// [startedAt] dan keyin yozilgan eng yangi log va cheq.out ni o'qiydi.
  static Future<ArcusRunResult> read({
    required DateTime startedAt,
    String arcusDir = defaultDir,
  }) async {
    final threshold = startedAt.subtract(_tolerance);

    File? newestLog;
    DateTime? newestTime;
    final logsDir = Directory('$arcusDir${_sep}Logs');
    if (await logsDir.exists()) {
      await for (final e in logsDir.list(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        final t = (await e.stat()).modified;
        if (newestTime == null || t.isAfter(newestTime)) {
          newestTime = t;
          newestLog = e;
        }
      }
    }

    final bool logFresh = newestLog != null && !newestTime!.isBefore(threshold);

    if (!logFresh) {
      final rc = await _readOutputRc(arcusDir);
      return ArcusRunResult(
        log: 'Arcus2 bu operatsiya uchun log yozmadi'
            '${rc.isNotEmpty ? ' (kod: $rc)' : ''}.\n'
            'Arcus2 ishga tushmadi yoki sozlama (INI) topilmadi.\n'
            'Terminalga so\'rov yuborilmadi.\n'
            'Arcus2 не записал лог этой операции. НЕТ СВЯЗИ С ПИН-ПАДОМ',
        receipt: '',
        isFresh: false,
      );
    }

    final log = windows1251.decode(await newestLog.readAsBytes());

    String receipt = '';
    final cheq = File('$arcusDir${_sep}cheq.out');
    if (await cheq.exists()) {
      final t = (await cheq.stat()).modified;
      if (!t.isBefore(threshold)) {
        receipt = windows1251.decode(await cheq.readAsBytes());
      }
    }

    return ArcusRunResult(log: log, receipt: receipt, isFresh: true);
  }

  /// output.dat ning birinchi qatori — Arcus javob kodi (masalan 999).
  static Future<String> _readOutputRc(String arcusDir) async {
    try {
      final f = File('$arcusDir${_sep}output.dat');
      if (!await f.exists()) return '';
      final lines = windows1251.decode(await f.readAsBytes()).split('\n');
      return lines.isEmpty ? '' : lines.first.trim();
    } catch (_) {
      return '';
    }
  }
}
