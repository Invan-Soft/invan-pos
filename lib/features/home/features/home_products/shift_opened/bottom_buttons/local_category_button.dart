import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class LocalCategoryButton extends StatelessWidget {
  const LocalCategoryButton({
    Key? key,
    required this.onPress,
    required this.text,
    required this.isSelected,
  }) : super(key: key);

  final VoidCallback onPress;
  final String text;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 3.0),
      width: SizeConfig.h * 12,
      height: SizeConfig.v * 9,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).bottomAppBarTheme.color,
            width: double.infinity,
            height: isSelected ? 3 : 0,
          ),
          Expanded(
            child: MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              onPressed: onPress,
              elevation: 0,
              color: Theme.of(context).dialogBackgroundColor,
              minWidth: double.infinity,
              height: double.infinity,
              child: Text(
                text,
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontSize: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
