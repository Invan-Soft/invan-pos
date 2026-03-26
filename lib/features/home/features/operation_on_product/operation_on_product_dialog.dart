import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/home/features/operation_on_product/discount_details.dart';
import 'number_calc.dart';
import 'opd_bottom.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../changes/providers/operation_on_product_provider.dart';
import 'opd_top.dart';
import 'opd_center/opd_center.dart';

class OperationOnProductDialog extends StatelessWidget {
  const OperationOnProductDialog({
    super.key,
    required this.item,
    required this.isClientMinimumPrice,
  });

  final bool isClientMinimumPrice;
  final ReceiptModelSoldItem4 item;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => OperationOnProductProvider(
        item: item,
        isClientMinimumPrice: isClientMinimumPrice,
      ),
      builder: (context, child) {
        double subLength = item.productDiscount.length > 5
            ? 3.5 * 5
            : 3.5 * item.productDiscount.length;
        double length = item.productDiscount.isNotEmpty
            ? SizeConfig.v * (40.18 + subLength)
            : SizeConfig.v * 44.18;
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          content: Row(
            children: [
              Container(
                width: SizeConfig.h * 38.96,
                height: length,
                decoration: BoxDecoration(
                  color: Pref.getBool(PrefKeys.isDarkMode, true)
                      ? Theme.of(context).dialogBackgroundColor
                      : MyThemes.lightGreyColorr,
                  borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OPDTop(),
                    OPDCenter(item: item),
                    item.productDiscount.isNotEmpty
                        ? DiscountDetails(item: item)
                        : const SizedBox(),
                    const OPDBottom(),
                  ],
                ),
              ),
              Container(
                width: SizeConfig.h,
                height: SizeConfig.v * 44.18,
                color: Colors.transparent,
              ),
              NumberCalc(height: length, isKg: item.isKg),
            ],
          ),
        );
      },
    );
  }
}
