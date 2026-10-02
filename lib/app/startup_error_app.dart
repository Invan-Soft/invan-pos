/*
    Dastur ishga tushmasa — sabab ko'rsatiladigan ekran.

    main() runApp'gacha bazalar va sozlamalarni tayyorlaydi. Shu qadamlardan
    biri xato bersa, ilgari dastur birinchi ekranni umuman chizmasdi: Mac'da
    qora oyna qolardi, Windows'da esa oyna startup'da yashirin bo'lgani uchun
    dastur "ochilmasdi" — kassir sababini bilmasdi.

    Qachon bo'ladi (misollar):
    - cheklar bazasi (ObjectBox) dastur versiyasiga mos emas: dastur eski
      versiyaga qaytarilgan (patch rollback, eski installer) yoki shu
      kompyuterda boshqa InVan dasturi bazani o'z sxemasiga yangilagan
      (Mac sinovi, 2026-10-02: "DB's last property ID 61 is higher than the
      incoming one 50 in entity ReceiptModel4");
    - baza fayli buzilgan (kompyuter to'satdan o'chgan), disk to'la;
    - Hive fayli boshqa nusxa tomonidan band (dastur ikki marta ochilgan).

    Bu ekran Hive/Pref/tarjimaga BOG'LIQ EMAS (ular ochilmagan bo'lishi
    mumkin) — matn ikki tilda.
*/

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/patch_updater.dart';

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  /// Cheklar bazasi sxemasi dastur versiyasiga mos emasmi.
  bool get _isDbSchemaMismatch {
    final String text = '$error';
    return text.contains('last property ID') ||
        text.contains('last entity ID') ||
        text.contains('last index ID') ||
        text.contains('last relation ID');
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFF111A22);
    const Color red = Color(0xFFE53935);
    const TextStyle title =
        TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold);
    const TextStyle body = TextStyle(color: Colors.white70, fontSize: 17, height: 1.4);

    final String uz = _isDbSchemaMismatch
        ? 'Kassadagi ma\'lumotlar bazasi dasturning bu versiyasiga mos emas. '
            'Odatda dastur eski versiyaga qaytarilganda yoki shu kompyuterda '
            'boshqa InVan dasturi ishlatilganda bo\'ladi.\n'
            'Cheklar o\'chirilmagan — ular bazada saqlanib turibdi. '
            'Administratorga murojaat qiling.'
        : 'Dasturni ishga tushirishda xato yuz berdi. Qayta ishga tushirib '
            'ko\'ring. Takrorlansa — administratorga murojaat qiling va '
            'pastdagi matnni yuboring.';
    final String ru = _isDbSchemaMismatch
        ? 'База данных кассы не подходит к этой версии программы. Обычно это '
            'бывает, когда программу откатили на старую версию или на этом '
            'компьютере использовалась другая программа InVan.\n'
            'Чеки не удалены — они сохранены в базе. Обратитесь к '
            'администратору.'
        : 'При запуске программы произошла ошибка. Попробуйте перезапустить. '
            'Если повторится — обратитесь к администратору и отправьте текст '
            'ниже.';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: red, size: 56),
                  const SizedBox(height: 16),
                  const Text('Dastur ishga tushmadi', style: title),
                  const SizedBox(height: 8),
                  Text(uz, style: body),
                  const SizedBox(height: 24),
                  const Text('Программа не запустилась', style: title),
                  const SizedBox(height: 8),
                  Text(ru, style: body),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      '$error',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13, height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _restart,
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                            'Qayta ishga tushirish / Перезапустить'),
                      ),
                      OutlinedButton(
                        onPressed: () => exit(0),
                        child: const Text('Yopish / Закрыть',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dasturni qayta ochadi. Startup'dagi patch tekshiruvi ATAYLAB
  /// o'tkazib yuborilmaydi: muammoni tuzatuvchi patch chiqqan bo'lsa,
  /// qayta ochilishda u qo'llanadi.
  static Future<void> _restart() async {
    try {
      await Process.start(
        Platform.resolvedExecutable,
        const <String>[],
        mode: ProcessStartMode.detached,
        workingDirectory: File(Platform.resolvedExecutable).parent.path,
        environment: restartEnvironment(Platform.environment),
        includeParentEnvironment: false,
      );
    } catch (_) {
      // Ochib bo'lmasa ham joriy jarayon yopiladi — kassir qo'lda ochadi.
    }
    exit(0);
  }

  /// Windows runner (`windows/runner/win32_window.cpp` `CheckOneInstance`)
  /// shu belgini ko'rsa eski nusxa yopilishini kutadi — aks holda yangi
  /// nusxa "ikkinchi nusxa" deb jim yopilib qolishi mumkin.
  static const String restartEnv = 'INVAN_RESTART';

  /// Yangi jarayon muhiti. Joriy jarayon patch uchun o'zi qayta yongan
  /// bo'lsa (masalan yangi patch bazani ochmadi), uning yangilanish belgisi
  /// meros bo'lib o'tmasin: aks holda yangi jarayon patch tekshiruvini
  /// o'tkazib yuborardi (rollback'ni ushlamasdi) va "Dastur yangilandi"
  /// derdi.
  @visibleForTesting
  static Map<String, String> restartEnvironment(Map<String, String> current) =>
      Map<String, String>.of(current)
        ..remove(PatchUpdater.relaunchedEnv)
        ..[restartEnv] = '1';
}
