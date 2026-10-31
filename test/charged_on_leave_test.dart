// To'lov sahifasidan chiqish: pul yechilgan (Kaftpay, terminal orqali
// Uzcard / Humo) bo'lsa — tasdiq oynasi; qo'lda belgilangan karta — yo'q.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/payment/charged_on_leave.dart';
import 'package:invan2/changes/models/organization_model.dart' show Payment;
import 'package:invan2/features/payment/leave_charged_dialog.dart';

const kCard = 'pay-card';
const kKaft = 'pay-kaftpay';

Map<String, Payment> map(Map<String, double> v) => {
      for (final e in v.entries)
        e.key: Payment(id: e.key.replaceFirst('@', ''), value: e.value),
    };

List<ChargedPayment> of(
  Map<String, double> v, {
  bool uzcardTerminal = true,
  bool humoTerminal = true,
  String kaftpayId = kKaft,
}) =>
    ChargedOnLeave.of(map(v),
        kaftpayId: kaftpayId,
        cardId: kCard,
        uzcardTerminal: uzcardTerminal,
        humoTerminal: humoTerminal);

String kinds(List<ChargedPayment> l) =>
    l.map((c) => '${c.kind.name}:${c.amount.toInt()}').join(',');

void main() {
  group('ChargedOnLeave', () {
    test('bo\'sh / faqat naqd — chiqish erkin', () {
      expect(of({}), isEmpty);
      expect(of({'pay-cash': 50000}), isEmpty);
    });

    test('Kaftpay yechilgan', () {
      expect(kinds(of({'pay-cash': 40000, kKaft: 60000})), 'kaftpay:60000');
    });

    test(
        'Uzcard terminal orqali — ogohlantiriladi; integratsiya o\'chiq — yo\'q',
        () {
      expect(kinds(of({kCard: 30000})), 'uzcard:30000');
      expect(of({kCard: 30000}, uzcardTerminal: false), isEmpty,
          reason: 'qo\'lda belgi — pul dastur orqali yechilmagan');
    });

    test('Humo ("@cardId") terminal orqali — ogohlantiriladi', () {
      expect(kinds(of({'@$kCard': 25000})), 'humo:25000');
      expect(of({'@$kCard': 25000}, humoTerminal: false), isEmpty);
      // Uzcard sozlamasi Humo'ga ta'sir qilmaydi va aksincha.
      expect(
          kinds(of({'@$kCard': 25000}, uzcardTerminal: false)), 'humo:25000');
      expect(kinds(of({kCard: 25000}, humoTerminal: false)), 'uzcard:25000');
    });

    test('aralash: naqd + Uzcard + Humo + Kaftpay', () {
      expect(
          kinds(of({
            'pay-cash': 10000,
            kCard: 20000,
            '@$kCard': 30000,
            kKaft: 40000,
          })),
          'kaftpay:40000,uzcard:20000,humo:30000');
    });

    test('0 summali qatorlar va sozlanmagan id\'lar hisobga olinmaydi', () {
      expect(of({kKaft: 0, kCard: 0}), isEmpty);
      expect(of({kKaft: 5000}, kaftpayId: ''), isEmpty);
      expect(
          ChargedOnLeave.of(map({'': 100, '@': 100}),
              kaftpayId: '',
              cardId: '',
              uzcardTerminal: true,
              humoTerminal: true),
          isEmpty);
    });
  });

  group('LeaveChargedDialog', () {
    Future<bool? Function()> open(
        WidgetTester tester, List<ChargedPayment> charged) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: TextButton(
                  onPressed: () async => result =
                      await LeaveChargedDialog.show(ctx, charged: charged),
                  child: const Text('open')),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return () => result;
    }

    const both = [
      ChargedPayment(ChargedKind.kaftpay, 60000),
      ChargedPayment(ChargedKind.uzcard, 40000),
    ];

    testWidgets('summalar ko\'rinadi; "Qolish" → false', (tester) async {
      final r = await open(tester, both);
      expect(
          find.byKey(const ValueKey('leave_charged_kaftpay')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('leave_charged_uzcard')), findsOneWidget);
      expect(find.text("60,000 so'm"), findsOneWidget);
      expect(find.text("40,000 so'm"), findsOneWidget);
      expect(find.textContaining('Sozlamalar › Kaftpay'), findsOneWidget);
      expect(find.textContaining('terminalda bekor qilish'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('leave_stay')));
      await tester.pumpAndSettle();
      expect(r(), isFalse);
    });

    testWidgets('"Baribir chiqish" → true', (tester) async {
      final r = await open(tester, const [ChargedPayment(ChargedKind.humo, 1)]);
      expect(find.textContaining('Sozlamalar › Kaftpay'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('leave_anyway')));
      await tester.pumpAndSettle();
      expect(r(), isTrue);
    });
  });
}
