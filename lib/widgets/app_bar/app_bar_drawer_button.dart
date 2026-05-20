import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class AppBarDrawerButton extends StatelessWidget {
  const AppBarDrawerButton({
    Key? key,
    required this.onPress,
    required this.color,
  }) : super(key: key);

  final VoidCallback onPress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      focusNode: FocusNode(skipTraversal: true),
      style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.background),

      onPressed: onPress,
      // color: color,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.h),
        child: Center(
            child: Image.asset(
          "assets/images/drawerIcon.png",
          color: Theme.of(context).canvasColor,
        )),
      ),
    );
  }
}
