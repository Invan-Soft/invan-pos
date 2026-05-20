import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class NumberButtonOfPaymentPage extends StatelessWidget {
  const NumberButtonOfPaymentPage({
    Key? key,
    required this.number,
    required this.onPress,
  }) : super(key: key);

  final String number;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.h * 1.56,
        bottom: SizeConfig.v * 1.78,
      ),
      child: SizedBox(
        width: SizeConfig.h * 6.73,
        height: SizeConfig.v * 9.68,
        child: RawMaterialButton(
          focusNode: FocusNode(skipTraversal: true),
          elevation: 0,
          fillColor: Theme.of(context).dialogBackgroundColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
          onPressed: onPress,
          child: Text(
            number,
            style: MyThemes.txtStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).canvasColor,
              fontSize: 3,
            ),
          ),
        ),
      ),
    );
  }
}
