import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/widgets.dart';

class BeforeLogOutDialog extends StatelessWidget {
  final bool isAboutShift;
  const BeforeLogOutDialog({Key? key, required this.isAboutShift})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return isAboutShift? AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      content: SizedBox(
        height: SizeConfig.v * 40,
        width: SizeConfig.h * 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tizimdanChiqishdanOldin,
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
                fontWeight: FontWeight.bold,
                fontSize: 3,
              ),
            ),
            Text(
              loc.ochiqSmenaniYopish,
              style: MyThemes.txtStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 2.5,
              ),
            ),
            Expanded(child: Container()),
            DefaultButton(
              text: loc.cancel.toUpperCase(),
              onPress: () => AppNavigation.pop(),
              isErrorButton: false,
              isButtonEnabled: true,
            ),
          ],
        ),
      ),
    ): AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      content: SizedBox(
        height: SizeConfig.v * 40,
        width: SizeConfig.h * 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
           
            Expanded(child:  Align(
              alignment: Alignment.center,
              child: Text(
                loc.tizimdan_chiqish_imkonsiz,
                textAlign: TextAlign.center,
                style: MyThemes.txtStyle(
                  color: Theme.of(context).canvasColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 3,
                ),
              ),
            ),),
            DefaultButton(
              text: loc.cancel.toUpperCase(),
              onPress: () => AppNavigation.pop(),
              isErrorButton: false,
              isButtonEnabled: true,
            ),
          ],
        ),
      ),
    );
  }
}
