import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/changes/components/shortcuts.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/lock/lock/view/lock_dots.dart';
import 'package:invan2/features/lock/lock/view/lock_number_button.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class PincodeKeyboardWidgetOff extends StatefulWidget {
  final int passwordLenth;
  final Function(int) pressNum;
  final VoidCallback pressDeleteButton;
  final int length;
  final VoidCallback cardPressedd;
  const PincodeKeyboardWidgetOff({
    required this.passwordLenth,
    required this.length,
    required this.cardPressedd,
    required this.pressDeleteButton,
    required this.pressNum,
    super.key,
  });

  @override
  State<PincodeKeyboardWidgetOff> createState() =>
      _PincodeKeyboardWidgetOffState();
}

class _PincodeKeyboardWidgetOffState extends State<PincodeKeyboardWidgetOff> {
  late FocusNode focusNode;
  @override
  void initState() {
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          loc.parol_keriting,
          style: MyThemes.txtStyle(
            fontWeight: FontWeight.w700,
            color: const Color(0xff434862),
            fontSize: 2.57,
          ),
        ),
        SizedBox(height: SizeConfig.v * 3.1),
        LockDots(widget.length, passwordLength: widget.passwordLenth),
        SizedBox(height: SizeConfig.v * 3.2),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.numpad0): Intend0(),
                LogicalKeySet(LogicalKeyboardKey.numpad1): Intend1(),
                LogicalKeySet(LogicalKeyboardKey.numpad2): Intend2(),
                LogicalKeySet(LogicalKeyboardKey.numpad3): Intend3(),
                LogicalKeySet(LogicalKeyboardKey.numpad4): Intend4(),
                LogicalKeySet(LogicalKeyboardKey.numpad5): Intend5(),
                LogicalKeySet(LogicalKeyboardKey.numpad6): Intend6(),
                LogicalKeySet(LogicalKeyboardKey.numpad7): Intend7(),
                LogicalKeySet(LogicalKeyboardKey.numpad8): Intend8(),
                LogicalKeySet(LogicalKeyboardKey.numpad9): Intend9(),
                ///////////////////////////////////////////////
                LogicalKeySet(LogicalKeyboardKey.digit0): Intend0(),
                LogicalKeySet(LogicalKeyboardKey.digit1): Intend1(),
                LogicalKeySet(LogicalKeyboardKey.digit2): Intend2(),
                LogicalKeySet(LogicalKeyboardKey.digit3): Intend3(),
                LogicalKeySet(LogicalKeyboardKey.digit4): Intend4(),
                LogicalKeySet(LogicalKeyboardKey.digit5): Intend5(),
                LogicalKeySet(LogicalKeyboardKey.digit6): Intend6(),
                LogicalKeySet(LogicalKeyboardKey.digit7): Intend7(),
                LogicalKeySet(LogicalKeyboardKey.digit8): Intend8(),
                LogicalKeySet(LogicalKeyboardKey.digit9): Intend9(),
                ///////////////////////////////////////////////
                LogicalKeySet(LogicalKeyboardKey.backspace): IntendBackSpace(),
                LogicalKeySet(LogicalKeyboardKey.numpadDecimal): IntendDot(),
                LogicalKeySet(LogicalKeyboardKey.period): IntendDot(),
                LogicalKeySet(LogicalKeyboardKey.numpadEnter): IntendEnter(),
                LogicalKeySet(LogicalKeyboardKey.tab): IntendTab(),
              },
              child: Actions(
                actions: {
                  Intend0: CallbackAction<Intend0>(
                    onInvoke: (intent) {
                      widget.pressNum(0);
                      return;
                    },
                  ),
                  Intend1: CallbackAction<Intend1>(
                    onInvoke: (intent) {
                      widget.pressNum(1);
                      return;
                    },
                  ),
                  Intend2: CallbackAction<Intend2>(
                    onInvoke: (intent) {
                      widget.pressNum(2);
                      return;
                    },
                  ),
                  Intend3: CallbackAction<Intend3>(
                    onInvoke: (intent) {
                      widget.pressNum(3);
                      return;
                    },
                  ),
                  Intend4: CallbackAction<Intend4>(
                    onInvoke: (intent) {
                      widget.pressNum(4);
                      return;
                    },
                  ),
                  Intend5: CallbackAction<Intend5>(
                    onInvoke: (intent) {
                      widget.pressNum(5);
                      return;
                    },
                  ),
                  Intend6: CallbackAction<Intend6>(
                    onInvoke: (intent) {
                      widget.pressNum(6);
                      return;
                    },
                  ),
                  Intend7: CallbackAction<Intend7>(
                    onInvoke: (intent) {
                      widget.pressNum(7);
                      return;
                    },
                  ),
                  Intend8: CallbackAction<Intend8>(
                    onInvoke: (intent) {
                      widget.pressNum(8);
                      return;
                    },
                  ),
                  Intend9: CallbackAction<Intend9>(
                    onInvoke: (intent) {
                      widget.pressNum(9);
                      return;
                    },
                  ),
                  IntendBackSpace: CallbackAction<IntendBackSpace>(
                    onInvoke: (intent) {
                      widget.pressDeleteButton();
                      return;
                    },
                  ),
                  IntendTab: CallbackAction<IntendTab>(
                    onInvoke: (intent) {
                      return;
                    },
                  ),
                },
                child: Focus(
                  autofocus: true,
                  focusNode: focusNode,
                  child: LockNumberButton(
                    number: "1",
                    onPress: () => widget.pressNum(1),
                  ),
                ),
              ),
            ),
            LockNumberButton(
              number: "2",
              onPress: () => widget.pressNum(2),
            ),
            LockNumberButton(
              number: "3",
              onPress: () => widget.pressNum(3),
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
              onPress: () => widget.pressNum(4),
            ),
            LockNumberButton(
              number: "5",
              onPress: () => widget.pressNum(5),
            ),
            LockNumberButton(
              number: "6",
              onPress: () => widget.pressNum(6),
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
              onPress: () => widget.pressNum(7),
            ),
            LockNumberButton(
              number: "8",
              onPress: () => widget.pressNum(8),
            ),
            LockNumberButton(
              number: "9",
              onPress: () => widget.pressNum(9),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(SizeConfig.v * 1.04),
              child: SizedBox(
                width: SizeConfig.v * 9,
                height: SizeConfig.v * 9,
                child: RawMaterialButton(
                  focusNode: FocusNode(skipTraversal: true),
                  elevation: 0,
                  fillColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
                  onPressed: widget.cardPressedd,
                  child: Image.asset(
                    "assets/images/card.png",
                  ),
                ),
              ),
            ),
            LockNumberButton(
              number: "0",
              onPress: () => widget.pressNum(0),
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.v * 1.04),
              child: SizedBox(
                width: SizeConfig.v * 9,
                height: SizeConfig.v * 9,
                child: RawMaterialButton(
                  focusNode: FocusNode(skipTraversal: true),
                  elevation: 0,
                  fillColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
                  child: Image.asset(
                    "assets/images/clear.png",
                  ),
                  onPressed: () => widget.pressDeleteButton(),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: SizeConfig.v * 4.8,
        )
      ],
    );
  }
}
