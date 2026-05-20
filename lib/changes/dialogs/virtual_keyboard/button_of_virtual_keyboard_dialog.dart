import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class ButtonOfVirtualKeyboardDialog extends StatelessWidget {
  const ButtonOfVirtualKeyboardDialog({
    Key? key,
    required this.number,
    required this.onPress,
  }) : super(key: key);

  final String number;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SizeConfig.h * 6.73,
      height: SizeConfig.v * 9.68,
      child: RawMaterialButton(
        focusNode: FocusNode(skipTraversal: true),
        elevation: 0,
        fillColor: Theme.of(context).dividerColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
        onPressed: onPress,
        child: Text(
          number,
          style: MyThemes.txtStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).canvasColor,
            fontSize: 3.5,
          ),
        ),
      ),
    );
  }
}
