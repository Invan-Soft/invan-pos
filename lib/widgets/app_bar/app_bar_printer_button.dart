import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class AppBarPrinterButton extends StatelessWidget {
  const AppBarPrinterButton({
    Key? key,
    required this.onPress,
  }) : super(key: key);

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      height: double.infinity,
      minWidth: SizeConfig.h * 8,
      color: Theme.of(context).primaryColor,
      onPressed: onPress,
      elevation: 0,
      child: Center(
        child: Icon(
          Icons.print,
          size: SizeConfig.v * 5,
          color: Colors.white,
        ),
      ),
    );
  }
}
