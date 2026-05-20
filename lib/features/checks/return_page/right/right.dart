import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/return_dialog.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../changes/providers/return_page_provider.dart';
import 'build_right_list.dart';
import 'build_right_button.dart';

class Right extends StatelessWidget {
  const Right({super.key});

  @override
  Widget build(BuildContext context) {
    ReturnBloc returnBloc = BlocProvider.of(context);
    final loc = AppLocalizations.of(context)!;

    final returnPageProvider = Provider.of<ReturnPageProviderr>(context);
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
            loc.qaytishCheki,
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
            loc.qaytarishniBekorQilishUchunTovarniBosing,
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
        const Expanded(child: BuildRightList()),
        Divider(
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.h * 1.5,
            top: SizeConfig.v * .5,
            bottom: SizeConfig.v * 1.4,
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
                MoneyFormatter.formatVat
                    .format(returnPageProvider.getRightTotalPrice),
                style: MyThemes.txtStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 2.3,
                  color: Theme.of(context).canvasColor,
                ),
              ),
            ],
          ),
        ),
        BuildRightButtonn(
          isEnabled: returnPageProvider.getRightList.isNotEmpty,
          onPressed: () async {
            ReceiptModel4 receiptModel4 = returnPageProvider.getReceipt;
            returnBloc.add(
              ReturnReturnEvent(
                isRetry: false,
                clientNumber: receiptModel4.clientPhone,
                receiptModel4: receiptModel4,
                rightList: returnPageProvider.getRightList,
                loc: loc,
              ),
            );
            await showGeneralDialog(
              context: context,
              pageBuilder: (context, x, y) {
                return ReturnDialog(
                  clientNumber: receiptModel4.clientPhone,
                  receiptModel4: receiptModel4,
                  rightList: returnPageProvider.getRightList,
                );
              },
            );
            AppNavigation.pop();
          },
        ),
      ],
    );
  }
}
