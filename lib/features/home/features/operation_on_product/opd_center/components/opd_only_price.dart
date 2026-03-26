import 'package:flutter/material.dart';
import 'package:invan2/changes/providers/operation_on_product_provider.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';

class OPDonlyPrice extends StatefulWidget {
  const OPDonlyPrice({Key? key}) : super(key: key);
  @override
  OPDonlyPriceState createState() => OPDonlyPriceState();
}

class OPDonlyPriceState extends State<OPDonlyPrice> {
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
              loc.narxi,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
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
