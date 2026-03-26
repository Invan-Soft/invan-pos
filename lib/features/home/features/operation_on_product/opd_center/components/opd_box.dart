import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../../../changes/providers/operation_on_product_provider.dart';

class OPDbox extends StatefulWidget {
  const OPDbox({
    Key? key,
    required this.value,
  }) : super(key: key);
  final double value;

  @override
  OPDboxState createState() => OPDboxState();
}

class OPDboxState extends State<OPDbox> {
  @override
  Widget build(BuildContext context) {
    final opdProvider = Provider.of<OperationOnProductProvider>(context);
    final item = opdProvider.getItem;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            "Box",
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
                        .selectInput(2);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).dialogBackgroundColor,
                    padding: const EdgeInsets.all(0.0),
                  ),
                  child: Text(
                    context.watch<OperationOnProductProvider>().boxValueStr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: SizeConfig.v * 2.3,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.normal,
                      color: Theme.of(context).canvasColor,
                      backgroundColor: context
                              .watch<OperationOnProductProvider>()
                              .isSelectedAlls[2]
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
        minimumSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        fixedSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        elevation: 0,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(.4),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        opdProvider.decreaseQuantity(item.inBox);
      },
      child: Icon(
        Icons.remove,
        color: Theme.of(context).canvasColor,
      ),
    );
  }

  ElevatedButton _suffixIcon(
      OperationOnProductProvider opdProvider, ReceiptModelSoldItem4 item) {
    return ElevatedButton(
      focusNode: FocusNode(skipTraversal: true),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        fixedSize: Size(SizeConfig.v * 3.64, SizeConfig.v * 3.64),
        elevation: 0,
        backgroundColor: Theme.of(context).dividerColor.withOpacity(.4),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        opdProvider.increaseQuantity(item.inBox);
      },
      child: Icon(
        Icons.add,
        color: Theme.of(context).canvasColor,
      ),
    );
  }
}
