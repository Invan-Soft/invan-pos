import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/themes.dart';

import '../../features/features.dart';
import '../../utils/l10n/app_localizations.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (_) => const LogsScreen());

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<LogModel> successLogs = [];
  List<LogModel> failedLogs = [];
  List<LogModel> unsentLogs = [];
  int _currnetPage = 0;
  late GlobalKey<ScaffoldState> _scaffoldKey;
  late ScrollController allController;
  late ScrollController successController;
  late ScrollController failedControllerr;
  late ScrollController unsentController;

  @override
  void initState() {
    _scaffoldKey = GlobalKey<ScaffoldState>();
    allController = ScrollController();
    successController = ScrollController();
    failedControllerr = ScrollController();
    unsentController = ScrollController();
    unsentLogs = HiveBoxes.getTelegramLogs().values.cast<LogModel>().toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Row(
            children: [
              const Text('LOGS'),
              const Spacer(),
              _setTab('ALL', 0),
              const SizedBox(width: 12.0),
              _setTab('SUCCESS', 1),
              const SizedBox(width: 12.0),
              _setTab('FAILED', 2),
              const SizedBox(width: 12.0),
              _setTab('UNSENT', 3),
              const Spacer(),
              ElevatedButton(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () async {
                  await showCupertinoDialog(
                    context: context,
                    builder: (context) {
                      return Theme(
                        data: ThemeData.dark(),
                        child: CupertinoAlertDialog(
                          title: Text(
                            loc.haqiqatan_ham_barcha_jurnallarni_ochirib_tashlamoqchimisiz,
                            style: MyThemes.txtStyle(
                                fontSize: 2,
                                color: Theme.of(context).canvasColor),
                          ),
                          actions: [
                            CupertinoButton(
                              child: Text(
                                loc.bekor_qilish,
                                style: MyThemes.txtStyle(
                                    fontSize: 2,
                                    color: Theme.of(context).canvasColor),
                              ),
                              onPressed: () => AppNavigation.pop(),
                            ),
                            CupertinoButton(
                              child: Text(
                                loc.ha,
                                style: MyThemes.txtStyle(
                                    fontSize: 2,
                                    color: Theme.of(context).canvasColor),
                              ),
                              onPressed: () async {
                                await HiveBoxes.getLogs().clear();
                                await HiveBoxes.getTelegramLogs().clear();

                                AppNavigation.pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  successLogs = [];
                  failedLogs = [];
                  unsentLogs = [];
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(),
                child: Text(loc.hammasini_tozalash),
              ),
            ],
          )),
      body: IndexedStack(index: _currnetPage, children: [
        _firstPage(allController),
        _showListt(successLogs.reversed.toList(), successController, "success"),
        _showListt(failedLogs.reversed.toList(), failedControllerr, 'fail'),
        _showListt(unsentLogs.reversed.toList(), unsentController, "unsent"),
      ]),
    );
  }

  Widget _setTab(String label, int index) => InkWell(
        onTap: () => setState(() => _currnetPage = index),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: _currnetPage == index
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        ),
      );

  ValueListenableBuilder<Box<LogModel>> _firstPage(
      ScrollController controller) {
    return ValueListenableBuilder(
      valueListenable: HiveBoxes.getLogs().listenable(),
      builder: (context, Box<LogModel> box, child) {
        List<LogModel> logs = box.values.toList().reversed.toList();
        successLogs.clear();
        failedLogs.clear();
        for (var log in logs) {
          if (log.type!) {
            successLogs.add(log);
          } else {
            failedLogs.add(log);
          }
        }

        if (logs.isEmpty) {
          return const Center(child: Text('EMPTY'));
        }

        return _showListt(logs.reversed.toList(), controller, "first");
      },
    );
  }

  Widget _showListt(
      List<LogModel> logs, ScrollController controller, String where) {
    return ListView.separated(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        LogModel log = logs[i];
        return ListTile(
          minLeadingWidth: 60,
          leading: _setText(
            "${(i - logs.length).abs()}). ${log.type! ? "SUCCESS" : "FAIL"}",
            size: 26,
            color: log.type! ? Colors.teal : Colors.red,
          ),
          title: _setText(log.dateTime.toString(), size: 12),
          subtitle: _setText(log.message.toString()
              // color: Colors.amber,
              ),
          trailing: _setText(log.file!),
        );
      },
    );
  }

  Text _setText(
    String text, {
    Color color = Colors.black,
    double size = 26.0,
  }) =>
      Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      );
}
