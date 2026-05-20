import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class AccessLevelButton extends StatelessWidget {
  const AccessLevelButton({
    Key? key,
    required this.text,
    required this.onPress,
  }) : super(key: key);

  final String text;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      onPressed: onPress,
      height: SizeConfig.v * 11,
      minWidth: SizeConfig.h * 40,
      color: Theme.of(context).primaryColor,
      child: Text(
        text,
        style: MyThemes.txtStyle(
          fontSize: 3,
          color: Colors.white,
        ),
      ),
    );
  }
}
