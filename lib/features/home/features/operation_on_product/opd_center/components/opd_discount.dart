import 'package:flutter/material.dart';
import 'package:invan2/changes/providers/operation_on_product_provider.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';

class OPDDiscount extends StatefulWidget {
  const OPDDiscount({super.key});

  @override
  OPDDiscountState createState() => OPDDiscountState();
}

class OPDDiscountState extends State<OPDDiscount> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: SizeConfig.v * 4.81,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              loc.chegirma,
              style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(SizeConfig.h * .2),
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
                  const Icon(Icons.percent, color: Colors.transparent),
                  TextButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () {
                      Provider.of<OperationOnProductProvider>(context,
                              listen: false)
                          .selectInput(3);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).dialogBackgroundColor,
                      padding: const EdgeInsets.all(0.0),
                    ),
                    child: Text(
                      context.watch<OperationOnProductProvider>().discountStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: SizeConfig.v * 2.3,
                        fontWeight: FontWeight.normal,
                        fontStyle: FontStyle.normal,
                        color: Theme.of(context).canvasColor,
                        backgroundColor: context
                                .watch<OperationOnProductProvider>()
                                .isSelectedAlls[3]
                            ? Colors.red.withOpacity(.4)
                            : null,
                      ),
                    ),
                  ),
                  Icon(Icons.percent, color: Theme.of(context).canvasColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
