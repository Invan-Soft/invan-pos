import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../changes/providers/return_page_provider.dart';
import '../../../../utils/l10n/app_localizations.dart';
import 'build_left_list.dart';

class Left extends StatelessWidget {
  const Left({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final returnPageProvider = Provider.of<ReturnPageProviderr>(context);
    final receipt = returnPageProvider.getReceipt;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: SizeConfig.v * 3,
            bottom: SizeConfig.v * 1,
            left: SizeConfig.h * 1.5,
          ),
          child: Text(
            '${loc.chek} ${receipt.externalId}',
            style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
                fontWeight: FontWeight.bold),
          ),
        ),
        Divider(
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Padding(
          padding: EdgeInsets.only(left: SizeConfig.h * 1.5),
          child: Text(
            loc.qaytishUchunTovarniBosing,
            style: MyThemes.txtStyle(
              fontSize: 1.9,
              color: Colors.grey,
            ),
          ),
        ),
        Divider(
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
      const   Expanded(
          child: BuildLeftList(),
        ),
        Divider(
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.h * 1.5,
            top: SizeConfig.v * 1,
            right: SizeConfig.h * 1.5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                loc.soliqlar,
                style: MyThemes.txtStyle(
                  fontSize: 2.3,
                  color:Theme.of(context).canvasColor,
                ),
              ),
              Text(
                '_ . _ _',
                style: MyThemes.txtStyle(
                  fontSize: 2.3,
                  color:Theme.of(context).canvasColor,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.h * 1.5,
            top: SizeConfig.v,
            bottom: SizeConfig.v * 6,
            right: SizeConfig.h * 1.5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                loc.jami,
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 2.3,
                  color: Theme.of(context).canvasColor,
                ),
              ),
              Text(
                // returnPageProvider.getLeftTotalPrice.toStringAsFixed(2),
                MoneyFormatter.formatVat
                    .format(returnPageProvider.getLeftTotalPrice),
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 2.3,
                  color:Theme.of(context).canvasColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
