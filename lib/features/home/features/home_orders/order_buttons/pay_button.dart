import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';

class PayButton extends StatelessWidget {
  const PayButton({
    Key? key,
    required this.isEnabled,
    required this.onPressed,
  }) : super(key: key);

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      minWidth: SizeConfig.h * 11.0,
      height: SizeConfig.v * 8.6,
      onPressed: isEnabled ? onPressed : null,
      color: Theme.of(context).primaryColor,
      disabledColor: Theme.of(context).primaryColor.withOpacity(.5),
      child: Text(
        loc.tolash_oplatit,
        style: MyThemes.txtStyle(color: Colors.white, fontSize: 2.4),
      ),
    );
  }
}
