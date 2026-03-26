import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class TextInRowHomeBottomSide extends StatelessWidget {
  final String text1;
  final String text2;
  const TextInRowHomeBottomSide({
    Key? key,
    required this.text1,
    required this.text2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text1,
          style: MyThemes.txtStyle(
            fontSize: 1.56,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).canvasColor,
          ),
        ),
        SizedBox(width: SizeConfig.h * 3),
        Text(
          text2,
          style: MyThemes.txtStyle(
            fontStyle: FontStyle.italic,
            fontSize: 1.56,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).canvasColor,
          ),
        ),
      ],
    );
  }
}
