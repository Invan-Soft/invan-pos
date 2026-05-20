import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/settings/bloc/settings_bloc.dart';
import 'package:invan2/features/settings/view/dark_mode_item.dart';
import '../../../app_navigation.dart';
import 'left_side_item.dart';
import 'package:invan2/features/features.dart';

class LeftSide extends StatefulWidget {
  final int index;

  const LeftSide({required this.index, Key? key}) : super(key: key);

  @override
  State<LeftSide> createState() => _LeftSideState();
}

class _LeftSideState extends State<LeftSide> {
  bool isRepostClick = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    SettingsBloc settingsBloc = BlocProvider.of(context);
    return Column(
      children: [
        LeftSideItem(
          icon: Icons.print,
          text: loc.printerlar,
          isSelected: widget.index == 0 && !isRepostClick,
          onPress: () {
            isRepostClick = false;
            setState(() {});
            settingsBloc.add(SettingsLeftItemPressedEvent(0));
          },
        ),
        LeftSideItem(
          icon: Icons.settings,
          text: loc.sozlamalar,
          isSelected: widget.index == 1 && !isRepostClick,
          onPress: () {
            isRepostClick = false;
            setState(() {});
            settingsBloc.add(SettingsLeftItemPressedEvent(1));
          },
        ),
        InkWell(
          onTap: () {
            isRepostClick = true;
            setState(() {});
            settingsBloc.add(SettingsCallReportsEvent());
          },
          child: LeftSideItem(
            icon: Icons.report_gmailerrorred_outlined,
            text: loc.ha =="Ha"?"Hisobotlar":"Отчёты",
            isSelected: isRepostClick,
          ),
        ),
        /*LeftSideItem(
          icon: Icons.ads_click,
          text: loc.click_pass,
          isSelected: index == 2,
          onPress: () {
            settingsBloc.add(SettingsLeftItemPressedEvent(2));
          },
        ),*/
        LeftSideItem(
          icon: Icons.credit_card,
          text: loc.terminal,
          isSelected: widget.index == 3 && !isRepostClick,
          onPress: () {
            isRepostClick = false;
            setState(() {});
            settingsBloc.add(SettingsLeftItemPressedEvent(3));
          },
        ),
        LeftSideItem(
          icon: Icons.api,
          text:loc.ha == "Ha" ?"HTTP so'rovlar":"HTTP запросы",
          isSelected: widget.index == 4,
          onPress: () => AppNavigation.showAliceInspector(),
        ),
        /*LeftSideItem(
          icon: Icons.credit_card,
          text: "Payme Go",
          isSelected: index == 4,0
          onPress: () {
            settingsBloc.add(SettingsLeftItemPressedEvent(4));
          },
        ),
        LeftSideItem(
          icon: Icons.credit_card,
          text: "UZUM",
          isSelected: index == 5,
          onPress: () {
            settingsBloc.add(SettingsLeftItemPressedEvent(5));
          },
        ),*/
        const Spacer(),
        const DarkModeItem(),
      ],
    );
  }
}
