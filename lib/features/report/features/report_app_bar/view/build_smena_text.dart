import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/components/logo_widget.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';
import 'package:invan2/utils/utils.dart' show SizeConfig;

import '../../../../lock/access_level/bloc/access/access_bloc.dart';

class BackToButton extends StatelessWidget {
  const BackToButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 1.5),
      child: TextButton(
        focusNode: FocusNode(skipTraversal: true),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(0.0),
        ),
        onPressed: () {
          BlocProvider.of<AccessBloc>(context).add(AccessSwitchToAccessEvent());
          // AppNavigation.pop();
          AppNavigation.pushAndRemoveUntil(
            const AccessLevelPage(
                //     // configH: SizeConfig.h,
                //     // configV: SizeConfig.v,

                ),
          );
        },
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).canvasColor,
              size: SizeConfig.v * 3.4,
            ),
            SizedBox(width: SizeConfig.h),
            LogoInvanWidget(width: SizeConfig.h * 9)
          ],
        ),
      ),
    );
  }
}
