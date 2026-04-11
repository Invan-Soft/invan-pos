import 'package:flutter/material.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/home/features/home_orders/order_list/order_list_top.dart';
import 'package:invan2/features/home/features/home_orders/order_list/text_widget.dart';
import 'package:invan2/utils/utils.dart';

class OrderListItem extends StatelessWidget {
  const OrderListItem(
      {super.key,
      required this.index,
      required this.isLastAdded,
      required this.orderedProduct,
      required this.onPressed,
      required this.selected,
      re});
  final int index;
  final bool selected;
  final bool isLastAdded;
  final ReceiptModelSoldItem4 orderedProduct;
  final VoidCallback onPressed;

  bool _isAlcoholMxik(String mxik) =>
      mxik.startsWith('02203') ||
      mxik.startsWith('02204') ||
      mxik.startsWith('02205') ||
      mxik.startsWith('02206') ||
      mxik.startsWith('02207') ||
      mxik.startsWith('02208') ||
      mxik.startsWith('024');

  // Qat'iy taqiq: alkogol mxik yoki cashsale==0
  bool _isHardRestricted() {
    if (Pref.getBool(PrefKeys.sellProductsWithMarking, true) &&
        _isAlcoholMxik(orderedProduct.mxik.trim())) {
      return true;
    }
    if (!Pref.getBool('checkProductByCashsale', true)) return false;
    final product = ItemsSingleton.getProductById(orderedProduct.productId);
    return (product?.cashsale ?? 1) == 0;
  }

  // Shartli taqiq: cashsale==1 va umumiy narx 25mln dan oshgan
  bool _isBigTotalRestricted() {
    if (!Pref.getBool('checkProductByCashsale', true)) return false;
    final product = ItemsSingleton.getProductById(orderedProduct.productId);
    if (product == null) return false;
    if ((product.cashsale ?? -1) != 1) return false;
    return (orderedProduct.price * orderedProduct.value) > 25000000;
  }

  @override
  Widget build(BuildContext context) {
    final bool hardRestricted = _isHardRestricted();
    final bool bigTotalRestricted = !hardRestricted && _isBigTotalRestricted();

    // Rang tanlash
    Color? bgColor;
    if (selected) {
      bgColor = Theme.of(context).primaryColor.withValues(alpha: .3);
    } else if (orderedProduct.isDeleted!) {
      bgColor = Colors.red;
    } else if (orderedProduct.mxikError ?? false) {
      bgColor = Colors.orangeAccent.withValues(alpha: .5);
    } else if (hardRestricted) {
      bgColor = Colors.amber.withValues(alpha: .12);
    } else if (bigTotalRestricted) {
      bgColor = const Color(0xFF1565C0).withValues(alpha: .18); // ko'k
    } else {
      bgColor = Theme.of(context).colorScheme.surface;
    }

    // Chap border rangi
    Color? borderColor;
    if (!orderedProduct.isDeleted!) {
      if (hardRestricted) borderColor = Colors.amber;
      if (bigTotalRestricted) borderColor = const Color(0xFF42A5F5); // light blue
    }

    return SizedBox(
      child: Stack(
        children: [
          MaterialButton(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: onPressed,
            color: bgColor,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.v),
              child: Row(
                children: [
                  SoldItemWidget(
                    flex: Flexes.order,
                    title: index.toString(),
                    isDeleted: orderedProduct.isDeleted!,
                  ),
                  _verticalDivider(),
                  Expanded(
                    flex: Flexes.name,
                    child: Padding(
                      padding: EdgeInsets.only(left: SizeConfig.h * 0.61),
                      child: SizedBox(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderedProduct.productName,
                              textAlign: TextAlign.start,
                              style: MyThemes.txtStyle(
                                color: Theme.of(context).canvasColor,
                                textDecoration: orderedProduct.isDeleted!
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                fontWeight: FontWeight.w500,
                                fontStyle: orderedProduct.isDeleted!
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                fontSize: 2.6,
                              ),
                            ),
                            SizedBox(height: SizeConfig.v * .5),
                            Text(
                              orderedProduct.barcode.isNotEmpty
                                  ? 'Barcode/SKU: ${orderedProduct.barcode}/${orderedProduct.sku}'
                                  : '',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).dividerColor,
                                fontWeight: FontWeight.w300,
                                fontSize: SizeConfig.v * 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _verticalDivider(),
                  SoldItemWidgetWithDiscount(
                    flex: Flexes.price,
                    price: MoneyFormatter.formatter.format(orderedProduct.price),
                    isDeleted: orderedProduct.isDeleted!,
                    oldPrice: MoneyFormatter.formatter
                        .format(orderedProduct.realPrice),
                    discountPercent: orderedProduct.discountPercent != null &&
                            orderedProduct.discountPercent! > 0
                        ? orderedProduct.discountPercent!
                        : 0,
                  ),
                  _verticalDivider(),
                  SoldItemWidget(
                    flex: Flexes.number,
                    title: orderedProduct.value % 1 == 0
                        ? orderedProduct.value.toStringAsFixed(0)
                        : orderedProduct.value.toString(),
                    isDeleted: orderedProduct.isDeleted!,
                  ),
                  _verticalDivider(),
                  SoldItemWidget(
                    flex: Flexes.discount,
                    title: orderedProduct.discountPercent != null &&
                            orderedProduct.discountPercent! > 0
                        ? orderedProduct.discountPercent!.toStringAsFixed(1)
                        : '',
                    isDeleted: orderedProduct.isDeleted!,
                  ),
                  _verticalDivider(),
                  SoldItemWidgetWithDiscount(
                    flex: Flexes.price,
                    price: MoneyFormatter.formatter
                        .format(orderedProduct.value * orderedProduct.price),
                    isDeleted: orderedProduct.isDeleted!,
                    oldPrice: MoneyFormatter.formatter
                        .format(orderedProduct.realPrice * orderedProduct.value),
                    discountPercent: orderedProduct.discountPercent != null &&
                            orderedProduct.discountPercent! > 0
                        ? orderedProduct.discountPercent!
                        : 0,
                  ),
                ],
              ),
            ),
          ),
          if (borderColor != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: borderColor),
            ),
        ],
      ),
    );
  }

  _verticalDivider() => const VerticalDivider(
        thickness: 2,
        width: 3,
        color: Colors.transparent,
      );
}
