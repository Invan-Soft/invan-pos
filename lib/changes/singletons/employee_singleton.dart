import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

class EmployeeSingleton {
  const EmployeeSingleton._();
  static Future<void> clearAndPutAll(EmployeesFindResponse v) async {

    final box = HiveBoxes.getEmployees();
    await box.clear();
    await box.addAll(v.data ?? []);
    return;
  }
}
