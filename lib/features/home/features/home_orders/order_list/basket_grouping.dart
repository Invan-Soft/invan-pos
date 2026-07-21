import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

/// Savatdagi bir vizual qatorni ifodalaydi.
///
/// Markirovkali mahsulotlar uchun har bir dona alohida `ReceiptModelSoldItem4`
/// sifatida saqlanadi (har birining o'z mark kodi bor — fiskal uchun zarur).
/// Blok sotuv (`saleType==2`) uchun ham har bir blok alohida item bo'lib
/// saqlanadi (har biri value=1, narxi = blok narxi). Lekin UI da ular bitta
/// qator bo'lib, qty = donalar/bloklar soni qilib ko'rsatiladi.
///
/// Guruhdagi donalar narxi/chegirmasi har xil bo'lishi mumkin (masalan 1+1
/// chegirmada bittasi tekin). Shuning uchun qatorda yig'ma (blended) qiymatlar
/// ko'rsatiladi: [totalPrice] = chegirmali umumiy summa, [totalRealPrice] =
/// chegirmasiz umumiy summa.
///
/// [representative] — qatorni chizish uchun ishlatiladigan asosiy item (nomi,
/// barcode, mxik va h.k. uchun; jonli ref).
/// [totalValue] — guruhdagi barcha itemlar value yig'indisi (markirovkada = dona
/// soni; blokda = blok soni, chunki har blok value=1).
/// [indices] — manba ro'yxatdagi haqiqiy indekslar (tahrir/o'chirish uchun).
/// [isMarkGroup] — bu qator markirovka guruhimi (1 dan ortiq dona bo'lishi mumkin).
/// [isBoxGroup] — bu qator blok guruhimi (bir xil mahsulotning bloklari).
/// [boxValue] — blok guruhi uchun 1 blokdagi dona soni (aks holda 0).
/// [productId] — guruhni topish uchun mahsulot id.
class BasketRow {
  final ReceiptModelSoldItem4 representative;
  final double totalValue;
  final double totalPrice;
  final double totalRealPrice;
  final List<int> indices;
  final bool isMarkGroup;
  final bool isBoxGroup;
  final int boxValue;
  final String productId;

  const BasketRow({
    required this.representative,
    required this.totalValue,
    required this.totalPrice,
    required this.totalRealPrice,
    required this.indices,
    required this.isMarkGroup,
    required this.productId,
    this.isBoxGroup = false,
    this.boxValue = 0,
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

  /// Blok guruhi uchun umumiy dona soni (blok soni × 1 blokdagi dona).
  double get totalUnits => isBoxGroup ? totalValue * boxValue : totalValue;
}

/// Savatdagi itemlarni vizual qatorlarga guruhlaydi.
///
/// Qoidalar:
///  - Blok sotuv (`saleType==2`) va o'chirilmagan (`isDeleted != true`) itemlar
///    bir xil `productId` bo'yicha bitta "blok guruhi"ga yig'iladi.
///  - Markirovkali (`marking == true`, blok emas) va o'chirilmagan itemlar bir
///    xil `productId` bo'yicha bitta "marka guruhi"ga yig'iladi.
///  - Blok va marka guruhlari ALOHIDA: bitta mahsulot ham dona-marka, ham blok
///    bo'lib sotilsa ikki xil qator bo'ladi.
///  - Boshqa hamma narsa (oddiy mahsulot, yoki o'chirilgan qatorlar) har biri
///    alohida qator bo'lib qoladi.
///  - Qatorlar tartibi manba ro'yxat tartibida saqlanadi: guruh o'zining birinchi
///    (eng yangi) elementi turgan joyda paydo bo'ladi.
List<BasketRow> groupBasketRows(List<ReceiptModelSoldItem4> items) {
  // productId -> rows ro'yxatidagi guruh indeksi (marka va blok uchun alohida)
  final markGroupRowIndex = <String, int>{};
  final boxGroupRowIndex = <String, int>{};
  // Har bir qator uchun yig'iladigan qiymatlar (mutable)
  final values = <double>[];
  final prices = <double>[];
  final realPrices = <double>[];
  final reps = <ReceiptModelSoldItem4>[];
  final indicesList = <List<int>>[];
  final isMark = <bool>[];
  final isBox = <bool>[];
  final boxValues = <int>[];
  final productIds = <String>[];

  void addRow(ReceiptModelSoldItem4 item, int index,
      {required bool markGroup, required bool boxGroup}) {
    reps.add(item);
    values.add(item.value);
    prices.add(item.value * item.price);
    realPrices.add(item.value * item.realPrice);
    indicesList.add([index]);
    isMark.add(markGroup);
    isBox.add(boxGroup);
    boxValues.add(boxGroup ? item.boxValue : 0);
    productIds.add(item.productId);
  }

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final isActive = !(item.isDeleted ?? false);
    final isActiveBox = isActive && item.saleType == 2;
    final isActiveMark = isActive && item.marking && item.saleType != 2;

    if (isActiveBox) {
      final existing = boxGroupRowIndex[item.productId];
      if (existing != null) {
        indicesList[existing].add(i);
        values[existing] += item.value;
        prices[existing] += item.value * item.price;
        realPrices[existing] += item.value * item.realPrice;
      } else {
        boxGroupRowIndex[item.productId] = reps.length;
        addRow(item, i, markGroup: false, boxGroup: true);
      }
    } else if (isActiveMark) {
      final existing = markGroupRowIndex[item.productId];
      if (existing != null) {
        indicesList[existing].add(i);
        values[existing] += item.value;
        prices[existing] += item.value * item.price;
        realPrices[existing] += item.value * item.realPrice;
      } else {
        markGroupRowIndex[item.productId] = reps.length;
        addRow(item, i, markGroup: true, boxGroup: false);
      }
    } else {
      addRow(item, i, markGroup: false, boxGroup: false);
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
        isBoxGroup: isBox[r],
        boxValue: boxValues[r],
        productId: productIds[r],
      ),
  ];
}
