import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class NumberButtonOfShiftClosed extends StatelessWidget {
  const NumberButtonOfShiftClosed({
    Key? key,
    required this.number,
    required this.onPress,
  }) : super(key: key);

  final String number;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.h * 0.78, vertical: SizeConfig.v * 1.04),
      child: SizedBox(
        width: SizeConfig.h * 6.666,
        height: SizeConfig.v * 9.46,
        child: RawMaterialButton(
          focusNode: FocusNode(skipTraversal: true),
          elevation: 5,
          fillColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
          onPressed: onPress,
          child: Text(
            number,
            style: MyThemes.txtStyle(
              fontWeight: FontWeight.w700,
              color: const Color(0xff434862),
              fontSize: 3.5,
            ),
          ),
        ),
      ),
    );
  }
}
