import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../changes/providers/operation_on_product_provider.dart';

class OPDTop extends StatelessWidget {
  const OPDTop({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final item = Provider.of<OperationOnProductProvider>(context).getItem;
    return Container(
      height: SizeConfig.v * 6.64,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 1.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  overflow: TextOverflow.ellipsis,
                  style: MyThemes.txtStyle(
                    color: Theme.of(context).canvasColor,
                  ),
                ),
                // Blok tahriri: "N blokda M ta" — kassir blokdagi dona sonini
                // ko'rsin (item.value = blok soni, boxValue = 1 blokdagi dona).
                if (item.saleType == 2 && item.boxValue > 0)
                  Text(
                    '${item.value.toStringAsFixed(0)} blokda '
                    '${(item.value * item.boxValue).toStringAsFixed(0)} ta',
                    overflow: TextOverflow.ellipsis,
                    style: MyThemes.txtStyle(
                      fontSize: 1.8,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              ),
              padding: EdgeInsets.only(bottom: SizeConfig.h * .2),
              child: TextButton(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () {
                  Provider.of<OperationOnProductProvider>(context,
                          listen: false)
                      .selectInput(5);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).dialogBackgroundColor,
                  padding: const EdgeInsets.all(0.0),
                ),
                child: Text(
                  context.watch<OperationOnProductProvider>().onlyPriceStr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: SizeConfig.v * 2.3,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.normal,
                    color: Theme.of(context).canvasColor,
                    backgroundColor: context
                            .watch<OperationOnProductProvider>()
                            .isSelectedAlls[5]
                        ? Colors.red.withOpacity(.4)
                        : null,
                  ),
                ),
              ),
            ),
          ),
          CloseButton(
            color: Theme.of(context).canvasColor,
            onPressed: () {
              AppNavigation.pop();
            },
          ),
        ],
      ),
    );
  }
}
