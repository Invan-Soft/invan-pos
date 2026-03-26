import 'package:flutter/material.dart';
import 'package:invan2/utils/themes.dart';

class RowTextClintSearch extends StatelessWidget {
 final String str1;
 final String str2;
  const RowTextClintSearch(this.str1,this.str2,   {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          str1,
          style: MyThemes.txtStyle(color: Theme.of(context).canvasColor, fontSize: 2),
        ),
        Text(
          str2,
          style:MyThemes.txtStyle(color: Theme.of(context).canvasColor,fontSize: 2.5),
        )
      ],
    );
  }
}
