import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/services/customer_service.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/widgets.dart';

import '../../../../utils/l10n/app_localizations.dart';

// ignore: must_be_immutable
class FeedBackDialogWidget extends StatelessWidget {
  FeedBackDialogWidget({
    super.key,
  });

  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      content: Container(
        width: SizeConfig.h * 50,
        height: SizeConfig.v * 50,
        padding: EdgeInsets.all(SizeConfig.v * 2.5),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(SizeConfig.v),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  style:
                      MyThemes.txtStyle(color: Theme.of(context).canvasColor),
                  onChanged: (v) {},
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintStyle:
                        MyThemes.txtStyle(color: Theme.of(context).canvasColor),
                    hintText: loc.matnniKiriting,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: SizeConfig.v * 3),
            DefaultButton(
                text: loc.jonatish,
                isButtonEnabled: true,
                onPress: () {
                  CustomerSupportService.feedBackToHive(controller.text);
                  AppNavigation.pop();
                }),
          ],
        ),
      ),
    );
  }
}
