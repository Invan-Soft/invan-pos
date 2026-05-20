import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class Button extends StatelessWidget {
  const Button({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      onPressed: onPressed,
      minWidth: SizeConfig.h * 25,
      height: SizeConfig.v * 8,
      color: Theme.of(context).primaryColor.withOpacity(.9),
      child: Text(
        text,
        style: MyThemes.txtStyle(
          fontSize: 2.2,
          color: Colors.white,
        ),
      ),
    );
  }
}
