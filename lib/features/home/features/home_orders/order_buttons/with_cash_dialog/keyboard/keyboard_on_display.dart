import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/features/home/features/home_orders/order_buttons/with_cash_dialog/keyboard/number_button.dart';
import 'package:invan2/changes/providers/provider_of_with_cash_dialog.dart';
import 'package:provider/provider.dart';
import 'package:invan2/utils/utils.dart';

class KeyboardOnWithCashPaymentDialog extends StatefulWidget {
  const KeyboardOnWithCashPaymentDialog({Key? key}) : super(key: key);

  @override
  KeyboardOnWithCashPaymentDialogState createState() =>
      KeyboardOnWithCashPaymentDialogState();
}

class KeyboardOnWithCashPaymentDialogState
    extends State<KeyboardOnWithCashPaymentDialog>
    with SingleTickerProviderStateMixin {
  late WithCashProvider withCashProvider;

  late AnimationController controller;

  final focusNode = FocusNode();

  @override
  void initState() {
    controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = Tween(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.reverse();
        }
      });
    withCashProvider = Provider.of<WithCashProvider>(context);
    return AnimatedBuilder(
      animation: offsetAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.only(
            left: offsetAnimation.value + 24.0,
            right: 24.0 - offsetAnimation.value,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: SizeConfig.v * 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RawKeyboardListener(
                    focusNode: focusNode,
                    autofocus: true,
                    onKey: (event) {
                      if (event.logicalKey == LogicalKeyboardKey.digit0 ||
                          event.logicalKey == LogicalKeyboardKey.numpad0) {
                        pressNum(context, 0);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit1 ||
                          event.logicalKey == LogicalKeyboardKey.numpad1) {
                        pressNum(context, 1);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit2 ||
                          event.logicalKey == LogicalKeyboardKey.numpad2) {
                        pressNum(context, 2);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit3 ||
                          event.logicalKey == LogicalKeyboardKey.numpad3) {
                        pressNum(context, 3);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit4 ||
                          event.logicalKey == LogicalKeyboardKey.numpad4) {
                        pressNum(context, 4);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit5 ||
                          event.logicalKey == LogicalKeyboardKey.numpad5) {
                        pressNum(context, 5);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit6 ||
                          event.logicalKey == LogicalKeyboardKey.numpad6) {
                        pressNum(context, 6);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit7 ||
                          event.logicalKey == LogicalKeyboardKey.numpad7) {
                        pressNum(context, 7);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit8 ||
                          event.logicalKey == LogicalKeyboardKey.numpad8) {
                        pressNum(context, 8);
                      } else if (event.logicalKey ==
                              LogicalKeyboardKey.digit9 ||
                          event.logicalKey == LogicalKeyboardKey.numpad9) {
                        pressNum(context, 9);
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.delete) {
                        pressCButton(context);
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.backspace) {
                        pressDeleteButton(context);
                      }
                    },
                    child: DigitButton(
                      number: 1,
                      onPress: () => pressNum(context, 1),
                    ),
                  ),
                  DigitButton(
                    number: 2,
                    onPress: () => pressNum(context, 2),
                  ),
                  DigitButton(
                    number: 3,
                    onPress: () => pressNum(context, 3),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DigitButton(
                    number: 4,
                    onPress: () => pressNum(context, 4),
                  ),
                  DigitButton(
                    number: 5,
                    onPress: () => pressNum(context, 5),
                  ),
                  DigitButton(
                    number: 6,
                    onPress: () => pressNum(context, 6),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DigitButton(
                    number: 7,
                    onPress: () => pressNum(context, 7),
                  ),
                  DigitButton(
                    number: 8,
                    onPress: () => pressNum(context, 8),
                  ),
                  DigitButton(
                    number: 9,
                    onPress: () => pressNum(context, 9),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: SizeConfig.v * 10,
                      height: SizeConfig.v * 10,
                      child: RawMaterialButton(
                        focusNode: FocusNode(skipTraversal: true),
                        elevation: 10,
                        fillColor: Colors.white,
                        shape: const CircleBorder(),
                        child: Text(
                          'C',
                          style: MyThemes.txtStyle(
                            color: Colors.red,
                            fontSize: 4,
                          ),
                        ),
                        onPressed: () => pressCButton(context),
                      ),
                    ),
                  ),
                  DigitButton(
                    number: 0,
                    onPress: () => pressNum(context, 0),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: SizeConfig.v * 10,
                      height: SizeConfig.v * 10,
                      child: RawMaterialButton(
                        focusNode: FocusNode(skipTraversal: true),
                        elevation: 10,
                        fillColor: Colors.white,
                        shape: const CircleBorder(),
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: Colors.black,
                        ),
                        onPressed: () => pressDeleteButton(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  void pressDeleteButton(BuildContext context) {
    if (isUnableToClick(DateTime.now())) {
      return;
    } else {
      withCashProvider.decreaseControllerText();
    }
  }

  void pressCButton(BuildContext context) {
    if (isUnableToClick(DateTime.now())) {
      return;
    } else {
      Provider.of<WithCashProvider>(context, listen: false)
          .changeControllerValue('');
    }
  }

  void pressNum(BuildContext context, int num) {
    if (isUnableToClick(DateTime.now())) {
      return;
    } else {
      withCashProvider.increaseControllerText(num);
    }
  }

  void shake(BuildContext context) async {
    controller.reset();
    controller.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
