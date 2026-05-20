import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/ofd/incom_response_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:provider/provider.dart';

import '../../providers/ordering_provider_4.dart';

class MxikErrorDialog extends StatefulWidget {
  final List<NoMxikItem> items;

  const MxikErrorDialog({
    required this.items,
    super.key,
  });

  @override
  State<MxikErrorDialog> createState() => _MxikErrorDialogState();
}

class _MxikErrorDialogState extends State<MxikErrorDialog> {
  bool isWaiting = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Pref.getBool(PrefKeys.isDarkMode, true)
        ? Theme.of(context).dialogBackgroundColor
        : MyThemes.lightGreyColorr;
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.h * 3),
        width: SizeConfig.h * 53,
        height: SizeConfig.v * 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
        ),
        child: Material(
          color: bgColor,
          child: Column(
            children: [
              Text(
                "${loc.quiyidagi_mahsulotlarda_mxik_xatoliklar_mavjud}:",
                style: MyThemes.txtStyle(
                  color: MyThemes.textWhiteColor,
                  fontSize: 3.5,
                ),
              ),
              Expanded(
                child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.v),
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    itemBuilder: (_, __) {
                      return ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SizeConfig.v)),
                        tileColor: MyThemes.textWhiteColor,
                        title: Text(
                          widget.items[__].name!,
                          style: MyThemes.txtStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          widget.items[__].barode!,
                          style: MyThemes.txtStyle(fontStyle: FontStyle.italic),
                        ),
                        trailing: Text(
                          widget.items[__].classCode!,
                          style: MyThemes.txtStyle(fontStyle: FontStyle.italic),
                        ),
                      );
                    }),
              ),
              isWaiting
                  ? SizedBox(
                      height: SizeConfig.v * 7.55,
                      child: const CupertinoActivityIndicator(),
                    )
                  : DefaultButton(
                      text: "Ok",
                      isButtonEnabled: true,
                      onPress: () async {
                        isWaiting = true;
                        await Provider.of<OrderingProvider4>(context,
                                listen: false)
                            .onMxikError(widget.items);
                        AppNavigation.pop();
                      },
                    )
            ],
          ),
        ),
      ),
    );
  }
}
