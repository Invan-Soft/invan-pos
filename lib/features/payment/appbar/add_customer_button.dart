import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';

class AddCustomerButton extends StatelessWidget {
  const AddCustomerButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return MaterialButton(
      focusNode: FocusNode(skipTraversal: true),
      elevation: 0,
      height: double.infinity,
      minWidth: SizeConfig.h * 20,
      color: Theme.of(context).primaryColor,
      onPressed: onPressed,
      child: Text(
        loc.mijozQoshish,
        style: MyThemes.txtStyle(
          color: Colors.white,
          fontSize: 3,
        ),
      ),
    );
  }
}
