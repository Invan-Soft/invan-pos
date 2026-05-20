import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invan2/utils/utils.dart';

import '../../../changes/providers/ordering_provider_4.dart';


class ReceiptList extends StatelessWidget {
  const ReceiptList({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentPageProvider = Provider.of<OrderingProvider4>(context);
    final orderedProducts =
        paymentPageProvider.getSixClientModel4.orderedProducts;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orderedProducts.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final item = orderedProducts[index];

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
            '${item.value % 1 == 0 ? item.value.toStringAsFixed(0) : item.value.toString()} * ${(item.price).toStringAsFixed(2)}',
            style: MyThemes.txtStyle(
              fontSize: 2.1,
              fontWeight: FontWeight.normal,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Text(
            (item.value * item.price).toStringAsFixed(2),
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
