// Markirovkali (KM skanerlangan) mahsulot uchun savat qatori.
//
// `SoldItemBuilder.build` dan farqi ATAYLAB saqlangan:
//   - har skan ALOHIDA qator (miqdor har doim 1), chunki har donaning
//     o'z markirovka kodi bor
//   - `soldBy` da o'lchov birligi ketadi (oddiy qatorda kategoriya IDsi)
//   - `mark` — skanerlangan KM (mahsulot markirovkali bo'lsa)
//   - `packageName` mahsulot qadoq turidan
// Ikkisini bitta funksiyaga birlashtirish xato manbai bo'lardi.
//
// `OrderingProvider4.addSeperatedProduct` dan ajratildi (Faza 9.5) —
// tana o'zgarmagan.

import 'package:invan2/changes/domain/marking/mxik_rules.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class MarkedRowBuilder {
  const MarkedRowBuilder._();

  /// [markValue] — skanerlangan markirovka kodi (tozalangan holda).
  /// [sellerId] — joriy kassir IDsi.
  static ReceiptModelSoldItem4 build(
    ItemModel freshProduct,
    double price, {
    required String? markValue,
    required String sellerId,
  }) {
    return ReceiptModelSoldItem4(
      isDeleted: false,
      inBox: 0,
      tin: freshProduct.commissionTin,
      marking: MxikRules.isProductMarkable(freshProduct),
      mark: MxikRules.isProductMarkable(freshProduct) ? markValue : null,
      soldBy: freshProduct.measurementUnit?.shortName ?? "",
      cost: 0,
      createdTime: DateTime.now().millisecondsSinceEpoch,
      price: price,
      realPrice: price,
      onlyPrice: price,
      singleDiscount: 0,
      value: 1,
      productId: freshProduct.id!,
      productName: freshProduct.name!,
      ownerType:
          (freshProduct.ownerType != null && freshProduct.ownerType!.isNotEmpty)
              ? int.parse(freshProduct.ownerType!)
              : 1,
      packageCode: freshProduct.packageCode,
      packageName: freshProduct.packageType,
      barcode:
          freshProduct.barcode!.isNotEmpty ? freshProduct.barcode!.first : "",
      sku: int.parse(freshProduct.sku ?? "0"),
      vat: price == 0
          ? 0
          : (price * (freshProduct.vat!.percentage ?? 12)) /
              (100 + (freshProduct.vat!.percentage ?? 12)),
      mxik: freshProduct.mxikCode!,
      vatPercent: (freshProduct.vat!.percentage ?? 12).toDouble(),
      sellerId: sellerId,
      vatName: freshProduct.vat?.name ?? "",
      discountPercent: 0,
      productType: MxikRules.resolveProductType(freshProduct),
      productPackage: MxikRules.resolveProductPackage(freshProduct),
    );
  }
}
