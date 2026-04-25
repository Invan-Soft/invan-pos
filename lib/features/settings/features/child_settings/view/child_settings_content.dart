// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/settings/bloc/settings_bloc.dart';
import 'package:invan2/features/settings/features/child_settings/dialogs/before_log_out_dialog.dart';
import 'package:invan2/features/settings/features/child_settings/view/double_receipt.dart';
import 'package:invan2/features/settings/features/child_settings/view/drop_down_button_of_auto_sync.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import '../../../../../changes/services/api.dart';
import '../../../../../changes/services/api/result_http_model.dart';
import '../../../../../changes/services/log_service.dart';
import '../../../../../utils/helpers/auth_backup.dart';
import 'item_list_tile.dart';
import '../dialogs/language_dialog.dart';
import '../dialogs/tarozi_prefix_dialog.dart';
import 'package:invan2/utils/utils.dart';

class ChildSettingsContent extends StatefulWidget {
  const ChildSettingsContent({Key? key}) : super(key: key);

  @override
  State<ChildSettingsContent> createState() => _ChildSettingsContentState();
}

class _ChildSettingsContentState extends State<ChildSettingsContent> {
  late bool autoUpdate;
  late bool doubleReceipt;
  late bool virtualKeyboard;
  late bool printerRequired;
  late bool withOfd;

  @override
  void initState() {
    autoUpdate = Pref.getBool(PrefKeys.isAutoSyncActive, false);
    doubleReceipt = Pref.getBool(PrefKeys.doubleReceipt, false);
    virtualKeyboard = Pref.getBool(PrefKeys.virtualKeyboard, false);
    printerRequired = Pref.getBool(PrefKeys.printerRequired, false);
    withOfd = Pref.getBool(PrefKeys.withOFD, false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    doubleReceipt = Pref.getBool(PrefKeys.doubleReceipt, false);
    autoUpdate = Pref.getBool(PrefKeys.isAutoSyncActive, false);
    virtualKeyboard = Pref.getBool(PrefKeys.virtualKeyboard, false);
    printerRequired = Pref.getBool(PrefKeys.printerRequired, false);
    final loc = AppLocalizations.of(context)!;
    SettingsBloc settingsBloc = BlocProvider.of(context);
    return Column(
      children: [
        ItemListTile(
          text: loc.til,
          onPress: () {
            showDialog(
              context: context,
              builder: (_) => const LanguageDialog(),
            );
          },
        ),
        ItemListTile(
          text: loc.taroziUchunPrefix,
          onPress: () {
            showDialog(
              context: context,
              builder: (_) => const TaroziPrefixDialog(),
            );
          },
        ),
        ItemListTile(
          text: loc.tizimdanChiqish,
          onPress: () async {
            // Closed cashBox
            if (Pref.getBool(PrefKeys.shiftsOpened, false)) {
              showDialog(
                context: context,
                builder: (_) => const BeforeLogOutDialog(isAboutShift: true),
              );
            } else {
              HttpResult httpResult = await ShiftApi4.closeCashBox();
              if (!httpResult.isSuccess) {
                showDialog(
                  context: context,
                  builder: (_) => const BeforeLogOutDialog(isAboutShift: true),
                );
              } else {
                await Pref.setBool(PrefKeys.authenticationBool, false);
                await AuthBackup.delete();
                await HiveBoxes.clearAllBoxes();
                await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
                await Pref.setString(PrefKeys.version,
                    await LogService.getAppVersion() as String);
                AppNavigation.pushAndRemoveUntil(const PhoneNumberPage());
              }
            }
          },
        ),
        // ItemListTile(
        //   text: "Reports",
        //   onPress: () => settingsBloc.add(SettingsCallReportsEvent()),
        // ),
        // ItemListTile(
        //   text: "Http requests",
        //   onPress: () => AppNavigation.showAliceInspector(),
        // ),

        /////////////////qidir kerak/////////////////////
        /*DropdownOfAutoSync(
          activ: autoUpdate,
          onChanged: (v) async {
            int interval = Pref.getInt(PrefKeys.autoSyncInterval, 0);
            if (v) {
              if (3600000 <= interval) {
                await Pref.setBool(PrefKeys.isAutoSyncActive, v);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  mySnackBar(
                    context,
                    msg: loc.intervalni_tanlang,
                  ),
                );
              }
              setState(() {});
              return;
            } else {
              await Pref.setBool(PrefKeys.isAutoSyncActive, v);
              setState(() {});
              return;
            }
          },
        ),
        SettingSwitchListTile(
          title: "Double receipt",
          activ: doubleReceipt,
          onChanged: (v) async {
            await Pref.setBool(PrefKeys.doubleReceipt, v);
            setState(() {});
          },
        ),
        SettingSwitchListTile(
          title: "Virtual keyboard",
          activ: virtualKeyboard,
          onChanged: (v) async {
            await Pref.setBool(PrefKeys.virtualKeyboard, v);
            setState(() {});
          },
        ),*/
        // SettingSwitchListTile(
        //   title: "Printer required",
        //   activ: printerRequired,
        //   onChanged: (v) async {
        //     await Prefs.setBool(PrefKeys.printerRequired, v);
        //     setState(() {});
        //   },
        // ),
        // SettingSwitchListTile(
        //   title: "With OFD",
        //   activ: withOfd,
        //   onChanged: (v) async {

        //     if (Prefs.getBool(PrefKeys.shiftsOpened, false)) {
        //       return;
        //     }

        //     withOfd = v;
        //     await Prefs.setBool(PrefKeys.withOFD, v);
        //     setState(() {});
        //   },
        // ),
      ],
    );
  }
}
