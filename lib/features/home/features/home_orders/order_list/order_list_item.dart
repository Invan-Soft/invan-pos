import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: MaterialButton(
        focusNode: FocusNode(skipTraversal: true),
        onPressed: onPressed,
        color: selected
            ? Theme.of(context).primaryColor.withOpacity(.3)
            : orderedProduct.isDeleted!
                ? Colors.red
                : (orderedProduct.mxikError ?? false)
                    ? Colors.orangeAccent.withOpacity(.5)
                    : Theme.of(context).colorScheme.background,
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
                        SizedBox(
                          height: SizeConfig.v * .5,
                        ),
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
              // SoldItemWidgetWithDiscount(
              //   flex: Flexes.price,
              //   price: MoneyFormatter.formatter.format(orderedProduct.price),
              //   isDeleted: orderedProduct.isDeleted!,
              //   oldPrice:
              //       MoneyFormatter.formatter.format(orderedProduct.onlyPrice),
              //   discountPercent: orderedProduct.discountPercent != null &&
              //           orderedProduct.discountPercent! > 0
              //       ? orderedProduct.discountPercent!
              //       : 0,
              // ),
              SoldItemWidgetWithDiscount(
                flex: Flexes.price,
                price: MoneyFormatter.formatter.format(orderedProduct.price),
                isDeleted: orderedProduct.isDeleted!,
                oldPrice:
                MoneyFormatter.formatter.format(orderedProduct.realPrice),
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
                oldPrice: MoneyFormatter.formatter.format(
                    orderedProduct.realPrice * orderedProduct.value
                    // ((orderedProduct.vat * (100 + orderedProduct.vatPercent)) /
                    //         orderedProduct.vatPercent) *
                    //     orderedProduct.value,
                    ),
                discountPercent: orderedProduct.discountPercent != null &&
                        orderedProduct.discountPercent! > 0
                    ? orderedProduct.discountPercent!
                    : 0,
              ),

              // SoldItemWidget(
              //   flex: Flexes.summ,
              //   textAlign: TextAlign.end,
              //   title: MoneyFormatter.formatter
              //       .format(orderedProduct.value * orderedProduct.price),
              //   isDeleted: orderedProduct.isDeleted!,
              // )
            ],
          ),
        ),
      ),
    );
  }

  _verticalDivider() => const VerticalDivider(
        thickness: 2,
        width: 3,
        color: Colors.transparent,
      );
}
