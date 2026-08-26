// Invoice (yuk xati) qatoridan savat qatori yasash.
//
// Oddiy sotuvdan farqi: nom, miqdor va tannarx INVOICE dan keladi, narx esa
// invoice tiers idan (eng katta minQuantity ustun); invoice narx bermasa
// katalogning 1 donalik narxiga tushadi.
//
// `OrderingProvider4.loadInvoiceByBarcodeWithBloc` dan ajratildi
// (Faza 9.5) — tana o'zgarmagan. `SoldItemBuilder.build` bilan ATAYLAB
// birlashtirilmadi: maydon manbalari boshqa (invoice vs katalog), ikkisini
// bitta funksiyaga tiqish xato manbai bo'lardi.

import 'package:invan2/changes/domain/cart/row_repricer.dart';
import 'package:invan2/changes/domain/marking/mxik_rules.dart';
import 'package:invan2/changes/models/invoice_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class InvoiceRowBuilder {
  const InvoiceRowBuilder._();

  /// [item] — invoice qatori, [product] — katalogdagi mahsulot.
  static ReceiptModelSoldItem4 build(InvoiceItem item, ItemModel product) {
    double selectedPrice = 0;
    if (item.prices.isNotEmpty) {
      item.prices
          .sort((a, b) => b.minQuantity.compareTo(a.minQuantity));
      selectedPrice = item.prices.first.price;
    }
    if (selectedPrice <= 0) {
      final isKg = product.measurementUnit?.shortName == 'кг' ||
          product.measurementUnit?.shortName == 'kg';
      selectedPrice =
          ItemsSingleton.finalPrice(product, 1, isKg).toDouble();
    }

    return ReceiptModelSoldItem4(
      productId: product.id ?? '',
      productName: item.productName,
      barcode: product.barcode?.isNotEmpty == true
          ? product.barcode!.first
          : '',
      sku: int.tryParse(product.sku ?? '0') ?? 0,
      value: item.expectedAmount.toDouble(),
      price: selectedPrice,
      realPrice: selectedPrice,
      onlyPrice: selectedPrice,
      isKg: RowRepricer.isKg(product),
      isDeleted: false,
      discountPercent: 0,
      singleDiscount: 0,
      vatPercent: product.vat?.percentage?.toDouble() ?? 12,
      mxik: product.mxikCode ?? '',
      packageCode: product.packageCode ?? '',
      marking: MxikRules.isProductMarkable(product),
      createdTime: DateTime.now().millisecondsSinceEpoch,
      cost: item.cost,
      ownerType: product.ownerType != null
          ? int.tryParse(product.ownerType!) ?? 1
          : 1,
      tin: product.commissionTin ?? '',
      soldBy: product.categories?.isNotEmpty == true
          ? product.categories!.first.id ?? ''
          : '',
      inBox: 0,
      vat: product.vat?.percentage?.toDouble() ?? 0,
      vatName: product.vat?.name ?? "",
      sellerId: "",
    );
  }
}
