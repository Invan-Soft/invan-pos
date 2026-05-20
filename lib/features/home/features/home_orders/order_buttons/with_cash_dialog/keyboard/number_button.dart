import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class DigitButton extends StatelessWidget {
  const DigitButton({
    Key? key,
    required this.number,
    required this.onPress,
  }) : super(key: key);

  final int number;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: SizeConfig.v * 10,
        height: SizeConfig.v * 10,
        child: RawMaterialButton(
          focusNode: FocusNode(skipTraversal: true),
          elevation: 10,
          fillColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: onPress,
          child: Text(
            '$number',
            style: MyThemes.txtStyle(
              color: Colors.black,
              fontSize: 4,
            ),
          ),
        ),
      ),
    );
  }
}
