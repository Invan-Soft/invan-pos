import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../../../changes/providers/operation_on_product_provider.dart';
import '../../../../widgets/my_snackbar.dart';
import '../../../hive_repository/hive_boxes.dart';
import 'delete_item/input_alert_dialog.dart';

class OPDBottom extends StatelessWidget {
  const OPDBottom({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.h * 1.95,
        right: SizeConfig.h * 1.95,
        bottom: SizeConfig.v * 1.43,
      ),
      child: Row(
        children: [
          Expanded(
            child: MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  SizeConfig.v * 1.1,
                ),
              ),
              onPressed: () async {
                Employee currentEmployee = HiveBoxes.getCurrentEmployee!;

                if ((currentEmployee.access?.deletePrice ?? false)) {
                  Provider.of<OrderingProvider4>(context, listen: false)
                      .pressDialogDeleteButton();
                  AppNavigation.pop();
                } else {
                  await showDialog(
                    context: context,
                    builder: (_) => InputAlertDialog(
                      onUniversalPinEntered: () {},
                      onValueEntered: (employee) {
                        Provider.of<OrderingProvider4>(context, listen: false)
                            .pressDialogDeleteButton();
                        AppNavigation.pop();
                        AppNavigation.pop();
                      },
                    ),
                  );
                }
              },
              height: SizeConfig.v * 6.18,
              color: Colors.red,
              disabledColor: Colors.red.withOpacity(.5),
              child: Text(
                loc.ochirish,
                style: MyThemes.txtStyle(color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: SizeConfig.h * 2),
          Expanded(
            child: MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              onPressed: () {
                if (Pref.getString(PrefKeys.innLength, "").length == 9 ||
                    Pref.getString(PrefKeys.innLength, "").length == 14 ||
                    Pref.getString(PrefKeys.innLength, "") == '') {
                  context
                      .read<OperationOnProductProvider>()
                      .onSaveButtonPressed(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    mySnackBar(context,
                        msg: "ИНН комитента состоит из 9 или 14 цифр",
                        duration: 1000),
                  );
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  SizeConfig.v * 1.1,
                ),
              ),
              height: SizeConfig.v * 6.18,
              color: Theme.of(context).primaryColor,
              disabledColor: Theme.of(context).primaryColor.withOpacity(.5),
              child: Text(
                loc.saqlash,
                style: MyThemes.txtStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
