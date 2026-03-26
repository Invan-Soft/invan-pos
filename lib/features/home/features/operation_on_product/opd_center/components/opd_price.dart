import 'package:flutter/material.dart';
import 'package:invan2/changes/providers/operation_on_product_provider.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

class OPDprice extends StatefulWidget {
  const OPDprice({Key? key}) : super(key: key);

  @override
  State<OPDprice> createState() => _OPDpriceState();
}

class _OPDpriceState extends State<OPDprice> {
  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: SizeConfig.v * 2.1),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              loc.chegirmali_narx,
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
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
                      .selectInput(0);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).dialogBackgroundColor,
                  padding: const EdgeInsets.all(0.0),
                ),
                child: Text(
                  context.watch<OperationOnProductProvider>().priceStr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: SizeConfig.v * 2.3,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.normal,
                    color: Theme.of(context).canvasColor,
                    backgroundColor: context
                            .watch<OperationOnProductProvider>()
                            .isSelectedAlls[0]
                        ? Colors.red.withOpacity(.4)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
