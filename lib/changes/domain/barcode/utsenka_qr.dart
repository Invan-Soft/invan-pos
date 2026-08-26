// Utsenka (chegirmali tovar) QR kodi.
//
// Do'kon muddati yaqinlashgan tovarga QR chop etadi: `{"sku":206,"price":8000}`.
// Skanerlanganda mahsulot savatga chegirmali narxda tushadi va chekda
// chegirma miqdori ko'rinadi (asl narx `realPrice` da qoladi).
//
// `OrderingProvider4._parseUtsenkaQr` dan ajratildi — tana o'zgarmagan.
// Savat qatorini yasash providerda qoladi (`SoldItemBuilder`), bu modul
// faqat KODNI o'qiydi va chegirmani hisoblaydi.

import 'dart:convert';

import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

/// QR dan o'qilgan chegirma ma'lumoti.
class UtsenkaOffer {
  const UtsenkaOffer({
    required this.product,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.percent,
  });

  final ItemModel product;

  /// QR da ko'rsatilgan chegirmali narx.
  final double price;

  /// Katalogdagi asl (1 donalik) narx.
  final double originalPrice;

  /// Asl narx bilan farq (manfiy bo'lmaydi).
  final double discount;

  /// Chegirma foizi.
  final double percent;
}

class UtsenkaQr {
  const UtsenkaQr._();

  /// QR matnini o'qiydi. Format noto'g'ri, SKU katalogda yo'q yoki narx
  /// musbat bo'lmasa `null` qaytaradi (chaqiruvchi "format noto'g'ri"
  /// dialogini ko'rsatadi).
  static UtsenkaOffer? parse(String barcode) {
    try {
      final decoded = jsonDecode(barcode);
      if (decoded is! Map) return null;
      final skuRaw = decoded['sku'];
      final priceRaw = decoded['price'];
      if (skuRaw == null || priceRaw == null) return null;

      final skuInt = int.tryParse(skuRaw.toString());
      if (skuInt == null) return null;
      final utsenkaPrice = (priceRaw as num).toDouble();
      if (utsenkaPrice <= 0) return null;

      final product = ItemsSingleton.getProductBySku(skuInt);
      if (product == null) return null;

      final originalPrice =
          ItemsSingleton.finalPrice(product, 1, false).toDouble();
      final discount =
          (originalPrice - utsenkaPrice).clamp(0.0, double.infinity);
      final percent =
          originalPrice > 0 ? (discount / originalPrice) * 100 : 0.0;

      return UtsenkaOffer(
        product: product,
        price: utsenkaPrice,
        originalPrice: originalPrice,
        discount: discount,
        percent: percent.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
