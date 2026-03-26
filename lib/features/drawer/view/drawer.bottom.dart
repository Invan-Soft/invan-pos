import 'package:flutter/material.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import '../../../changes/services/app_constants.dart';
import '../../../utils/constants/pref_keys.dart';
import '../../../utils/themes.dart';

class DrawerBottom extends StatelessWidget {
  const DrawerBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.h * 2, horizontal: SizeConfig.h * 3),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Versiya raqam: ${Pref.getString(PrefKeys.version, '')}',
              textAlign: TextAlign.right,
              style:
                  MyThemes.txtStyle(fontSize: 1.8, color: Colors.grey.shade600),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Seriya raqam: ${Pref.getString(PrefKeys.serialNumber, "")}',
              textAlign: TextAlign.right,
              style:
                  MyThemes.txtStyle(fontSize: 1.8, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
