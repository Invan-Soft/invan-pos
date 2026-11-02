// Yon menyudagi Kaftpay: PIN — oyna; sahifa butun oyna bo'ylab (keng ekranda
// ikki ustun: sozlash va to'lovlar tarixi).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/features/kaftpay/kaftpay_pin_dialog.dart';
import 'package:invan2/features/settings/view/payments/kaftpay_content.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await setUpPosTestEnv('kaftpay_page', withEmployee: false);
    await Pref.setString(PrefKeys.kaftpayId, 'kp');
  });
  tearDownAll(tearDownPosTestEnv);

  Future<void> app(WidgetTester tester, Widget home, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('uz'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    ));
    await tester.pump();
  }

  /// PIN maydoni kursori miltillaydi — pumpAndSettle tugamaydi.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('PIN oynasi', () {
    Future<bool? Function()> open(WidgetTester tester) async {
      bool? result;
      await app(
          tester,
          Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () async => result = await KaftpayPinDialog.show(ctx,
                    check: (pin) => pin == '1234'),
                child: const Text('open'),
              ),
            ),
          ),
          const Size(1280, 900));
      await tester.tap(find.text('open'));
      await settle(tester);
      return () => result;
    }

    Future<void> typePin(WidgetTester tester, String pin) async {
      await tester.enterText(
          find.descendant(
              of: find.byKey(const ValueKey('kaftpay_pin_field')),
              matching: find.byType(EditableText)),
          pin);
      await settle(tester);
    }

    testWidgets(
        'noto\'g\'ri PIN — oyna qoladi, xato ko\'rinadi; to\'g\'ri — true',
        (tester) async {
      final r = await open(tester);
      await typePin(tester, '9999');
      expect(find.byType(KaftpayPinDialog), findsOneWidget);
      expect(find.textContaining('Noto\'g\'ri PIN'), findsOneWidget);
      await typePin(tester, '1234');
      expect(find.byType(KaftpayPinDialog), findsNothing);
      expect(r(), isTrue);
    });

    testWidgets('bekor qilish — false', (tester) async {
      final r = await open(tester);
      await tester.tap(find.byKey(const ValueKey('kaftpay_pin_cancel')));
      await settle(tester);
      expect(r(), isFalse);
    });
  });

  group('Sahifa joylashuvi', () {
    testWidgets('keng ekran — ikki ustun (tarix o\'ngda)', (tester) async {
      await app(tester, const KaftpayContent(), const Size(1600, 1000));
      expect(
          find.byKey(const ValueKey('kaftpay_setup_column')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('kaftpay_history_column')), findsOneWidget);
      final setup =
          tester.getRect(find.byKey(const ValueKey('kaftpay_setup_column')));
      final history =
          tester.getRect(find.byKey(const ValueKey('kaftpay_history_column')));
      expect(setup.left, 0);
      expect(history.right, 1600, reason: 'butun oyna bo\'ylab');
      expect(history.left, greaterThanOrEqualTo(setup.right));
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('kaftpay_history_column')),
              matching: find.text('To\'lovlar tarixi')),
          findsOneWidget);
    });

    testWidgets('tor ekran — bitta ustun', (tester) async {
      await app(tester, const KaftpayContent(), const Size(900, 1000));
      expect(
          find.byKey(const ValueKey('kaftpay_history_column')), findsNothing);
      expect(find.byKey(const ValueKey('kaftpay_ping')), findsOneWidget);
    });
  });
}
