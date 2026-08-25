// To'lov summasi qoidalari — `PaymentTallyController` dagi ikki formula.
//
// Bu formulalar `type*` metodlarida OLTI marta so'zma-so'z takrorlangan edi
// (Uzcard/Humo/Paynet — bir xil, Click/Payme/Uzum — boshqa). Faza 9.4 da
// bitta joyga yig'ildi; bu fayl ikkalasining farqini ham muzlatadi.
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
  group('amountMinusCurrent — terminal yo\'llari (Uzcard/Humo/Paynet)', () {
    test('summa kiritilmagan (0) → butun qoldiq', () {
      expect(tally(total: 100000).amountMinusCurrent(0), 100000);
    });

    test('kiritilgan summa qoldiqdan kichik → o\'zi qaytadi', () {
      expect(tally(total: 100000).amountMinusCurrent(30000), 30000);
    });

    test('kiritilgan summa qoldiqdan katta → qoldiq bilan cheklanadi', () {
      expect(tally(total: 100000).amountMinusCurrent(150000), 100000);
    });

    test('CHEGARA: aynan qoldiqcha kiritilsa o\'zi qaytadi', () {
      expect(tally(total: 100000).amountMinusCurrent(100000), 100000);
    });

    test('boshqa tur bilan qisman to\'langan bo\'lsa qoldiq kamayadi', () {
      final c = tally(total: 100000, selected: 'karta', paid: {'naqd': 40000});
      expect(c.amountMinusCurrent(0), 60000);
    });

    test('SHU tur bo\'yicha kiritilgan summa AYIRILADI (ikkilanish oldi)', () {
      // Chekda karta 30 000 bor; tugma qayta bosilsa qolgan 70 000 qaytishi
      // kerak (100 000 emas) — aks holda allPaymentType ustiga qo'shib yuboradi.
      final c = tally(total: 100000, selected: 'karta', paid: {'karta': 30000});
      expect(c.amountMinusCurrent(0), 70000);
    });

    test('SHU tur to\'liq yopgan bo\'lsa 0 qaytadi', () {
      final c =
          tally(total: 100000, selected: 'karta', paid: {'karta': 100000});
      expect(c.amountMinusCurrent(0), 0);
    });

    test('kiritilgan summa qolgan bo\'shliqdan katta → bo\'shliq qaytadi', () {
      final c = tally(total: 100000, selected: 'karta', paid: {'karta': 90000});
      expect(c.amountMinusCurrent(50000), 10000);
    });

    test('ortiqcha to\'langan bo\'lsa manfiy qaytadi', () {
      final c =
          tally(total: 100000, selected: 'karta', paid: {'karta': 130000});
      expect(c.amountMinusCurrent(0), -30000);
    });

    test('kasrli summa saqlanadi', () {
      expect(tally(total: 100000).amountMinusCurrent(1500.5), 1500.5);
    });
  });

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

  group('Ikki formulaning FARQI (qayd etilgan xatti-harakat)', () {
    test('SHU tur bo\'yicha to\'lov bor: minusCurrent kamaytiradi, '
        'ignoringCurrent — YO\'Q', () {
      final c = tally(total: 100000, selected: 'click', paid: {'click': 30000});
      expect(c.amountMinusCurrent(0), 70000);
      expect(c.amountIgnoringCurrent(0), 100000,
          reason: 'QAYD: onlayn yo\'llar joriy summani ayirmaydi — '
              'tugma ikki marta bosilsa summa oshib ketishi mumkin');
    });

    test('SHU tur bo\'yicha to\'lov yo\'q bo\'lsa ikkalasi bir xil', () {
      final c = tally(total: 100000, selected: 'click', paid: {'naqd': 20000});
      expect(c.amountMinusCurrent(0), c.amountIgnoringCurrent(0));
    });
  });
}
