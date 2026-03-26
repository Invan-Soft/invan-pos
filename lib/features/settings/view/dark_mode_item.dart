import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app/theme_bloc/theme_mode_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:invan2/utils/themes.dart';

class DarkModeItem extends StatefulWidget {
  const DarkModeItem({Key? key}) : super(key: key);

  @override
  State<DarkModeItem> createState() => _DarkModeItemState();
}

class _DarkModeItemState extends State<DarkModeItem> {
  late bool isDark;
  @override
  void initState() {
    isDark = Pref.getBool(PrefKeys.isDarkMode, true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeModeBloc appBloc = BlocProvider.of(context, listen: false);
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.h * .5,
            vertical: SizeConfig.v * 1.5,
          ),
          onTap: () {},
          title: Padding(
            padding: EdgeInsets.only(left: SizeConfig.h * 2),
            child: Text(
              loc.dark_mode,
              style: MyThemes.txtStyle(
                  fontSize: 2.7, color: Theme.of(context).canvasColor),
            ),
          ),
          trailing: Padding(
            padding: EdgeInsets.only(right: SizeConfig.h * 2),
            child: CupertinoSwitch(
                value: isDark,
                onChanged: (v) async {
                  appBloc.add(ThemeChangedEvent(v));
                  await Pref.setBool(PrefKeys.isDarkMode, v);
                  isDark = v;
                  setState(() {});
                }),
          ),
        ),
        Container(
          width: double.infinity,
          height: 1,
          color: Theme.of(context).dividerColor,
        ),
      ],
    );
  }
}
