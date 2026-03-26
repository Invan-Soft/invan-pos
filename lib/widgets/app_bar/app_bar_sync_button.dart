import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class AppBarSyncButton extends StatelessWidget {
  const AppBarSyncButton({
    Key? key,
    required this.onPress,
  }) : super(key: key);

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      height: double.infinity,
      minWidth: SizeConfig.h * 5.6,
      color: Theme.of(context).colorScheme.background,
      onPressed: onPress,
      elevation: 0,
      child: Center(
        child: Icon(
          Icons.sync_rounded,
          size: SizeConfig.v * 4.5,
          color: Theme.of(context).canvasColor,
        ),
      ),
    );
  }
}
