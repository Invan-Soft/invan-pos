import 'dart:convert';
import 'dart:io';

import 'package:invan2/features/printing/model/printer_model.dart';
import 'package:path_provider/path_provider.dart' as pp;

/// Printer sozlamalarini Hive'dan TASHQARI, alohida oddiy JSON faylga atomik
/// saqlaydi va kerak bo'lsa tiklaydi.
///
/// Nega kerak: printers.hive ga yozilgan ma'lumot diskka darrov tushmaydi
/// (Hive `box.add()` flush qilmaydi — OS buferida turadi). Svet o'chsa /
/// dastur to'satdan o'lsa OS flush qilishidan oldin — yozuv yo'qoladi va
/// printer sozlamasi "o'zidan o'chgan" bo'lib ko'rinadi.
///
/// Bu backup undan himoya qiladi:
///  - `.tmp` ga yozib, keyin `rename` — OS darajasida atomik (yarim-yozilgan
///    fayl bo'lmaydi: yo to'liq eski, yo to'liq yangi).
///  - `flush: true` — baytlar diskka kafolatli tushadi.
///  - startup'da Hive box bo'sh bo'lsa (qanday sababdan bo'lsa ham) shu fayldan
///    tiklanadi (SELF-HEAL).
class PrinterBackup {
  static const _fileName = 'printers_backup.json';

  /// Backup fayli Hive printers box bilan bir papkada turadi
  /// (main.dart hiveOpen() dagi yo'llarga mos).
  static Future<File> _file() async {
    if (Platform.isWindows) {
      const dir = r'C:\ProgramData\InVanPos2\cache\printers\';
      return File('$dir$_fileName');
    }
    final support = await pp.getApplicationSupportDirectory();
    // main.dart else bloki: path: "${basePath}printers", basePath = "${dir}/pos"
    final dir = Directory('${support.path}/posprinters');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  /// Printer ro'yxatini atomik (xavfsiz) saqlaydi. Xatolik asosiy oqimni
  /// buzmaydi — backup ixtiyoriy himoya qatlami.
  static Future<void> save(List<PrinterModel> printers) async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);

      final data = printers
          .map((p) => {
                'name': p.name,
                'url': p.url,
                'model': p.model,
                'location': p.location,
                'comment': p.comment,
                'paperSize': p.paperSize,
              })
          .toList();

      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(data), flush: true);
      await tmp.rename(f.path); // atomik almashtirish
    } catch (_) {
      // backup yozib bo'lmadi — jim o'tamiz, asosiy ish to'xtamaydi.
    }
  }

  /// Backupdan o'qiydi. Fayl yo'q/bo'sh/buzilgan bo'lsa bo'sh ro'yxat qaytaradi.
  static Future<List<PrinterModel>> load() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return [];
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return [];

      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PrinterModel(
                name: e['name'] as String?,
                url: e['url'] as String?,
                model: e['model'] as String?,
                location: e['location'] as String?,
                comment: e['comment'] as String?,
                paperSize: e['paperSize'] as int?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Backup faylini o'chiradi (logout'da chaqiriladi — printer ham tozalanadi).
  static Future<void> clear() async {
    try {
      final f = await _file();
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}
