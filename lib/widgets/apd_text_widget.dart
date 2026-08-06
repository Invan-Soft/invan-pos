import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

// ignore: must_be_immutable
class ApdText extends StatelessWidget {
  final String title;
  TextAlign textAlign;
  ApdText(
    this.title, {
    super.key,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: textAlign,
      style: MyThemes.txtStyle(
          color: MyThemes.textBlackColor, fontWeight: FontWeight.bold),
    );
  }
}
