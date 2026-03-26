import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart';

class PayWithCashButton extends StatelessWidget {
  const PayWithCashButton({
    Key? key,
    required this.isEnabled,
    required this.onPressed,
  }) : super(key: key);

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      minWidth: SizeConfig.h * 6,
      height: SizeConfig.v * 8.6,
      onPressed: isEnabled ? onPressed : null,
      color: Theme.of(context).primaryColor,
      disabledColor: Theme.of(context).primaryColor.withOpacity(.5),
      child: Icon(
        Icons.money,
        color: Colors.white,
        size: SizeConfig.v * 5,
      ),
    );
  }
}
