import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';

class SettingsSubmitButtom extends StatelessWidget {
  final VoidCallback onSubmitted;
  const SettingsSubmitButtom({Key? key, required this.onSubmitted})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppLocalizations? loc = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 9),
      child: MaterialButton(
        focusNode: FocusNode(skipTraversal: true),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.all(SizeConfig.v * 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.v),
        ),
        disabledColor: Theme.of(context).dividerColor,
        color: Theme.of(context).primaryColor,
        onPressed: onSubmitted,
        child: Text(
          loc?.tasdiqlash ?? "Tasdiqlash",
          style: MyThemes.txtStyle(color: MyThemes.textWhiteColor),
        ),
      ),
    );
  }
}
