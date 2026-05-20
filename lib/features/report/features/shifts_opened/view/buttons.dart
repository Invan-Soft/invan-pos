import 'package:flutter/material.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'button.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import '../smena_yopish_dialog.dart';

class Buttons extends StatelessWidget {
  final bool isZet;
  const Buttons({required this.isZet, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.h * 2.5,
        vertical: SizeConfig.v * 5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Button(
          //   text: loc.naqdPulniBoshqarish.toUpperCase(),
          //   onPressed: () {
          //     AppNavigation.pushReplacement(RuleCashPage(isZet: isZet));
          //   },
          // ),
          SizedBox(width: SizeConfig.h * 2.5),
          isZet
              ? Button(
                  text: loc.smenaniYopish.toUpperCase(),
                  onPressed: () {
                    bool canAccessToShift =
                        HiveBoxes.getCurrentEmployee?.access?.openShift ??
                            false;
                    if (canAccessToShift) {
                      // Provider.of<OpenShiftProvider>(context, listen: false)
                      //     .setPrintReportFalse();
                      ShiftModelHive shift = HiveBoxes.getShifts()
                          .get(Pref.getInt(PrefKeys.currentShiftKey, -1))!;                          
                      showDialog(
                        context: context,
                        builder: (context) => CloseShiftDialog(shiftt: shift),
                      );
                    }
                  },
                )
              : const SizedBox(
                  height: 0.0,
                  width: 0.0,
                ),
        ],
      ),
    );
  }
}
