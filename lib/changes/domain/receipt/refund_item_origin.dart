// Vozvrat qatorining fiskal "egalik" maydonlari: OwnerType va komitent STIR.
//
// Nega kerak: vozvrat qatorlari serverdan (`api/v1/order`) keladi va u yerda
// `owner_type` ham, `commission_tin` ham YO'Q. `ChecksSingleton` ilgari
// `ownerType: 0`, `tin: ""` deb qo'yardi — natijada soliqqa sotuvda
// `OwnerType: 1` ketgan tovar vozvratda `OwnerType: 0` bilan ketardi
// (soliq sahifasida "Komitent STIR/JSHSHIR: 0", 2026-09-23).
//
// Yechim: sotuvdagi bilan BIR XIL manba — katalogdagi mahsulot
// (`SoldItemBuilder.build` qanday olsa, shunday). Mahsulot katalogda
// topilmasa (o'chirilgan, eski chek) — spec bo'yicha oddiy tovar: `1`, STIR "".
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

class RefundItemOrigin {
  /// Fiskal `OwnerType`. Oddiy tovar — `1` (docs/fiscal-sale-integration.md).
  final int ownerType;

  /// Komitent STIR (9 xona) yoki JSHSHIR (14 xona); bo'lmasa "".
  final String tin;

  const RefundItemOrigin({required this.ownerType, required this.tin});

  static const RefundItemOrigin fallback =
      RefundItemOrigin(ownerType: 1, tin: '');

  /// Sotuv yo'li (`SoldItemBuilder.build`) bilan aynan bir xil qoida.
  static RefundItemOrigin resolve(ItemModel? product) {
    if (product == null) return fallback;
    return RefundItemOrigin(
      ownerType: int.tryParse(product.ownerType ?? '1') ?? 1,
      tin: product.commissionTin ?? '',
    );
  }

  /// Katalogdan qidiradi. Bu vozvrat (to'lov) yo'li — hech qachon exception
  /// tashlamaydi: katalogda `id == null` mahsulot bo'lsa ham [fallback].
  static RefundItemOrigin fromCatalog(String? productId) {
    if (productId == null || productId.isEmpty) return fallback;
    try {
      return resolve(ItemsSingleton.getProductById(productId));
    } catch (_) {
      return fallback;
    }
  }
}
