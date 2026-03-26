import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class LockNumberButton extends StatelessWidget {
  LockNumberButton({
    Key? key,
    required this.number,
    required this.onPress,
    this.color,
    this.textColor,
    this.sizeEdited,
  }) : super(key: key);

  final String number;
  final VoidCallback onPress;
  Color? color;
  Color? textColor;
  bool? sizeEdited;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.v * 1.04),
      child: SizedBox(
        width: sizeEdited != null && sizeEdited == true
            ? SizeConfig.v * 8
            : SizeConfig.v * 9,
        height: sizeEdited != null && sizeEdited == true
            ? SizeConfig.v * 8
            : SizeConfig.v * 9,
        child: RawMaterialButton(
          focusNode: FocusNode(skipTraversal: true),
          elevation: 5,
          fillColor: color ?? Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
          onPressed: onPress,
          child: Text(
            number,
            style: MyThemes.txtStyle(
              fontWeight: FontWeight.w700,
              color: textColor ?? const Color(0xff434862),
              fontSize: sizeEdited != null && sizeEdited == true ? 2.5 : 3.5,
            ),
          ),
        ),
      ),
    );
  }
}
