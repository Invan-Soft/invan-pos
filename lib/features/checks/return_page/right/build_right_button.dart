import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';

class BuildRightButtonn extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isEnabled;
  const BuildRightButtonn({required this.onPressed,super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.h * 1.5,
        right: SizeConfig.h * 1.5,
        bottom: SizeConfig.v * 2,
      ),
      child: MaterialButton(
        focusNode: FocusNode(skipTraversal: true),
        onPressed:isEnabled
            ? onPressed
            :null,
        color: Theme.of(context).primaryColor,
        disabledColor: Theme.of(context).primaryColor.withOpacity(.6),
        height: SizeConfig.v * 8,
        minWidth: double.infinity,
        child: Text(
          loc.qaytarish.toUpperCase(),
          style: MyThemes.txtStyle(
            color: Colors.white,
            fontSize: 2.4,
          ),
        ),
      ),
    );
  }
}
