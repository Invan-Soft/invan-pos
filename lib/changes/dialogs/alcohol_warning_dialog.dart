import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';

class CashPaymentWarningDialog extends StatelessWidget {
  const CashPaymentWarningDialog({super.key});

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
          boxShadow: const [BoxShadow(color: Colors.amber, blurRadius: 100)],
          color: MyThemes.darkBackgroundColor,
          borderRadius: BorderRadius.circular(SizeConfig.v * 1.1),
        ),
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  loc.naqd_tolov_mumkin_emas,
                  textAlign: TextAlign.center,
                  style: MyThemes.txtStyle(
                    color: MyThemes.textWhiteColor,
                    fontSize: 4,
                  ),
                ),
              ),
            ),
            DefaultButton(
              text: "OK",
              isButtonEnabled: true,
              onPress: () => AppNavigation.pop(),
              okButton: true,
            ),
          ],
        ),
      ),
    );
  }
}
