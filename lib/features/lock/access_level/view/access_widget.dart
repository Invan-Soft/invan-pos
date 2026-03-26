import 'package:flutter/material.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/features/lock/access_level/view/button_access_level_page.dart';
import 'package:invan2/features/lock/access_level/view/oclock.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';

class AccessWidget extends StatelessWidget {
  final AccessBloc lockBloc;

  const AccessWidget(this.lockBloc, {super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;

    List<String> items = [
      loc.sotuv,
      'X - ${loc.xisobot}',
      'Z - ${loc.xisobot}',
      loc.sozlamalar,
    ];
    if (Pref.getBool(PrefKeys.withOFD, false)) {
      items.add('OFD');
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ListView.separated(
          padding: EdgeInsets.only(
            top: SizeConfig.v * 2.7,
            left: SizeConfig.v * 2.85,
            right: SizeConfig.v * 2.85,
            bottom: SizeConfig.v * 3.57,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, __) {
            return AccessLevelButton(
              onPressed: () {
                if (__ == 1 || __ == 2) {
                  if (!Pref.getBool(PrefKeys.companyActive, false)) return;
                }
                lockBloc.add(LockSwitchToPinEvent(__));
              },
              selected: lockBloc.level == __,
              title: items[__],
            );
          },
          separatorBuilder: (context, index) {
            return SizedBox(height: SizeConfig.v * 1.93);
          },
        ),
        const OclockWidget(),
        SizedBox(height: SizeConfig.v * 1.78),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MyThemes.lightGreyColorr,
                borderRadius: BorderRadius.circular(SizeConfig.v * 0.7),
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.v, vertical: SizeConfig.v),
              child: Text(
                _dateFormatter(DateTime.now()),
                style: MyThemes.txtStyle(
                  fontSize: 2.85,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(),
        const SizedBox(),
        const SizedBox(),
        const SizedBox()
      ],
    );
  }

  String _dateFormatter(DateTime now) {
    return "${now.day} / ${now.month} / ${now.year}";
  }
}
