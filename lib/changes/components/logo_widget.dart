import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

import '../../app/theme_bloc/theme_mode_bloc.dart';

// ignore: must_be_immutable
class LogoInvanWidget extends StatelessWidget {
  double? width;
  Color? color;

  LogoInvanWidget({this.width, this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeModeBloc, ThemeModeState>(
      builder: (context, state) {
        if (state is ThemeModeInitial) {
          if (state.isDark) {
            return Image.asset(
              "assets/images/invan_logo.png",
              width: width,
              color: color ?? MyThemes.textWhiteColor,
            );
          } else {
            return Image.asset(
              "assets/images/invan_logo.png",
              width: width,
              color: color ?? Theme.of(context).primaryColor,
            );
          }
        }
        return Image.asset(
          "assets/images/invan_logo.png",
          width: width,
          color: color ??
              (Pref.getBool(PrefKeys.isDarkMode, true)
                  ? MyThemes.textWhiteColor
                  : Theme.of(context).primaryColor),
        );
      },
    );
  }
}
