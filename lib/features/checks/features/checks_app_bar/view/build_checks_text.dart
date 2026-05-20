import 'package:flutter/material.dart';
import 'package:invan2/utils/utils.dart' show MyThemes, SizeConfig;

import '../../../../../utils/l10n/app_localizations.dart';

class BuildChecksText extends StatelessWidget {
  const BuildChecksText({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: SizeConfig.h * 2),
        child: Text(
          loc.cheklar,
          style: MyThemes.txtStyle(
            color: Theme.of(context).canvasColor,
            fontWeight: FontWeight.bold,
            fontSize: 3.2,
          ),
        ),
      ),
    );
  }
}
