import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/money_formatter.dart';
import 'package:invan2/utils/themes.dart';

// ignore: must_be_immutable
class TextRowCalculation extends StatelessWidget {
  final String title;
  final double money;
  final double fsize;
  bool isBold;
  TextRowCalculation({
    required this.fsize,
    required this.title,
    required this.money,
    this.isBold = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: MyThemes.txtStyle(
            color: Theme.of(context).canvasColor,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            fontSize: fsize,
          ),
        ),
        Text(
          MoneyFormatter.formatter.format(money),
          style: MyThemes.txtStyle(
            color: Theme.of(context).canvasColor,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            fontSize: fsize,
          ),
        ),
      ],
    );
  }
}
