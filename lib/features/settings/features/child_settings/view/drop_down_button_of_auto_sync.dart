import 'package:flutter/material.dart';
import 'package:invan2/changes/providers/language_provider.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

class DropdownOfAutoSync extends StatefulWidget {
  const DropdownOfAutoSync({Key? key}) : super(key: key);

  @override
  State<DropdownOfAutoSync> createState() => _DropdownOfAutoSyncState();
}

class _DropdownOfAutoSyncState extends State<DropdownOfAutoSync> {
  int selectedIndexx = Pref.getInt(PrefKeys.selectedIntervalIndexOfAutoSync, 0);

  @override
  void initState() {
    super.initState();
  }

  /*void startPeriodicRequest() {
    if (Pref.getBool(PrefKeys.isAutoSyncActive, false)) {
      Timer.periodic(
          Duration(minutes: Pref.getInt(PrefKeys.autoSyncInterval, 1)),
          (timer) async {
        String endTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc());
        String startTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(
            DateTime.now().toUtc().subtract(const Duration(minutes: 1)));
        lastTime = endTime;
        if (mounted) {
          await ProductsWsService.getReceivedWS(
              mounted, context, startTime, endTime);
          DateTime endTimer =
              DateFormat('yyyy-MM-dd HH:mm:ss').parseUtc(endTime);
          int endTimeMillis = endTimer.millisecondsSinceEpoch;
          await Pref.setInt(PrefKeys.lastSyncTime, endTimeMillis);
        }
      });
    }
  }*/

  @override
  Widget build(BuildContext context) {
    bool russian = Provider.of<LanguageProvider>(context).getLanguage == 0;

    List<List<dynamic>> variants = russian
        ? [
            ["1 минута", 1],
            ["10 минута", 10],
            ["30 минута", 30],
            ["1 час", 60],
            ["5 час", 300],
            ["Незачем", -1],
          ]
        : [
            ["1 minut", 1],
            ["10 minut", 10],
            ["30 minut", 30],
            ["1 soat", 60],
            ["5 soat", 300],
            ["Kerak emas", -1],
          ];
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 3.5),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.only(
              left: SizeConfig.v * 2.3,
              bottom: SizeConfig.v * 1.5,
              top: SizeConfig.v * 1.5,
              right: SizeConfig.v,
            ),
            // onTap: () {},
            title: PopupMenuButton<int>(
              color: Theme.of(context).colorScheme.background,
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      width: 2, color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(SizeConfig.v)),
              tooltip: loc.intervalni_tanlang,
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: SizeConfig.h * 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.auto_yangilanish,
                            style: MyThemes.txtStyle(
                                fontSize: 2.7,
                                color: Theme.of(context).canvasColor),
                          ),
                          Text(
                            "${Pref.getBool(PrefKeys.isAutoSyncActive, false) ? variants[selectedIndexx][0] : ""}",
                            style: MyThemes.txtStyle(
                              color: Theme.of(context).canvasColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).canvasColor,
                      size: SizeConfig.v * 5,
                    ),
                  ],
                ),
              ),
              onSelected: (v) {},
              itemBuilder: (_) {
                return List.generate(
                  variants.length,
                  (__) => PopupMenuItem<int>(
                    onTap: () async {
                      int element = variants[__][1];
                      if (element >= 1) {
                        await Pref.setInt(PrefKeys.autoSyncInterval, element);
                        await Pref.setBool(PrefKeys.isAutoSyncActive, true);
                        await Pref.setBool(PrefKeys.orgINITIALIZED, true);
                      } else {
                        await Pref.setInt(PrefKeys.autoSyncInterval, 1);
                        await Pref.setBool(PrefKeys.isAutoSyncActive, false);
                        await Pref.setBool(PrefKeys.orgINITIALIZED, false);
                      }
                      await Pref.setInt(
                          PrefKeys.selectedIntervalIndexOfAutoSync, __);
                      selectedIndexx = __;
                      setState(() {});
                    },
                    value: variants[selectedIndexx][1],
                    child: SizedBox(
                      width: SizeConfig.h * 10,
                      child: Text(
                        "   ${variants[__][0]}",
                        textAlign: TextAlign.start,
                        style: MyThemes.txtStyle(
                          color: Theme.of(context).canvasColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }
}
