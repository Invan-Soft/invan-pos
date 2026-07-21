import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invan2/utils/utils.dart';

import '../../../changes/providers/ordering_provider_4.dart';
import '../../home/features/home_orders/order_list/basket_grouping.dart';


class ReceiptList extends StatelessWidget {
  const ReceiptList({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentPageProvider = Provider.of<OrderingProvider4>(context);
    final orderedProducts =
        paymentPageProvider.getSixClientModel4.orderedProducts;
    // Markirovkali va blok itemlar 1 qatorga guruhlanadi (savatdagi kabi).
    final rows = groupBasketRows(orderedProducts);

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final row = rows[index];
        final item = row.representative;
        // Guruh (marka yoki blok) bo'lsa yig'ma (blended) qiymatlar, aks holda
        // item maydonlari. Blok guruhida displayValue = blok soni, unitPrice =
        // blok narxi.
        final isGroup = row.isMarkGroup || row.isBoxGroup;
        final displayValue = isGroup ? row.totalValue : item.value;
        final unitPrice = isGroup ? row.unitPrice : item.price;
        final lineTotal =
            isGroup ? row.totalPrice : (displayValue * item.price);

        return ListTile(
          contentPadding: EdgeInsets.only(
            left: SizeConfig.h * 2,
            right: SizeConfig.h,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  item.productName,
                  style: MyThemes.txtStyle(
                    fontSize: 2.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: SizeConfig.h),
              Flexible(
                child: Text(
                  '(${item.productName})',
                  style: MyThemes.txtStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 2.1,
                    fontWeight: FontWeight.normal,
                    color: Colors.blueGrey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${displayValue % 1 == 0 ? displayValue.toStringAsFixed(0) : displayValue.toString()} * ${unitPrice.toStringAsFixed(2)}',
            style: MyThemes.txtStyle(
              fontSize: 2.1,
              fontWeight: FontWeight.normal,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Text(
            lineTotal.toStringAsFixed(2),
            style: MyThemes.txtStyle(
              fontSize: 2.1,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
        );
      },
    );
  }
}
