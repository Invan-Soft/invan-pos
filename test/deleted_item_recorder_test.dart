// `DeletedItemRecorder` — to'g'ridan-to'g'ri (providersiz) testlar.
//
// `deleted_items_orderpos_test` (54) va `deleted_item_record_test` (15)
// xatti-harakatni provider orqali qamraydi. Bu yerda modul yuzasi: xodim
// IDsi callback shartnomasi va chetki qiymatlar. Ilgari bu kod Hive'ga
// (`HiveBoxes.getCurrentEmployee`) qattiq bog'langan edi — endi callback,
// shuning uchun har fallback shoxini bevosita ko'rsatib bo'ladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/deleted_item_recorder.dart';
import 'package:invan2/changes/models/deleted_item_model.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

List<DeletedItemModel4> recordOne(
  ReceiptModelSoldItem4 item, {
  double? quantity,
  Employee? approvedBy,
  String employeeId = 'kassir-1',
}) {
  final into = <DeletedItemModel4>[];
  DeletedItemRecorder.record(
    into,
    item,
    quantity: quantity,
    approvedBy: approvedBy,
    currentEmployeeId: () => employeeId,
  );
  return into;
}

void main() {
  group('record — yozish sharti', () {
    test('oddiy qator yoziladi', () {
      expect(recordOne(makeSoldItem(price: 5000)).length, 1);
    });

    test('allaqachon o\'chirilgan qator yozilmaydi', () {
      expect(recordOne(makeSoldItem(isDeleted: true)), isEmpty);
    });

    test('value 0 bo\'lsa yozilmaydi', () {
      expect(recordOne(makeSoldItem(value: 0)), isEmpty);
    });

    test('quantity 0 berilsa yozilmaydi', () {
      expect(recordOne(makeSoldItem(value: 3), quantity: 0), isEmpty);
    });

    test('quantity manfiy bo\'lsa yozilmaydi', () {
      expect(recordOne(makeSoldItem(value: 3), quantity: -1), isEmpty);
    });

    test('quantity berilmasa qatorning butun value si olinadi', () {
      expect(recordOne(makeSoldItem(value: 3)).first.quantity, 3);
    });

    test('quantity berilsa qisman yoziladi', () {
      expect(recordOne(makeSoldItem(value: 3), quantity: 1).first.quantity, 1);
    });
  });

  group('deleted_by — xodim IDsi', () {
    test('approvedBy berilsa AYNAN o\'sha xodim yoziladi', () {
      final pinEgasi = Employee(user: EmployeeUser(id: 'pin-xodim'));
      final d = recordOne(makeSoldItem(), approvedBy: pinEgasi).first;
      expect(d.deletedBy, 'pin-xodim');
    });

    test('approvedBy null bo\'lsa joriy xodim callback\'i ishlatiladi', () {
      final d = recordOne(makeSoldItem(), employeeId: 'joriy-kassir').first;
      expect(d.deletedBy, 'joriy-kassir');
    });

    test('approvedBy da user null bo\'lsa joriy xodimga tushadi', () {
      final d = recordOne(makeSoldItem(),
              approvedBy: Employee(), employeeId: 'joriy-kassir')
          .first;
      expect(d.deletedBy, 'joriy-kassir');
    });

    test('callback bo\'sh qaytarsa bo\'sh string yoziladi', () {
      expect(recordOne(makeSoldItem(), employeeId: '').first.deletedBy, '');
    });
  });

  group('totalPrice', () {
    test('narx × miqdor', () {
      expect(recordOne(makeSoldItem(price: 5000, value: 3)).first.totalPrice,
          15000);
    });

    test('qisman o\'chirishda berilgan miqdor ishlatiladi', () {
      expect(
          recordOne(makeSoldItem(price: 5000, value: 3), quantity: 2)
              .first
              .totalPrice,
          10000);
    });

    test('butun songa yaxlitlanadi', () {
      expect(recordOne(makeSoldItem(price: 1500.4)).first.totalPrice, 1500);
    });

    test('kasr miqdor (tarozi) ham yaxlitlanadi', () {
      expect(
          recordOne(makeSoldItem(price: 1499, value: 1.5)).first.totalPrice,
          2249,
          reason: '1499 × 1.5 = 2248.5 → 2249');
    });
  });

  group('added_time', () {
    test('createdTime UTC formatida yoziladi', () {
      final item = makeSoldItem(
          createdTime: DateTime.utc(2026, 8, 25, 9, 8, 7).millisecondsSinceEpoch);
      expect(recordOne(item).first.addedTime, '2026-08-25 09:08:07');
    });

    test('createdTime 0 bo\'lsa bo\'sh string', () {
      expect(recordOne(makeSoldItem(createdTime: 0)).first.addedTime, isEmpty);
    });
  });

  group('flagOrphansIfCartEmpty', () {
    List<DeletedItemModel4> two() => [
          DeletedItemModel4(
              deletedBy: 'a',
              deletedTime: '',
              addedTime: '',
              productId: 'p1',
              quantity: 1,
              totalPrice: 100),
          DeletedItemModel4(
              deletedBy: 'a',
              deletedTime: '',
              addedTime: '',
              productId: 'p2',
              quantity: 1,
              totalPrice: 200),
        ];

    test('savat bo\'sh bo\'lsa hammasiga "-" qo\'yiladi', () {
      final items = two();
      DeletedItemRecorder.flagOrphansIfCartEmpty([], items);
      expect(items.map((e) => e.checkNumber), ['-', '-']);
    });

    test('barcha qatorlar o\'chirilgan bo\'lsa ham "-" qo\'yiladi', () {
      final items = two();
      DeletedItemRecorder.flagOrphansIfCartEmpty(
          [makeSoldItem(isDeleted: true)], items);
      expect(items.first.checkNumber, '-');
    });

    test('bitta aktiv qator qolsa hech biriga tegilmaydi', () {
      final items = two();
      DeletedItemRecorder.flagOrphansIfCartEmpty([makeSoldItem()], items);
      expect(items.every((e) => e.checkNumber.isEmpty), isTrue);
    });

    test('allaqachon chek raqami borga tegilmaydi', () {
      final items = two();
      items.first.checkNumber = 'CHEK-9';
      DeletedItemRecorder.flagOrphansIfCartEmpty([], items);
      expect(items[0].checkNumber, 'CHEK-9');
      expect(items[1].checkNumber, '-');
    });

    test('bo\'sh ro\'yxatda xato bermaydi', () {
      expect(() => DeletedItemRecorder.flagOrphansIfCartEmpty([], []),
          returnsNormally);
    });
  });
}
