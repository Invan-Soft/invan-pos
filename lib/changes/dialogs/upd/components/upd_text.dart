import 'package:flutter/material.dart';
import 'package:invan2/utils/themes.dart';

// ignore: must_be_immutable
class UpdText extends StatelessWidget {
  final String text;
  TextAlign textAlign;
  FontWeight fw;
  UpdText(this.text,
      {this.textAlign = TextAlign.center,
      this.fw = FontWeight.normal,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: MyThemes.txtStyle(
        fontWeight: fw,
        fontSize: 2,
        color: MyThemes.textWhiteColor,
      ),
    );
  }
}
