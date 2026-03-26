import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart' as hive;
import 'package:hive/hive.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart' as obj;
import 'package:path_provider/path_provider.dart' as pp;

class FileService {
  Future logToJson() async {
    final Directory directory = await pp.getApplicationDocumentsDirectory();
    final String path = directory.path;

  
    final File file = File('$path/hive_data.json');
    final hive.Box<LogModel> box = HiveBoxes.getLogs();

    List<Map> list = [];
    for (var log in box.values) {
      list.add(log.toJson());
    }
    return await file.writeAsString(jsonEncode(list));
  }

  static Future receiptsToJson() async {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final query = box.query(obj.ReceiptModel4_.uploaded.equals(false)).build();
    List<ReceiptModel4> receiptList = query.find();
    const directory = r"C:\ProgramData\InVanPos2\cache\";

    final File file = File('${directory}hive_data.json');

    List<Map> list = [];
    for (var receipt in receiptList) {
      list.add(receipt.toJson());
    }
    await file.writeAsString(jsonEncode(list));
  }

  static String getDate() {
    DateTime now = DateTime.now();
    String day = now.day.toString().padLeft(2, '0');
    String month = now.month.toString().padLeft(2, '0');
    return '$day$month${now.year}';
  }

  static logsToTxt() async {
    //  await hiveOpen();
    // final v = DateTime.now();
    Box<LogModel> box = HiveBoxes.getLogs();
    int weekTime =
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    List<LogModel> successlogs = box.values
        .cast<LogModel>()
        .where((e) =>
            e.type! && ((e.dateTime?.millisecondsSinceEpoch ?? 0) >= weekTime))
        .toList();
    List<LogModel> errorlogs = box.values
        .cast<LogModel>()
        .where((e) =>
            !e.type! && ((e.dateTime?.millisecondsSinceEpoch ?? 0) >= weekTime))
        .toList();
    const directory = r"C:\ProgramData\InVanPos2\cache\txtLogs\";
    final File errorFile = File('${directory}error_logs.txt');
    final File successFile = File('${directory}success_logs.txt');
    bool errorExists = await errorFile.exists();
    bool successExists = await errorFile.exists();
    if (!errorExists) {
      await errorFile.create(recursive: true);
    }
    if (!successExists) {
      await successFile.create(recursive: true);
    }
    int i = 0;  
    errorFile.openWrite().write("");
    successFile.openWrite().write("");

    await Future.delayed(const Duration(seconds: 60));

    errorFile.openWrite(mode: FileMode.append).writeAll(
          errorlogs
              .map((LogModel e) {
                i++;
                return e.logToTxt(i: i, log: e);
              })
              .toList()
              .reversed,
        );
    i = 0;

    successFile.openWrite(mode: FileMode.append).writeAll(
          successlogs
              .map((LogModel e) {
                i++;
                return e.logToTxt(i: i, log: e);
              })
              .toList()
              .reversed,
        );
  }
}
