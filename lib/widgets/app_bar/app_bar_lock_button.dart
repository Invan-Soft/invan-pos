import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class AppBarLockButton extends StatelessWidget {
  const AppBarLockButton({
    Key? key,
    required this.onPress,
    required this.color,
  }) : super(key: key);

  final VoidCallback onPress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      height: SizeConfig.v * 10,
      minWidth: SizeConfig.h * 5,
      color: color,
      onPressed: onPress,
      elevation: 0,
      child: Image.asset("assets/images/lock.png",scale: .8,color: Theme.of(context).canvasColor,),
    );
  }
}
