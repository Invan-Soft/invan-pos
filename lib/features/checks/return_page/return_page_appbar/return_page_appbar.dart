import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../utils/l10n/app_localizations.dart';

class ReturnPageAppbar extends StatelessWidget {
  const ReturnPageAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      color: Theme.of(context).colorScheme.background,
      height: SizeConfig.v * 9.5,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MaterialButton(
            focusNode: FocusNode(skipTraversal: true),
            height: double.infinity,
            minWidth: SizeConfig.v * 9.5,
            color: Theme.of(context).colorScheme.background,
            onPressed: () {
              // AppNavigation.pushReplacement(const ChecksPage());
              AppNavigation.pop();
            },
            elevation: 0,
            child: Center(
              child: Icon(
                Icons.arrow_back_ios_outlined,
                size: SizeConfig.v * 4,
                color: Theme.of(context).canvasColor,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.h * 2),
          Text(
            loc.qaytarish,
            style: MyThemes.txtStyle(
              color: Theme.of(context).canvasColor,
              fontWeight: FontWeight.bold,
              fontSize: 3,
            ),
          ),
        ],
      ),
    );
  }
}
