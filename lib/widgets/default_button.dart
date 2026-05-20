import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

// ignore: must_be_immutable
class DefaultButton extends StatelessWidget {
  DefaultButton({
    super.key,
    this.height = 7.55,
    required this.text,
    required this.isButtonEnabled,
    this.onPress,
    this.isErrorButton = false,
    this.deleteButton = false,
    this.okButton = false,
  });

  double height;
  final String text;
  final bool isButtonEnabled;
  final VoidCallback? onPress;
  final bool isErrorButton;
  final bool deleteButton;
  final bool okButton;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.v)),
      color: okButton
          ? Color(0xFF297A2C)
          : isErrorButton
              ? Theme.of(context).colorScheme.error
              : deleteButton
                  ? Colors.red
                  : Theme.of(context).primaryColor,
      disabledColor: okButton
          ? Color(0xFF38A63C)
          : isErrorButton
              ? Theme.of(context).colorScheme.error.withOpacity(.5)
              : deleteButton
                  ? Colors.red.shade500.withOpacity(.3)
                  : Theme.of(context).primaryColor.withOpacity(.5),
      minWidth: double.infinity,
      height: SizeConfig.v * height,
      onPressed: isButtonEnabled ? onPress : null,
      textColor: Colors.white,
      disabledTextColor: Colors.white.withOpacity(.8),
      child: Text(
        text,
        style: MyThemes.txtStyle(
          fontSize: 2.4,
          color: Pref.getBool(PrefKeys.isDarkMode, true)
              ? Colors.white
              : Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
