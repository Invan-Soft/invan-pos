/*
    @author Suxrob Sattorov, 2/1/2025, 11:36 AM
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../changes/providers/operation_on_product_provider.dart';
import '../../../../utils/utils.dart';
import '../../../lock/lock/view/lock_number_button.dart';

class NumberCalc extends StatelessWidget {
  double height;
  bool isKg;

  NumberCalc({
    super.key,
    required this.height,
    required this.isKg,
  });

  void pressNum(BuildContext context, String num) {
    Provider.of<OperationOnProductProvider>(context, listen: false)
        .onNumPressed(num);
  }

  @override
  Widget build(BuildContext context) {
    Color? color = Pref.getBool(PrefKeys.isDarkMode, true)
        ? Theme.of(context).primaryColor
        : null;
    Color? textColor =
        Pref.getBool(PrefKeys.isDarkMode, true) ? Colors.grey.shade300 : null;
    return Container(
      width: SizeConfig.v * 32,
      height: height,
      decoration: BoxDecoration(
        color: Pref.getBool(PrefKeys.isDarkMode, true)
            ? Theme.of(context).dialogBackgroundColor
            : MyThemes.lightGreyColorr,
        borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: SizeConfig.v),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LockNumberButton(
                number: "1",
                onPress: () => pressNum(context, '1'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
              LockNumberButton(
                number: "2",
                onPress: () => pressNum(context, '2'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
              LockNumberButton(
                number: "3",
                onPress: () => pressNum(context, '3'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LockNumberButton(
                number: "4",
                onPress: () => pressNum(context, '4'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
              LockNumberButton(
                number: "5",
                onPress: () => pressNum(context, '5'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
              LockNumberButton(
                number: "6",
                onPress: () => pressNum(context, '6'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LockNumberButton(
                number: "7",
                onPress: () => pressNum(context, '7'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
              LockNumberButton(
                number: "8",
                onPress: () => pressNum(context, '8'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
              LockNumberButton(
                number: "9",
                onPress: () => pressNum(context, '9'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              !isKg
                  ? Padding(
                      padding: EdgeInsets.all(SizeConfig.v * 1.04),
                      child: SizedBox(
                        width: SizeConfig.v * 8,
                        height: SizeConfig.v * 8,
                        child: RawMaterialButton(
                          focusNode: FocusNode(skipTraversal: true),
                          elevation: 0,
                          fillColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.v * 1.1)),
                          onPressed: null,
                          mouseCursor: SystemMouseCursors.basic,
                        ),
                      ),
                    )
                  : LockNumberButton(
                      number: ".",
                      onPress: () => pressNum(context, '.'),
                      color: color,
                      textColor: textColor,
                      sizeEdited: true,
                    ),
              LockNumberButton(
                number: "0",
                onPress: () => pressNum(context, '0'),
                color: color,
                textColor: textColor,
                sizeEdited: true,
              ),
              Padding(
                padding: EdgeInsets.all(SizeConfig.v * 1.04),
                child: SizedBox(
                  width: SizeConfig.v * 8,
                  height: SizeConfig.v * 8,
                  child: RawMaterialButton(
                    focusNode: FocusNode(skipTraversal: true),
                    elevation: 0,
                    fillColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(SizeConfig.v * 1.1)),
                    child: Image.asset(
                      "assets/images/clear.png",
                    ),
                    onPressed: () => pressNum(context, '10'),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.v)
        ],
      ),
    );
  }
}
