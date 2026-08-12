import 'package:flutter/material.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/home/features/home_orders/order_list/order_list_top.dart';
import 'package:invan2/features/home/features/home_orders/order_list/text_widget.dart';
import 'package:invan2/utils/utils.dart';
import 'basket_grouping.dart';

class OrderListItem extends StatelessWidget {
  const OrderListItem(
      {super.key,
      required this.index,
      required this.isLastAdded,
      required this.orderedProduct,
      required this.onPressed,
      required this.selected,
      this.group,
      re});
  final int index;
  final bool selected;
  final bool isLastAdded;
  final ReceiptModelSoldItem4 orderedProduct;
  final VoidCallback onPressed;

  /// Markirovka guruhi bo'lsa, yig'ma (blended) qty/narx/chegirma/summa shu
  /// orqali ko'rsatiladi. `null` bo'lsa oddiy item maydonlari ishlatiladi.
  final BasketRow? group;

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
    if (!OfdAdminSetting.isEnabled) return false;
    if (MarkingSettingHelper.isAutoDetectEnabled &&
        _isAlcoholMxik(orderedProduct.mxik.trim())) {
      return true;
    }
    if (!CashsaleSettingHelper.isEnabled) return false;
    final product = ItemsSingleton.getProductById(orderedProduct.productId);
    return (product?.cashsale ?? 1) == 0;
  }

  // Shartli taqiq: cashsale==1 va umumiy narx 25mln dan oshgan
  bool _isBigTotalRestricted() {
    if (!CashsaleSettingHelper.isEnabled) return false;
    final product = ItemsSingleton.getProductById(orderedProduct.productId);
    if (product == null) return false;
    if ((product.cashsale ?? -1) != 1) return false;
    return (orderedProduct.price * orderedProduct.value) > 25000000;
  }

  @override
  Widget build(BuildContext context) {
    // Markirovka guruhi bo'lsa yig'ma (blended) qiymatlar, aks holda item maydonlari.
    final num displayValue = group?.totalValue ?? orderedProduct.value;
    final double unitPrice = group?.unitPrice ?? orderedProduct.price;
    final double unitRealPrice = group?.unitRealPrice ?? orderedProduct.realPrice;
    final double discPercent = group != null
        ? group!.discountPercent
        : (orderedProduct.discountPercent ?? 0);
    final double lineTotal = group?.totalPrice ?? (orderedProduct.price * orderedProduct.value);
    final double lineRealTotal =
        group?.totalRealPrice ?? (orderedProduct.realPrice * orderedProduct.value);
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
                    price: MoneyFormatter.formatter.format(unitPrice),
                    isDeleted: orderedProduct.isDeleted!,
                    oldPrice: MoneyFormatter.formatter.format(unitRealPrice),
                    discountPercent: discPercent > 0 ? discPercent : 0,
                  ),
                  _verticalDivider(),
                  SoldItemWidget(
                    flex: Flexes.number,
                    title: displayValue % 1 == 0
                        ? displayValue.toStringAsFixed(0)
                        : displayValue.toString(),
                    isDeleted: orderedProduct.isDeleted!,
                  ),
                  _verticalDivider(),
                  SoldItemWidget(
                    flex: Flexes.discount,
                    title: discPercent > 0 ? discPercent.toStringAsFixed(1) : '',
                    isDeleted: orderedProduct.isDeleted!,
                  ),
                  _verticalDivider(),
                  SoldItemWidgetWithDiscount(
                    flex: Flexes.price,
                    price: MoneyFormatter.formatter.format(lineTotal),
                    isDeleted: orderedProduct.isDeleted!,
                    oldPrice: MoneyFormatter.formatter.format(lineRealTotal),
                    discountPercent: discPercent > 0 ? discPercent : 0,
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
