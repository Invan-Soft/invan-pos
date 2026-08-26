// Blok (yaqin qadoq) qatori — savatga blok shtrix-kodi skanerlanganda.
//
// `SoldItemBuilder` va `MarkedRowBuilder` dan farqlari biznes qoidasi:
//   - `saleType: 2`, `value: 1` — bitta qator = bitta blok
//   - narx BUTUN BLOK narxi (dona narx × boxValue), tier esa blok ichidagi
//     dona soni bo'yicha tanlanadi
//   - `marking: false` — blok qatori markirovka guruhiga kirmaydi, lekin
//     `mark` da blok KM saqlanadi
//   - nomga " //blok" qo'shiladi (kassir savatda ajratib ko'rsin)
//
// `OrderingProvider4._addBoxProduct` dan ajratildi — tana o'zgarmagan.

import 'package:invan2/changes/domain/marking/mxik_rules.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class BoxRowBuilder {
  const BoxRowBuilder._();

  /// [boxPrice] — butun blok narxi, [boxValue] — blokdagi dona soni,
  /// [boxQuantity] — savatdagi shu mahsulot bloklarining yangi soni,
  /// [rawMark] — skanerlangan blok markirovka kodi.
  static ReceiptModelSoldItem4 build(
    ItemModel freshProduct, {
    required double boxPrice,
    required int boxValue,
    required int boxQuantity,
    required String rawMark,
    required String sellerId,
  }) {
    return ReceiptModelSoldItem4(
      inBox: 0,
      tin: freshProduct.commissionTin ?? '',
      isDeleted: false,
      marking: false,
      mark: MxikRules.isProductMarkable(freshProduct) ? rawMark : null,
      soldBy: freshProduct.categories?.isNotEmpty == true
          ? freshProduct.categories!.first.id ?? ''
          : '',
      cost: freshProduct.shopPrices?.shID?.supplyPrice?.toDouble() ?? 0,
      createdTime: DateTime.now().millisecondsSinceEpoch,
      price: boxPrice,
      realPrice: boxPrice,
      onlyPrice: boxPrice,
      singleDiscount: 0,
      value: 1,
      productId: freshProduct.id ?? '',
      productName: '${freshProduct.name ?? ''} //blok',
      ownerType: int.tryParse(freshProduct.ownerType ?? '1') ?? 1,
      packageCode: freshProduct.packageCode,
      packageName: freshProduct.packageName,
      barcode: freshProduct.barcode?.isNotEmpty == true
          ? freshProduct.barcode!.first
          : '',
      sku: int.tryParse(freshProduct.sku ?? '0') ?? 0,
      vat: boxPrice == 0
          ? 0
          : (boxPrice * (freshProduct.vat?.percentage ?? 12)) /
              (100 + (freshProduct.vat?.percentage ?? 12)),
      mxik: freshProduct.mxikCode ?? '',
      sellerId: sellerId,
      vatName: freshProduct.vat?.name ?? '',
      vatPercent: (freshProduct.vat?.percentage ?? 12).toDouble(),
      discountPercent: 0,
      productType: MxikRules.resolveProductType(freshProduct),
      productPackage: MxikRules.resolveProductPackage(freshProduct),
      saleType: 2,
      boxValue: boxValue,
      boxQuantity: boxQuantity,
    );
  }
}
