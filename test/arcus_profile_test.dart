// ArcusProfile — bir kompyuterda Uzcard va Humo terminallari uchun
// INI-uzcard / INI-humo papkalaridan C:\Arcus2\INI ni almashtirish.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/payment/arcus_profile.dart';

final _sep = Platform.pathSeparator;

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('arcus_profile_test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<void> makeProfile(String name, String port) async {
    final d = await Directory('${dir.path}$_sep$name').create();
    await File('${d.path}${_sep}cashreg.ini').writeAsString('PORT=$port\n');
    await File('${d.path}${_sep}ops.ini').writeAsString('1=1,1,OPLATA\n');
  }

  String activePort() =>
      File('${dir.path}${_sep}INI${_sep}cashreg.ini').readAsStringSync().trim();

  test('INI yo\'q bo\'lsa yaratiladi va kerakli profil ko\'chiriladi',
      () async {
    await makeProfile('INI-uzcard', 'COM9');
    await makeProfile('INI-humo', 'COM6');

    expect(await ArcusProfile.activate(ArcusTerminal.humo, arcusDir: dir.path),
        isNull);
    expect(activePort(), 'PORT=COM6');
    expect(File('${dir.path}${_sep}INI${_sep}ops.ini').existsSync(), isTrue);

    expect(
        await ArcusProfile.activate(ArcusTerminal.uzcard, arcusDir: dir.path),
        isNull);
    expect(activePort(), 'PORT=COM9');
  });

  test('profil papkasi yo\'q (bitta terminal) — INI ga tegilmaydi', () async {
    final ini = await Directory('${dir.path}${_sep}INI').create();
    await File('${ini.path}${_sep}cashreg.ini').writeAsString('PORT=COM10\n');

    expect(await ArcusProfile.activate(ArcusTerminal.humo, arcusDir: dir.path),
        isNull);
    expect(activePort(), 'PORT=COM10');
  });

  test('profil papkasi bo\'sh — xato matni qaytadi', () async {
    await Directory('${dir.path}${_sep}INI-humo').create();

    final err =
        await ArcusProfile.activate(ArcusTerminal.humo, arcusDir: dir.path);
    expect(err, isNotNull);
  });
}
