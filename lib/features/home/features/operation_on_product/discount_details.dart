/*
    @author Suxrob Sattorov, 2/1/2025, 11:37 AM
*/

import 'package:flutter/material.dart';
import 'package:invan2/changes/models/product_discount_model.dart';

import '../../../../changes/services/api.dart';
import '../../../../utils/utils.dart';
import '../../../features.dart';

class DiscountDetails extends StatelessWidget {
  ReceiptModelSoldItem4 item;

  DiscountDetails({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 1.95),
      margin: EdgeInsets.only(bottom: SizeConfig.v * 3),
      child: Column(
        children: [
          Divider(color: Theme.of(context).dividerColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.chegirmalar,
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                ),
              ),
              SizedBox(
                width: SizeConfig.h * 22,
                height: item.productDiscount.length > 5
                    ? SizeConfig.v * (3.5 * 5)
                    : SizeConfig.v * (3.5 * item.productDiscount.length),
                child: ListView.builder(
                  // shrinkWrap: true,
                  itemCount: item.productDiscount.length,
                  itemBuilder: (context, index) {
                    ProductDiscountModel productDiscountModel =
                        item.productDiscount[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          productDiscountModel.name,
                          style: MyThemes.txtStyle(
                            color: Theme.of(context).canvasColor,
                          ),
                        ),
                        SizedBox(width: SizeConfig.h * 2),
                        Row(
                          children: [
                            Text(
                              productDiscountModel.value.toStringAsFixed(0),
                              style: MyThemes.txtStyle(
                                color: Theme.of(context).canvasColor,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              productDiscountModel.typeId ==
                                      'e908c52f-4c6f-46d8-b765-16e074425cd9'
                                  ? '%'
                                  : loc.chegirma == 'Chegirma'
                                      ? 'so\'m'
                                      : 'сум',
                              style: MyThemes.txtStyle(
                                color: Theme.of(context).canvasColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
