// Mijoz kartasidagi foizli chegirma.
//
// Foiz savatning HAR qatoriga qo'llanadi: narx tushadi, chekka "sum"
// turidagi chegirma qatori yoziladi. `discountPercent` esa KATALOG narxiga
// nisbatan hisoblanadi — shuning uchun qator allaqachon arzonlashtirilgan
// bo'lsa, chekdagi foiz mijoz kartasidagidan katta chiqadi.
//
// `OrderingProvider4.setNewClientDiscountPercentage` dan ajratildi —
// hisob-kitob o'zgarmagan.

import 'package:invan2/changes/models/discount_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class ClientDiscount {
  const ClientDiscount._();

  /// [makeDiscount] — chekka yoziladigan chegirma qatorini yasaydi
  /// (`DiscountFromWhere` provider tomonda qoladi).
  static void applyPercentage(
    List<ReceiptModelSoldItem4> rows,
    double percentage, {
    required DiscountModel Function(num howMuch) makeDiscount,
  }) {
    double newPRICE = 0;
    for (int i = 0; i < rows.length; i++) {
      num basePrice =
          ItemsSingleton.getItemBasePrice(rows[i], false, allRows: rows);
      num onlyBasePrice = rows[i].price;
      newPRICE = (onlyBasePrice / 100) * (100 - percentage);

      // QAYD: o'chirish paytida indeks surilmaydi — ketma-ket ikkita "sum"
      // bo'lsa ikkinchisi o'tkazib yuboriladi. Asl xatti-harakat
      // (`test/client_discount_test.dart` da muzlatilgan).
      for (int n = 0; n < rows[i].discount.length; n++) {
        if (rows[i].discount[n].type == "sum") {
          rows[i].discount.removeAt(n);
        }
      }

      rows[i].discount.add(makeDiscount(basePrice - newPRICE));
      rows[i].price = newPRICE;
      rows[i].discountPercent = (100 - (newPRICE * 100 / basePrice));
      rows[i].isPriceChanged = true;
    }
  }
}
