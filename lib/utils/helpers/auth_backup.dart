import 'dart:io';

class AuthBackup {
  static const _path = r'C:\ProgramData\InVanPos2\cache\auth_backup.dat';

  static Future<void> save(String token) async {
    try {
      final file = File(_path);
      await file.parent.create(recursive: true);
      await file.writeAsString(token, flush: true);
    } catch (_) {}
  }

  static Future<String> read() async {
    try {
      final file = File(_path);
      if (await file.exists()) return await file.readAsString();
    } catch (_) {}
    return '';
  }

  static Future<void> delete() async {
    try {
      final file = File(_path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
