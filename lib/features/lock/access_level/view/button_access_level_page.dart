import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class AccessLevelButton extends StatelessWidget {
  final bool selected;
  final String title;
  final VoidCallback onPressed;
  const AccessLevelButton(
      {required this.onPressed,
      required this.selected,
      required this.title,
      super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.v * 1.1)),
      onPressed: onPressed,
      height: SizeConfig.v * 9,
      minWidth: SizeConfig.h * 45.5,
      color:
          selected ? MyThemes.darkPrimaryColor : MyThemes.lightGreyColorr,
      child: Text(
        title,
        style: MyThemes.txtStyle(
          fontWeight: FontWeight.w500,
          fontSize: 3.15,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
