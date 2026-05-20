import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';

import '../providers/ordering_provider_4.dart';

class ContainsNoMxikPackageItemDialogg extends StatefulWidget {
  final OrderingProvider4 provider;

  const ContainsNoMxikPackageItemDialogg({super.key, required this.provider});

  @override
  State<ContainsNoMxikPackageItemDialogg> createState() =>
      _ContainsNoMxikPackageItemDialoggState();
}

class _ContainsNoMxikPackageItemDialoggState
    extends State<ContainsNoMxikPackageItemDialogg> {
  final TextEditingController controller = TextEditingController();
  bool isWaiting = false;
  bool isOkButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        width: SizeConfig.h * 38.96,
        height: SizeConfig.v * 42.18,
        decoration: BoxDecoration(
          boxShadow: const [BoxShadow(color: Colors.red, blurRadius: 100)],
          color: MyThemes.darkBackgroundColor,
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  loc.ha == 'Ha'
                      ? 'Mxik kod va O\'lchov birligi bo\'sh bo\'lmasligi kerak!'
                      : 'Код МХИК и единица измерения не должны быть пустыми!',
                  textAlign: TextAlign.center,
                  style: MyThemes.txtStyle(
                    color: MyThemes.textWhiteColor,
                    fontSize: 4,
                  ),
                ),
              ),
            ),
            DefaultButton(
              text: "Ok",
              isButtonEnabled: true,
              onPress: () async {
                AppNavigation.pop();
              },
              isErrorButton: true,
            )
          ],
        ),
      ),
    );
  }
}
