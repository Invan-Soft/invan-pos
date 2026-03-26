import 'package:flutter/material.dart';
import 'package:invan2/changes/providers/operation_on_product_provider.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/money_formatter.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';

class OPDsumma extends StatefulWidget {
  final String initialValue;

  const OPDsumma(this.initialValue, {Key? key}) : super(key: key);

  @override
  State<OPDsumma> createState() => _OPDsummaState();
}

class _OPDsummaState extends State<OPDsumma> {
  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return SizedBox(
      height: SizeConfig.v * 4.81,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              loc.jami,
              style: MyThemes.txtStyle(color: Theme.of(context).canvasColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                  // border: Border(
                  //   bottom: BorderSide(
                  //     color: Theme.of(context).canvasColor,
                  //   ),
                  // ),
                  ),
              child: TextButton(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () {
                  //TODO Bu yerda jami summani o`zgartirib bo`lmaydigan qilindi 27.04.2023
                  // Provider.of<OperationOnProductProvider>(context,
                  //         listen: false)
                  //     .selectInput(4);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).dialogBackgroundColor,
                  padding: const EdgeInsets.all(0.0),
                ),
                child: Text(
                  MoneyFormatter.inputMoneyFormatter.format(
                    double.parse(
                      (Provider.of<OperationOnProductProvider>(context,
                                      listen: false)
                                  .target
                                  .price *
                              Provider.of<OperationOnProductProvider>(context,
                                      listen: false)
                                  .target
                                  .value)
                          .toStringAsFixed(0),
                    ),
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: SizeConfig.v * 2.3,
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.normal,
                    color: Theme.of(context).canvasColor,
                    backgroundColor: context
                            .watch<OperationOnProductProvider>()
                            .isSelectedAlls[4]
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
