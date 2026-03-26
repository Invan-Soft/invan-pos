// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:invan2/utils/themes.dart';

class SoldItemWidget extends StatelessWidget {
  final bool isDeleted;
  final int flex;
  final String title;
  TextAlign textAlign;

  SoldItemWidget(
      {Key? key,
      this.textAlign = TextAlign.center,
      required this.flex,
      required this.title,
      this.isDeleted = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: textAlign,
        style: MyThemes.txtStyle(
          textDecoration:
              isDeleted ? TextDecoration.lineThrough : TextDecoration.none,
          fontSize: 2.2,
          fontWeight: FontWeight.bold,
          fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
          color: Theme.of(context).canvasColor,
        ),
      ),
    );
  }
}

class SoldItemWidgetWithDiscount extends StatelessWidget {
  final bool isDeleted;
  final int flex;
  final String price;
  final String oldPrice;
  final double discountPercent;

  TextAlign textAlign;

  SoldItemWidgetWithDiscount(
      {Key? key,
      this.textAlign = TextAlign.center,
      required this.flex,
      required this.price,
      required this.discountPercent,
      this.isDeleted = false,
      required this.oldPrice})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = 80;
    if (oldPrice.length > 13) {
      width = 160;
    } else if (oldPrice.length > 11) {
      width = 150;
    } else if (oldPrice.length > 8) {
      width = 125;
    } else if (oldPrice.length > 5) {
      width = 100;
    }
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          oldPrice != price && discountPercent > 0
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      oldPrice,
                      textAlign: textAlign,
                      style: MyThemes.txtStyle(
                        textDecoration: isDeleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        fontSize: 2.2,
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            isDeleted ? FontStyle.italic : FontStyle.normal,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                    Container(
                      height: 2,
                      width: width,
                      color: Colors.red,
                    )
                  ],
                )
              : const SizedBox(),
          Text(
            price,
            textAlign: textAlign,
            style: MyThemes.txtStyle(
              textDecoration:
                  isDeleted ? TextDecoration.lineThrough : TextDecoration.none,
              fontSize: 2.2,
              fontWeight: FontWeight.bold,
              fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
              color: Theme.of(context).canvasColor,
            ),
          ),
        ],
      ),
    );
  }
}
