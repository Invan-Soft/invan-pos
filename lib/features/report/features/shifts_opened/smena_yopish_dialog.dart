import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';

class CloseShiftDialog extends StatefulWidget {
  const CloseShiftDialog({
    Key? key,
    required this.shiftt,
  }) : super(key: key);

  final ShiftModelHive shiftt;

  @override
  CloseShiftDialogState createState() => CloseShiftDialogState();
}

class CloseShiftDialogState extends State<CloseShiftDialog> {
  final FocusNode _focusNode = FocusNode();
  int actCashAmount = 0;

  @override
  void initState() {
    super.initState();
    if (context.read<OpenShiftProvider>().controller.text.isEmpty) {
      context.read<OpenShiftProvider>().controller.text = MoneyFormatter
          .formatter
          .format(widget.shiftt.cashDrawerHive!.expCashAmount);
    }
    _focusNode.addListener(
      () {
        if (_focusNode.hasFocus) {
          Provider.of<OpenShiftProvider>(context, listen: false)
              .controller
              .selection = TextSelection(
            baseOffset: 0,
            extentOffset: Provider.of<OpenShiftProvider>(context, listen: false)
                .controller
                .text
                .length,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWaiting =
        Provider.of<OpenShiftProvider>(context, listen: false).getIsWaiting;
    final loc = AppLocalizations.of(context)!;

    final openShiftProvider = Provider.of<OpenShiftProvider>(context);
    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        width: SizeConfig.h * 45,
        height: SizeConfig.v * 50,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Theme.of(context).canvasColor, blurRadius: 4)
          ],
          color: Pref.getBool(PrefKeys.isDarkMode, true)
              ? Theme.of(context).dialogBackgroundColor
              : MyThemes.lightGreyColorr,
          borderRadius: BorderRadius.circular(
            SizeConfig.v,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(SizeConfig.v * 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.smenaniYopish,
                    style: MyThemes.txtStyle(
                      fontSize: 2.8,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.kutilayotganPulMiqdori,
                        style: MyThemes.txtStyle(
                          fontSize: 2.6,
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                      Text(
                        MoneyFormatter.formatter.format(
                            widget.shiftt.cashDrawerHive!.expCashAmount),
                        style: MyThemes.txtStyle(
                          fontSize: 2.6,
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.pulMiqdori,
                        style: MyThemes.txtStyle(
                          fontSize: 2.6,
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                      SizedBox(width: SizeConfig.h * 5),
                      Expanded(
                        child: TextField(
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9]'),
                            ),
                          ],
                          controller:
                              context.read<OpenShiftProvider>().controller,
                          textAlign: TextAlign.end,
                          focusNode: _focusNode,
                          style: MyThemes.txtStyle(
                            fontSize: 2.6,
                            color: Theme.of(context).canvasColor,
                          ),
                          decoration: InputDecoration(
                            disabledBorder: _border(),
                            enabledBorder: _border(),
                            focusedBorder: _border(),
                            border: _border(),
                            hintText: '0',
                            hintStyle: MyThemes.txtStyle(
                              fontSize: 2.6,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.hisobotniChopEtish,
                        style: MyThemes.txtStyle(
                          fontSize: 2.6,
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                      FilterChip(
                        checkmarkColor: Theme.of(context).primaryColor,
                        selectedColor: Colors.white,
                        disabledColor:
                            Theme.of(context).primaryColor.withOpacity(.5),
                        shadowColor: Colors.transparent,
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(.5),
                        onSelected: (v) {
                          openShiftProvider.setPrintReport();
                        },
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.h * 1.5,
                          vertical: SizeConfig.v * 1.5,
                        ),
                        label: Icon(
                          Icons.print,
                          color: MyThemes.darkPrimaryColor,
                          size: SizeConfig.v * 3.5,
                        ),
                        selected: openShiftProvider.getPrintReport,
                      ),
                    ],
                  ),
                  const SizedBox(height: 1, width: 0),
                  const SizedBox(height: 1, width: 0),
                  const SizedBox(height: 1, width: 0),
                  MaterialButton(
                    focusNode: FocusNode(skipTraversal: true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConfig.v,
                      ),
                    ),
                    color: Theme.of(context).primaryColor,
                    minWidth: double.infinity,
                    height: SizeConfig.v * 8,
                    onPressed: () =>
                        Provider.of<OpenShiftProvider>(context, listen: false)
                            .onShiftCloseButtonPressed(context),
                    child: Text(
                      loc.smenaniYopish.toUpperCase(),
                      style: MyThemes.txtStyle(
                        fontSize: 2.8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            isWaiting
                ? Positioned.fill(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Theme.of(context).primaryColor.withOpacity(.4),
                      child: Center(
                        child: SpinKitCircle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  )
                : const Positioned(
                    top: 0,
                    left: 0,
                    child: SizedBox(
                      height: 0,
                      width: 0,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  UnderlineInputBorder _border() {
    return UnderlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).canvasColor,
      ),
    );
  }
}
