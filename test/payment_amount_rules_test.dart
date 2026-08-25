// To'lov summasi qoidalari — `PaymentTallyController` dagi ikki formula.
//
// Bu formula Click / Payme / Uzum / Paynet yo'llarida uch marta so'zma-so'z
// takrorlangan edi; Faza 9.4 da bitta joyga yig'ildi.
//
// Uzcard/Humo (Arcus terminali) yo'llari ATAYLAB tegilmagan — ularni sinash
// uchun fizik terminal kerak, u yo'q. Ularning formulasi providerda, asl
// holida qoldi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/providers/ordering/payment_tally_controller.dart';
import 'package:invan2/changes/models/organization_model.dart';

/// Berilgan chek jami va allaqachon kiritilgan to'lovlar bilan tally.
PaymentTallyController tally({
  double total = 100000,
  String selected = 'karta',
  Map<String, double> paid = const {},
}) {
  final c = PaymentTallyController(() {});
  c.totalPrice = total;
  c.selectedPaymentType = selected;
  paid.forEach((id, value) {
    c.paymentsMap[id] = Payment(id: id, name: id, value: value, type: 0);
  });
  return c;
}

void main() {
  group('amountIgnoringCurrent — onlayn yo\'llar (Click/Payme/Uzum)', () {
    test('summa kiritilmagan → butun qoldiq', () {
      expect(tally(total: 100000).amountIgnoringCurrent(0), 100000);
    });

    test('kiritilgan summa qoldiqdan kichik → o\'zi', () {
      expect(tally(total: 100000).amountIgnoringCurrent(30000), 30000);
    });

    test('kiritilgan summa qoldiqdan katta → qoldiq', () {
      expect(tally(total: 100000).amountIgnoringCurrent(150000), 100000);
    });

    test('boshqa tur bilan qisman to\'langan bo\'lsa qoldiq kamayadi', () {
      final c = tally(total: 100000, selected: 'click', paid: {'naqd': 40000});
      expect(c.amountIgnoringCurrent(0), 60000);
    });
  });
}
