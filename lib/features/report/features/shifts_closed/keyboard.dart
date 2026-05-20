import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/features/report/features/shifts_closed/number_button_of_shift_closed.dart';
import 'package:invan2/changes/providers/shift_closed_provider.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

class KeyboardOfShiftClosed extends StatefulWidget {
  const KeyboardOfShiftClosed({Key? key}) : super(key: key);

  @override
  KeyboardOfShiftClosedState createState() => KeyboardOfShiftClosedState();
}

class KeyboardOfShiftClosedState extends State<KeyboardOfShiftClosed> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: SizeConfig.v * 1.9,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RawKeyboardListener(
                focusNode: context.watch<ShiftClosedProvider>().focusNode,
                autofocus: true,
                onKey: (event) {
                  if (event.logicalKey == LogicalKeyboardKey.digit0 ||
                      event.logicalKey == LogicalKeyboardKey.numpad0) {
                    pressNum(context, 0);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit1 ||
                      event.logicalKey == LogicalKeyboardKey.numpad1) {
                    pressNum(context, 1);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
                      event.logicalKey == LogicalKeyboardKey.numpad2) {
                    pressNum(context, 2);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
                      event.logicalKey == LogicalKeyboardKey.numpad3) {
                    pressNum(context, 3);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
                      event.logicalKey == LogicalKeyboardKey.numpad4) {
                    pressNum(context, 4);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit5 ||
                      event.logicalKey == LogicalKeyboardKey.numpad5) {
                    pressNum(context, 5);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit6 ||
                      event.logicalKey == LogicalKeyboardKey.numpad6) {
                    pressNum(context, 6);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit7 ||
                      event.logicalKey == LogicalKeyboardKey.numpad7) {
                    pressNum(context, 7);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit8 ||
                      event.logicalKey == LogicalKeyboardKey.numpad8) {
                    pressNum(context, 8);
                  } else if (event.logicalKey == LogicalKeyboardKey.digit9 ||
                      event.logicalKey == LogicalKeyboardKey.numpad9) {
                    pressNum(context, 9);
                  } else if (event.logicalKey == LogicalKeyboardKey.delete) {
                    pressCButton(context);
                  } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
                    pressBackSpace(context);
                  } else if (event.logicalKey == LogicalKeyboardKey.period ||
                      event.logicalKey == LogicalKeyboardKey.numpadDecimal) {
                    pressNum(context, 111);
                  } else if (event.logicalKey == LogicalKeyboardKey.delete) {
                    pressCButton(context);
                  }
                },
                child: NumberButtonOfShiftClosed(
                  number: "7",
                  onPress: () => pressNum(context, 7),
                ),
              ),
              NumberButtonOfShiftClosed(
                number: "8",
                onPress: () => pressNum(context, 8),
              ),
              NumberButtonOfShiftClosed(
                number: "9",
                onPress: () => pressNum(context, 9),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NumberButtonOfShiftClosed(
                number: "4",
                onPress: () => pressNum(context, 4),
              ),
              NumberButtonOfShiftClosed(
                number: "5",
                onPress: () => pressNum(context, 5),
              ),
              NumberButtonOfShiftClosed(
                number: "6",
                onPress: () => pressNum(context, 6),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NumberButtonOfShiftClosed(
                number: "1",
                onPress: () => pressNum(context, 1),
              ),
              NumberButtonOfShiftClosed(
                number: "2",
                onPress: () => pressNum(context, 2),
              ),
              NumberButtonOfShiftClosed(
                number: "3",
                onPress: () => pressNum(context, 3),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NumberButtonOfShiftClosed(
                number: "0",
                onPress: () => pressNum(context, 0),
              ),
              NumberButtonOfShiftClosed(
                number: ".",
                onPress: () => pressNum(context, 111),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.h * 0.78,
                    vertical: SizeConfig.v * 1.04),
                child: SizedBox(
                  width: SizeConfig.h * 6.666,
                  height: SizeConfig.v * 9.46,
                  child: RawMaterialButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onLongPress: () => pressCButton(context),
                    elevation: 5,
                    fillColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(SizeConfig.v * 1.1)),
                    child: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => pressBackSpace(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: SizeConfig.v * 1.77,
          )
        ],
      ),
    );
  }

/* ////////////////////// PinCode ///////////////////////// */
/* ////////////////////// PinCode ///////////////////////// */
/* ////////////////////// PinCode ///////////////////////// */
/* ////////////////////// PinCode ///////////////////////// */

  DateTime? clickTime;

  bool isUnableToClick(DateTime currentTime) {
    if (clickTime == null) {
      clickTime = currentTime;
      return false;
    } else {
      if (currentTime.difference(clickTime!).inMilliseconds < 300) {
        return true;
      }

      clickTime = currentTime;
      return false;
    }
  }

  void pressBackSpace(BuildContext context) {
    if (isUnableToClick(DateTime.now())) {
      return;
    } else {
      Provider.of<ShiftClosedProvider>(context, listen: false)
          .decreaseController();
    }
  }

  void pressCButton(BuildContext context) {
    if (isUnableToClick(DateTime.now())) {
      return;
    } else {
      Provider.of<ShiftClosedProvider>(context, listen: false).cButtonPressed();
    }
  }

  void pressNum(BuildContext context, int num) {
    if (isUnableToClick(DateTime.now())) {
      return;
    } else {
      if (num == 111) {
        Provider.of<ShiftClosedProvider>(context, listen: false).onDotPressed();
      } else {
        Provider.of<ShiftClosedProvider>(context, listen: false)
            .increaseController(num.toString());
      }
    }
  }
}
