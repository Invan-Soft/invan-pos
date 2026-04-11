import 'package:flutter/material.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';


class GetEmployeesProvider extends ChangeNotifier {
  bool _isDownloading = false;


  bool get getIsDownloading => _isDownloading;


  Future<void> startGetEmployees() async {
    _isDownloading = true;
    notifyListeners();

    HttpResult httpResult = await EmployeesApi.findEmployees();

    if (httpResult.isSuccess) {
      
      EmployeesFindResponse e =
          EmployeesFindResponse.fromJson(httpResult.result);
      final box = HiveBoxes.getEmployees();

      await box.clear();

      final employeeList = e.data ?? <Employee>[];
      if (employeeList.isNotEmpty) await box.addAll(employeeList);

      _isDownloading = false;
      notifyListeners();
    }
  }
}
