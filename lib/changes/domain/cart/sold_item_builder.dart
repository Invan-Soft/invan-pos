// Savat qatori (sotilgan mahsulot) yasovchi.
//
// OrderingProvider4._createSoldItem dan ajratildi (2026-08-06) —
// tana o'zgartirilmadi, faqat MXIK qoidalari `MxikRules` ga to'g'ridan-to'g'ri
// murojaat qiladi (ilgari provider delegatsiyalari orqali borardi).
//
// Sof funksiya: holat, dialog, Hive yo'q. `MxikRules` esa Pref sozlamalarini
// o'qiydi (markirovka yoqilganmi va h.k.).
//
// Testlar: test/sold_item_builder_test.dart

import 'package:invan2/changes/domain/marking/mxik_rules.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class SoldItemBuilder {
  const SoldItemBuilder._();

  static ReceiptModelSoldItem4 build(
      ItemModel product, double price, double value, bool isKg) {
    return ReceiptModelSoldItem4(
      inBox: 0,
      tin: product.commissionTin ?? '',
      isDeleted: false,
      // Qo'shish yo'lidagi qaror bilan bir xil bo'lishi shart: OFD o'chiq bo'lsa
      // qator markirovka guruhi bo'lib qolmasligi kerak (aks holda savatda qty
      // tahriri bloklanadi).
      marking: MxikRules.isProductMarkable(product),
      soldBy: product.categories?.isNotEmpty == true
          ? product.categories![0].id ?? ''
          : '',
      cost: product.shopPrices?.shID?.supplyPrice?.toDouble() ?? 0,
      createdTime: DateTime.now().millisecondsSinceEpoch,
      price: price,
      realPrice: price,
      singleDiscount: 0,
      value: value,
      ownerType: int.tryParse(product.ownerType ?? '1') ?? 1,
      onlyPrice: price,
      productId: product.id ?? '',
      productName: product.name ?? '',
      packageCode: product.packageCode ?? '',
      packageName: product.packageName ?? '',
      barcode:
          product.barcode?.isNotEmpty == true ? product.barcode!.first : '',
      sku: int.tryParse(product.sku ?? '0') ?? 0,
      vat: price == 0
          ? 0
          : (price * (product.vat?.percentage ?? 12)) /
              (100 + (product.vat?.percentage ?? 12)),
      mxik: product.mxikCode ?? '',
      sellerId: Pref.getString(PrefKeys.cashierId, ''),
      vatName: product.vat?.name ?? '',
      discountPercent: 0,
      vatPercent: (product.vat?.percentage ?? 12).toDouble(),
      isKg: isKg,
      productType: MxikRules.resolveProductType(product),
      productPackage: MxikRules.resolveProductPackage(product),
    );
  }
}
