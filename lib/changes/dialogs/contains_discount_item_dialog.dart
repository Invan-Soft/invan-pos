import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';

import '../../features/get_products/singletons/items_singleton.dart';
import '../models/product/item_model.dart';
import '../singletons/discounts/discount_singleton.dart';

class ContainsDiscountItemDialog extends StatefulWidget {
  final OrderingProvider4 provider;
  ReturnedProduct returnedProduct;
  bool isFirst = false;

  ContainsDiscountItemDialog({
    super.key,
    required this.provider,
    required this.returnedProduct,
    this.isFirst = false,
  });

  @override
  State<ContainsDiscountItemDialog> createState() =>
      _ContainsDiscountItemDialogState();
}

class _ContainsDiscountItemDialogState
    extends State<ContainsDiscountItemDialog> {
  final TextEditingController controller = TextEditingController();
  bool isWaiting = false;
  bool isOkButtonPressed = false;
  ItemModel? item;

  @override
  void initState() {
    item = ItemsSingleton.getProductById(
        widget.returnedProduct.returnedProductId ?? '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 2.2,
        height: MediaQuery.of(context).size.height / 1.4,
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.green.shade500, blurRadius: 100)],
          color: MyThemes.darkBackgroundColor,
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.returnedProduct.discountName ?? '',
                      textAlign: TextAlign.center,
                      style: MyThemes.txtStyle(
                        color: MyThemes.textWhiteColor,
                        fontSize: 4.5,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Listdagi matnlarni qo‘shish
                        if (widget.returnedProduct.availableProducts != null)
                          ...widget.returnedProduct.availableProducts!.map(
                            (product) => Text(
                              product.name ?? '',
                              textAlign: TextAlign.center,
                              style: MyThemes.txtStyle(
                                color: MyThemes.textWhiteColor,
                                fontSize: 4,
                              ),
                            ),
                          ),

                        if (widget.returnedProduct.availableProducts != null)
                          Text(
                            widget.returnedProduct.availableProducts!.length ==
                                    1
                                ? loc.ha.toLowerCase() == 'ha'
                                    ? 'Shu maxsulotdan ${widget.returnedProduct.mustProductQuantity} ta olinsa'
                                    : 'Из этого товара взять ${widget.returnedProduct.mustProductQuantity} штук'
                                : loc.ha.toLowerCase() == 'ha'
                                    ? 'Shu maxsulotlardan ${widget.returnedProduct.mustProductQuantity} tadan olinsa'
                                    : 'Из этих товаров взять по ${widget.returnedProduct.mustProductQuantity} штук',
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyle(
                              color: Colors.grey.shade500,
                              fontSize: 2.5,
                            ),
                          ),


                        if (item != null)
                          Text(
                            item?.name ?? '',
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyle(
                              color: MyThemes.textWhiteColor,
                              fontSize: 4,
                            ),
                          ),
                        if (item != null)
                          Text(
                            loc.ha.toLowerCase() == 'ha'
                                ? 'Shu maxsulotdan ${widget.returnedProduct.returnedProductQuantity} ta berish kerak!!!'
                                : 'Из этого товара нужно выдать ${widget.returnedProduct.returnedProductQuantity} штук!!!',
                            textAlign: TextAlign.center,
                            style: MyThemes.txtStyle(
                              color: Colors.grey.shade500,
                              fontSize: 2.5,
                            ),
                          ),
                      ],
                    ),
                    SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            DefaultButton(
              text: "Ok",
              isButtonEnabled: true,
              onPress: () async {
                if (widget.isFirst) {
                  widget.provider.setDialogForDiscount(false);
                }
                AppNavigation.pop();
              },
              okButton: true,
            )
          ],
        ),
      ),
    );
  }
}
