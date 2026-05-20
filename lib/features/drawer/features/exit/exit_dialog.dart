import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../utils/l10n/app_localizations.dart';

class ExitDialog {
  static void showMyDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (_) => Theme(
        data: ThemeData.dark(),
        child: CupertinoAlertDialog(
          title: Text(
            loc.ilovadanChiqish,
            style: MyThemes.txtStyle(
              color: MyThemes.textWhiteColor,
            ),
          ),
          actions: [
            CupertinoButton(
              child: Text(
                loc.yoq,
                style: MyThemes.txtStyle(
                  color: MyThemes.textWhiteColor,
                ),
              ),
              onPressed: () => AppNavigation.pop(),
            ),
            CupertinoButton(
              child: Text(
                loc.ha,
                style: MyThemes.txtStyle(
                  color: MyThemes.textWhiteColor,
                ),
              ),
              onPressed: () => exit(0),
            ),
          ],
        ),
      ),
    );
  }
}
