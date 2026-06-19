import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

/// Savatdagi bir vizual qatorni ifodalaydi.
///
/// Markirovkali mahsulotlar uchun har bir dona alohida `ReceiptModelSoldItem4`
/// sifatida saqlanadi (har birining o'z mark kodi bor — fiskal uchun zarur).
/// Lekin UI da ular bitta qator bo'lib, qty = donalar soni qilib ko'rsatiladi.
///
/// Guruhdagi donalar narxi/chegirmasi har xil bo'lishi mumkin (masalan 1+1
/// chegirmada bittasi tekin). Shuning uchun qatorda yig'ma (blended) qiymatlar
/// ko'rsatiladi: [totalPrice] = chegirmali umumiy summa, [totalRealPrice] =
/// chegirmasiz umumiy summa.
///
/// [representative] — qatorni chizish uchun ishlatiladigan asosiy item (nomi,
/// barcode, mxik va h.k. uchun; jonli ref).
/// [totalValue] — guruhdagi barcha donalar value yig'indisi (markirovka uchun = soni).
/// [indices] — manba ro'yxatdagi haqiqiy indekslar (tahrir/o'chirish uchun).
/// [isMarkGroup] — bu qator markirovka guruhimi (1 dan ortiq dona bo'lishi mumkin).
/// [productId] — markirovka guruhi uchun mahsulot id (guruhni topish uchun).
class BasketRow {
  final ReceiptModelSoldItem4 representative;
  final double totalValue;
  final double totalPrice;
  final double totalRealPrice;
  final List<int> indices;
  final bool isMarkGroup;
  final String productId;

  const BasketRow({
    required this.representative,
    required this.totalValue,
    required this.totalPrice,
    required this.totalRealPrice,
    required this.indices,
    required this.isMarkGroup,
    required this.productId,
  });

  /// Yig'ma (blended) dona narxi — chegirmali. (totalPrice / qty)
  double get unitPrice =>
      totalValue > 0 ? totalPrice / totalValue : representative.price;

  /// Yig'ma (blended) dona narxi — chegirmasiz (eski narx).
  double get unitRealPrice =>
      totalValue > 0 ? totalRealPrice / totalValue : representative.realPrice;

  /// Yig'ma chegirma foizi: (1 - chegirmali/chegirmasiz) * 100.
  double get discountPercent => totalRealPrice > 0
      ? (1 - totalPrice / totalRealPrice) * 100
      : 0;
}

/// Savatdagi itemlarni vizual qatorlarga guruhlaydi.
///
/// Qoidalar:
///  - Markirovkali (`marking == true`) va o'chirilmagan (`isDeleted != true`)
///    itemlar bir xil `productId` bo'yicha bitta qatorga yig'iladi.
///  - Boshqa hamma narsa (markirovkasiz mahsulot, yoki o'chirilgan markalar)
///    har biri alohida qator bo'lib qoladi.
///  - Qatorlar tartibi manba ro'yxat tartibida saqlanadi: guruh o'zining birinchi
///    (eng yangi) marki turgan joyda paydo bo'ladi.
List<BasketRow> groupBasketRows(List<ReceiptModelSoldItem4> items) {
  // productId -> rows ro'yxatidagi guruh indeksi (faqat aktiv markalar uchun)
  final groupRowIndex = <String, int>{};
  // Har bir qator uchun yig'iladigan qiymatlar (mutable)
  final values = <double>[];
  final prices = <double>[];
  final realPrices = <double>[];
  final reps = <ReceiptModelSoldItem4>[];
  final indicesList = <List<int>>[];
  final isMark = <bool>[];
  final productIds = <String>[];

  void addRow(ReceiptModelSoldItem4 item, int index, bool markGroup) {
    reps.add(item);
    values.add(item.value);
    prices.add(item.value * item.price);
    realPrices.add(item.value * item.realPrice);
    indicesList.add([index]);
    isMark.add(markGroup);
    productIds.add(item.productId);
  }

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final isActiveMark = item.marking && !(item.isDeleted ?? false);

    if (isActiveMark) {
      final existing = groupRowIndex[item.productId];
      if (existing != null) {
        indicesList[existing].add(i);
        values[existing] += item.value;
        prices[existing] += item.value * item.price;
        realPrices[existing] += item.value * item.realPrice;
      } else {
        groupRowIndex[item.productId] = reps.length;
        addRow(item, i, true);
      }
    } else {
      addRow(item, i, false);
    }
  }

  return [
    for (var r = 0; r < reps.length; r++)
      BasketRow(
        representative: reps[r],
        totalValue: values[r],
        totalPrice: prices[r],
        totalRealPrice: realPrices[r],
        indices: indicesList[r],
        isMarkGroup: isMark[r],
        productId: productIds[r],
      ),
  ];
}
