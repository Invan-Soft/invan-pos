import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../../../changes/providers/operation_on_product_provider.dart';
import '../../delete_item/input_alert_dialog.dart';

class OPDQuantity extends StatefulWidget {
  const OPDQuantity({
    super.key,
    required this.value,
  });

  final num value;

  @override
  OPDQuantityState createState() => OPDQuantityState();
}

class OPDQuantityState extends State<OPDQuantity> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final opdProvider = Provider.of<OperationOnProductProvider>(context);
    final item = opdProvider.getItem;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            loc.soni,
            style: MyThemes.txtStyle(
              color: Theme.of(context).canvasColor,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.h * .1, vertical: SizeConfig.h * .2),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).canvasColor,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _prefixIcon(opdProvider, item),
                TextButton(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () {
                    Provider.of<OperationOnProductProvider>(context,
                            listen: false)
                        .selectInput(1);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).dialogBackgroundColor,
                    padding: const EdgeInsets.all(0.0),
                  ),
                  child: Text(
                    context.watch<OperationOnProductProvider>().valueStr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: SizeConfig.v * 2.3,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.normal,
                      color: Theme.of(context).canvasColor,
                      backgroundColor: context
                              .watch<OperationOnProductProvider>()
                              .isSelectedAlls[1]
                          ? Colors.red.withOpacity(.4)
                          : null,
                    ),
                  ),
                ),
                _suffixIcon(opdProvider, item)
              ],
            ),
          ),
        ),
      ],
    );
  }

  _prefixIcon(
      OperationOnProductProvider opdProvider, ReceiptModelSoldItem4 item) {
    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(SizeConfig.v * 5, SizeConfig.v * 5),
        fixedSize: Size(SizeConfig.v * 5, SizeConfig.v * 5),
        elevation: 0,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(.4),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () async {
        final provider =
            Provider.of<OperationOnProductProvider>(context, listen: false);

        if (item.value <= 1) {
          final Employee currentEmployee = HiveBoxes.getCurrentEmployee!;
          if (currentEmployee.access?.deletePrice ?? false) {
            Provider.of<OrderingProvider4>(context, listen: false)
                .pressDialogDeleteButton();
            AppNavigation.pop();
          } else {
            await showDialog(
              context: context,
              builder: (_) => InputAlertDialog(
                onUniversalPinEntered: () {},
                onValueEntered: (employee) {
                  Provider.of<OrderingProvider4>(context, listen: false)
                      .pressDialogDeleteButton();
                  AppNavigation.pop();
                  AppNavigation.pop();
                },
              ),
            );
          }
          return;
        }

        await provider.attemptDecreaseQuantity(1, context);
      },
      child: Icon(
        Icons.remove,
        color: Theme.of(context).canvasColor,
        size: SizeConfig.v * 3,
      ),
    );
  }

  ElevatedButton _suffixIcon(
      OperationOnProductProvider opdProvider, ReceiptModelSoldItem4 item) {
    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(SizeConfig.v * 5, SizeConfig.v * 5),
        fixedSize: Size(SizeConfig.v * 5, SizeConfig.v * 5),
        elevation: 0,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(.4),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        opdProvider.increaseQuantity(1);
      },
      child: Icon(
        Icons.add,
        color: Theme.of(context).canvasColor,
        size: SizeConfig.v * 3,
      ),
    );
  }
}
