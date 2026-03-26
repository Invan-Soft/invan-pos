import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

class SdachaDialog extends StatelessWidget {
  final String sdacha;
  const SdachaDialog(this.sdacha, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return AlertDialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: EdgeInsets.zero,
        alignment: Alignment.center,
        width: SizeConfig.h * 40.58,
        height: SizeConfig.v * 75.7,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(
            SizeConfig.v * 1.1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/bgSdacha.png",
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "${loc.sdacha}:",
                    style: MyThemes.txtStyle(
                        color: MyThemes.textWhiteColor, fontSize: 4),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        MoneyFormatter.inputMoneyFormatter
                            .format(double.parse(sdacha)),
                        style: MyThemes.txtStyle(
                          color: MyThemes.textWhiteColor,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        " ${loc.som}",
                        style: MyThemes.txtStyle(
                          color: MyThemes.textWhiteColor,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(),
                  TextButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      AppNavigation.pop();
                      await Future.delayed(Duration.zero);
                      AppNavigation.pop();
                    },
                    style: TextButton.styleFrom(
                      shadowColor: Theme.of(context).dialogBackgroundColor,
                      foregroundColor: Theme.of(context).dialogBackgroundColor,
                      elevation: 0,
                    ),
                    child: Image.asset(
                      "assets/images/sdacha.png",
                      alignment: const Alignment(0.0, .5),
                    ),
                  ),
                  Text(
                    loc.mijozga_qaytimini_bering_va_tekshiring,
                    textAlign: TextAlign.center,
                    style: MyThemes.txtStyle(
                      color: MyThemes.textWhiteColor,
                      fontSize: 3.8,
                    ),
                  ),
                  ElevatedButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      AppNavigation.pop();
                      await Future.delayed(Duration.zero);
                      AppNavigation.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: MyThemes.textWhiteColor,
                          width: SizeConfig.v * .25,
                        ),
                        borderRadius: BorderRadius.circular(
                          SizeConfig.v * 1.3,
                        ),
                      ),
                      fixedSize: Size(
                        SizeConfig.h * 11.56,
                        SizeConfig.v * 6.6,
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: MyThemes.textWhiteColor,
                        fontSize: SizeConfig.v * 4.13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
