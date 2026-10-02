import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/app/startup_error_app.dart';
import 'package:invan2/changes/services/patch_updater.dart';

/// Dastur ishga tushmaganda ko'rsatiladigan ekran (qora/ko'rinmas oyna
/// o'rniga). Mac sinovida (2026-10-02) haqiqiy sabab — boshqa InVan dasturi
/// cheklar bazasini o'z sxemasiga yangilagan edi.
void main() {
  setUp(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize =
        const Size(1600, 1200);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  testWidgets(
      'ObjectBox sxemasi mos emas — bazaga oid aniq sabab va "cheklar '
      'o\'chirilmagan" ko\'rsatiladi', (WidgetTester tester) async {
    await tester.pumpWidget(StartupErrorApp(
      error: Exception('ObjectBoxException: failed to create store: DB\'s '
          'last property ID 61 is higher than the incoming one 50 in entity '
          'ReceiptModel4'),
    ));

    expect(find.text('Dastur ishga tushmadi'), findsOneWidget);
    expect(find.text('Программа не запустилась'), findsOneWidget);
    expect(find.textContaining('dasturning bu versiyasiga mos emas'),
        findsOneWidget);
    expect(find.textContaining('Cheklar o\'chirilmagan'), findsOneWidget);
    expect(find.textContaining('last property ID 61'), findsOneWidget,
        reason: 'administrator uchun asl xato matni ko\'rinishi kerak');
    expect(find.text('Qayta ishga tushirish / Перезапустить'), findsOneWidget);
    expect(find.text('Yopish / Закрыть'), findsOneWidget);
  });

  testWidgets('boshqa xato — umumiy matn, baza haqida gapirilmaydi',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        const StartupErrorApp(error: 'HiveError: box is already locked'));

    expect(find.text('Dastur ishga tushmadi'), findsOneWidget);
    expect(find.textContaining('Qayta ishga tushirib'), findsOneWidget);
    expect(find.textContaining('versiyasiga mos emas'), findsNothing);
    expect(find.textContaining('box is already locked'), findsOneWidget);
  });

  test(
      'qayta ishga tushirish yangilanish belgisini meros qilmaydi — yangi '
      'jarayon patch tekshiruvini (rollback) o\'tkazib yubormaydi', () {
    final Map<String, String> env =
        StartupErrorApp.restartEnvironment(<String, String>{
      'PATH': r'C:\Windows\system32',
      PatchUpdater.relaunchedEnv: '1',
    });

    expect(env.containsKey(PatchUpdater.relaunchedEnv), isFalse);
    expect(env['PATH'], r'C:\Windows\system32',
        reason: 'qolgan muhit o\'zgarmasdan o\'tadi');
    expect(env[StartupErrorApp.restartEnv], '1',
        reason: 'Windows runner eski nusxa yopilishini kutsin');
  });
}
