import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class LeftSideItem extends StatelessWidget {
  const LeftSideItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.isSelected,
    this.onPress,
  }) : super(key: key);

  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: isSelected
          ? Theme.of(context).canvasColor
          : Theme.of(context).primaryColorDark.withOpacity(.2),
      contentPadding: EdgeInsets.symmetric(
        horizontal: SizeConfig.h * 3,
        vertical: SizeConfig.v * 1.8,
      ),
      onTap: onPress,
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).canvasColor : Colors.blueGrey,
        size: SizeConfig.v * 5,
      ),
      title: Text(
        text,
        style: MyThemes.txtStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
          color: isSelected ? Theme.of(context).canvasColor : Colors.blueGrey,
          fontSize: 3,
        ),
      ),
    );
  }
}
