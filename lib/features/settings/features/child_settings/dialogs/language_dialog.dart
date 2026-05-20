import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/providers/language_provider.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:provider/provider.dart';

class LanguageDialog extends StatelessWidget {
  const LanguageDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final LanguageProvider languageProvider =
        Provider.of<LanguageProvider>(context);
    final chosenLanguage = languageProvider.getLanguage;

    return AlertDialog(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      title: Text(
        loc.tilniTanlang,
        style: MyThemes.txtStyle(
          color: Theme.of(context).canvasColor,
          fontSize: 2.6,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildItem(
            context,
            chosenLanguage == 0,
            loc.russkiy,
            () {
              languageProvider.changeLanguage(0);
         AppNavigation.pop();
            },
          ),
          buildItem(
            context,
            chosenLanguage == 1,
            loc.ozbek,
            () {
              languageProvider.changeLanguage(1);
           AppNavigation.pop();
            },
          ),
        ],
      ),
    );
  }

  Widget buildItem(
    BuildContext context,
    bool isChosen,
    String lan,
    VoidCallback onPress,
  ) {
    return ListTile(
      onTap: onPress,
      leading: isChosen
          ? Icon(
              Icons.check_box,
              color: Theme.of(context).primaryColor,
            )
          : const Icon(
              Icons.check_box_outline_blank,
              color: Colors.black54,
            ),
      title: Text(
        lan,
        style: MyThemes.txtStyle(
          fontSize: 2.6,
          fontWeight: FontWeight.bold,
          color: isChosen ? Theme.of(context).canvasColor : Theme.of(context).canvasColor.withOpacity(.5),
        ),
      ),
    );
  }
}
