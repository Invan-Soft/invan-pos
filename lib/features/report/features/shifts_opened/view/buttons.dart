import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart';
import 'button.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import '../smena_yopish_dialog.dart';

class Buttons extends StatelessWidget {
  final bool isZet;
  const Buttons({required this.isZet, super.key});

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
                      // Smena yozuvini getCurrentHiveShift orqali olamiz: u
                      // summalarni ObjectBox cheklaridan qaytadan hisoblaydi va
                      // yozuv yo'qolgan bo'lsa (shifts.hive buzilgan) uni qayta
                      // tiklaydi. Shu sababli null bo'lmaydi (oldin .get(...)!
                      // null'da crash berib, tugma "ishlamay" qolardi) va dialog
                      // to'g'ri "kutilayotgan pul" qiymatini ko'rsatadi.
                      final shift = ShiftSingleton4.getCurrentHiveShift();
                      if (shift == null) return;
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
