import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class RuleCashbutton extends StatelessWidget {
  const RuleCashbutton({
    Key? key,
    required this.isEnabled,
    required this.onPressed,
    required this.title,
  }) : super(key: key);
  final bool isEnabled;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    bool isPrimaryColored = loc.kirim == title;
    return Expanded(
      child: MaterialButton(
        focusNode: FocusNode(skipTraversal: true),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            SizeConfig.v,
          ),
        ),
        onPressed: isEnabled ? onPressed : null,
        minWidth: double.infinity,
        height: SizeConfig.v * 7,
        color:isPrimaryColored?Theme.of(context).primaryColor: Colors.red.withOpacity(.9),
        disabledColor:isPrimaryColored?Theme.of(context).primaryColor.withOpacity(.5): Colors.red.withOpacity(.6),
        child: Text(
          title.toUpperCase(),
          style: MyThemes.txtStyle(
            color:Colors.white,
            fontSize: 2.8,
          ),
        ),
      ),
    );
  }
}
