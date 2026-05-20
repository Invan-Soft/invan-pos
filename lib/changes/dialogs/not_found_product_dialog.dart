import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/themes.dart';

import '../../utils/constants/constants.dart';
import '../../utils/helpers/helpers.dart';

class NotFoundProductDialog extends StatelessWidget {
  final VoidCallback onOKButtonPressed;
  final VoidCallback onCreateButtonPressed;

  const NotFoundProductDialog({
    super.key,
    required this.onOKButtonPressed,
    required this.onCreateButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    bool autoGenerate = Pref.getBool(PrefKeys.autoGenerate, false);
    return Theme(
      data: ThemeData.dark(),
      child: CupertinoAlertDialog(
        title: Text(
          loc.bu_belgi_bilan_mahsulot_mavjud_emas,
          style: MyThemes.txtStyle(
            color: MyThemes.textWhiteColor,
          ),
        ),
        actions: !autoGenerate
            ? [
                CupertinoButton(
                  onPressed: onOKButtonPressed,
                  child: const Text(
                    'Ok',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ]
            : [
                CupertinoButton(
                  onPressed: onCreateButtonPressed,
                  child: Text(
                    loc.yaratish,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                CupertinoButton(
                  onPressed: onOKButtonPressed,
                  child: Text(
                    loc.bekor_qilish,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
      ),
    );
  }
}
