// Bir kompyuterda ikki karta terminali (Uzcard + Humo) — Arcus2 profillari.
//
// Arcus2 CommandLineTool sozlamani faqat `C:\Arcus2\INI` dan o'qiydi, INI
// yo'lini beradigan parametr yo'q (ARCUS2.1 admin qo'llanmasi, 1_4_1).
// Shuning uchun har terminal uchun alohida papka saqlanadi:
//   C:\Arcus2\INI-uzcard\  (masalan PORT=COM9)
//   C:\Arcus2\INI-humo\    (masalan PORT=COM6)
// va to'lovdan OLDIN kerakli papka fayllari `C:\Arcus2\INI` ga ko'chiriladi.
//
// Profil papkasi bo'lmasa (bitta terminalli oddiy o'rnatish) — `INI` ga
// tegilmaydi, eski xatti-harakat saqlanadi.
//
// Yo'l ajratgichi `Platform.pathSeparator` — Windows'da `\`, testlarda `/`.

import 'dart:io';

enum ArcusTerminal { uzcard, humo }

class ArcusProfile {
  const ArcusProfile._();

  static const String defaultDir = r'C:\Arcus2';

  static final String _sep = Platform.pathSeparator;

  static String profileDirName(ArcusTerminal t) => 'INI-${t.name}';

  /// [t] terminal sozlamasini faollashtiradi.
  ///
  /// Muvaffaqiyatli bo'lsa yoki profil papkasi yo'q bo'lsa `null` qaytaradi.
  /// Ko'chirib bo'lmasa — kassirga ko'rsatiladigan xato matni (bu holda
  /// to'lovni boshlamaslik kerak: noto'g'ri terminalga so'rov ketishi mumkin).
  static Future<String?> activate(
    ArcusTerminal t, {
    String arcusDir = defaultDir,
  }) async {
    final src = Directory('$arcusDir$_sep${profileDirName(t)}');
    if (!await src.exists()) return null;

    final dst = Directory('$arcusDir${_sep}INI');
    try {
      if (!await dst.exists()) await dst.create(recursive: true);
      var copied = 0;
      await for (final e in src.list(followLinks: false)) {
        if (e is! File) continue;
        final name = e.uri.pathSegments.last;
        await e.copy('${dst.path}$_sep$name');
        copied++;
      }
      if (copied == 0) {
        return '${src.path} papkasi bo\'sh — terminal sozlamasi topilmadi.';
      }
      return null;
    } catch (e) {
      return 'Terminal sozlamasini (${profileDirName(t)}) faollashtirib '
          'bo\'lmadi: $e';
    }
  }
}
