import 'package:flutter/material.dart';
import 'package:invan2/changes/dialogs/virtual_keyboard/componets/macbook_key.dart';

class SingleCharKey extends StatelessWidget {
  final Alignment? alignment;
  final double? width;
  final double? height;
  final String char;
  final Color? color;
  final Function(String) onPressed;

  const SingleCharKey({
    Key? key,
    this.color,
    this.alignment,
    this.width,
    this.height,
    required this.char,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MacbookKey(
      color: color,
      alignment: alignment,
      width: width,
      height: height,
      onPressed: () {
        onPressed(char);
      },
      child: Text(
        char,
        style:  TextStyle(
          color: color,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
