// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import 'package:shell/shell.dart';
import 'package:windows1251/windows1251.dart';
import '../../../features.dart';
import '../components/settings_switch.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';
import 'package:file/local.dart' as fl;

class HumoContent extends StatefulWidget {
  const HumoContent({Key? key}) : super(key: key);

  @override
  State<HumoContent> createState() => _HumoContentState();
}

class _HumoContentState extends State<HumoContent> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    bool isEnabledHumo = Pref.getBool(PrefKeys.isHumoEnabled, false);
    bool isEnabledUzcard = Pref.getBool(PrefKeys.isUzcardEnabled, false);
    bool doubleReceipt = Pref.getBool(PrefKeys.doubleHumoReceipt, false);

    // bool isEnabled = Pref.getBool(PrefKeys.isHumoEnabled, false);

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.h * 10,
        vertical: SizeConfig.v * 3,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SettingsSwitch(
            isSubtitle: false,
            title: 'ХУМО Статус',
            value: isEnabledHumo,
            onChanged: (value) async {
              await Pref.setBool(PrefKeys.isHumoEnabled, value);
              setState(() {});
            },
          ),
          SizedBox(
            height: SizeConfig.v * 3,
          ),
          SettingsSwitch(
            isSubtitle: false,
            title: 'УЗКАРД Статус',
            value: isEnabledUzcard,
            onChanged: (value) async {
              await Pref.setBool(PrefKeys.isUzcardEnabled, value);
              setState(() {});
            },
          ),
          SizedBox(
            height: SizeConfig.v * 3,
          ),
          isEnabledHumo || isEnabledUzcard
              ? SettingsSwitch(
                  isSubtitle: false,
                  title: "${loc.soni} 2x",
                  value: doubleReceipt,
                  onChanged: (value) async {
                    await Pref.setBool(PrefKeys.doubleHumoReceipt, value);
                    setState(() {});
                  },
                )
              : const SizedBox(),
          SizedBox(
            height: SizeConfig.v * 3,
          ),
          isEnabledHumo || isEnabledUzcard
              ? DefaultButton(
                  height: 8.5,
                  text: 'Меню кассира',
                  isButtonEnabled: true,
                  onPress: () {
                    terminalMenu(context);
                  },
                )
              : const SizedBox(),
          SizedBox(
            height: SizeConfig.v * 3,
          ),
          isEnabledHumo || isEnabledUzcard
              ? DefaultButton(
                  height: 8.5,
                  text: 'Баланс',
                  isButtonEnabled: true,
                  onPress: () {
                    balance(context);
                  },
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  void terminalMenu(BuildContext context) async {
    const fs = fl.LocalFileSystem();
    final shell = Shell();
    await shell.startAndReadAsString(
      'C:/Arcus2/CommandLineTool/bin/CommandLineTool.exe',
      // arguments: ['/o1', '/a$summaAsString', '/c860'], //tolov
      // arguments: ['/o25'], //balance
      arguments: ['/o98'], //kassa smena
    ).then(
      (value) async {
        var reciptDirectory = fs.directory('C:\\Arcus2\\cheq.out');
        final file2 = File(reciptDirectory.path);
        var data2 = await file2.readAsBytes();
        String asString2 = windows1251.decode(data2);
        await PrintingMethods.printHumoRecipts(asString2.toString());
      },
    ).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(mySnackBar(context, msg: error.info));
    });
  }

  void balance(BuildContext context) async {
    const fs = fl.LocalFileSystem();
    final shell = Shell();
    await shell.startAndReadAsString(
      'C:/Arcus2/CommandLineTool/bin/CommandLineTool.exe',
      // arguments: ['/o1', '/a$summaAsString', '/c860'], //tolov
      arguments: ['/o25'], //balance
      // arguments: ['/o98'], //kassa smena
    ).then(
      (value) async {
        var reciptDirectory = fs.directory('C:\\Arcus2\\cheq.out');
        final file2 = File(reciptDirectory.path);
        var data2 = await file2.readAsBytes();
        String asString2 = windows1251.decode(data2);
        await PrintingMethods.printHumoRecipts(asString2.toString());
      },
    ).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(mySnackBar(context, msg: error.info));
    });
  }
}

/*
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../components/settings_switch.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

class HumoContent extends StatefulWidget {
  const HumoContent({Key? key}) : super(key: key);

  @override
  State<HumoContent> createState() => _HumoContentState();
}

class _HumoContentState extends State<HumoContent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isEnabled = Pref.getBool(PrefKeys.isHumoEnabled, false);

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.h * 10,
        vertical: SizeConfig.v * 3,
      ),
      child: SettingsSwitch(
        title: 'HUMO',
        value: isEnabled,
        onChanged: (value) async {
          await Pref.setBool(PrefKeys.isHumoEnabled, value);
          setState(() {});
        },
      ),
    );
  }
}
*/
