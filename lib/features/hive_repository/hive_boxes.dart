import 'package:hive/hive.dart';
import 'package:invan2/changes/dialogs/creat_product/model/mes_vat_unit_model/mes_unit.dart';
import 'package:invan2/changes/models/feedback_model.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_discounts/get_discounts.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import '../../changes/models/product/soliq_mxik_model.dart';

class HiveBoxes {
  static Future<void> clearAllBoxes() async {
    await Future.wait([
      getEmployees().clear(),
      getPrinters().clear(),
      getCategories().clear(),
      getLocalCategories().clear(),
      getShifts().clear(),
      getProducts().clear(),
      getFeedBacks().clear(),
      prefBox().clear(),
      mesUnitBox().clear(),
      vatUnitBox().clear(),
      getDiscounts().clear()
    ]);
  }

  static Box<DiscountItem> getDiscounts() =>
      Hive.box<DiscountItem>(HiveBoxNames.discounts);

  static Box<Employee> getEmployees() =>
      Hive.box<Employee>(HiveBoxNames.employees);

  static Box<RoleWithPermission> getRoleEmployeesWithId() =>
      Hive.box<RoleWithPermission>(HiveBoxNames.employeesRolesWithId);

  static Employee? get getCurrentEmployee {
    final cashierId = Pref.getString(PrefKeys.cashierId, "not initialized");
    final employeeBox = HiveBoxes.getEmployees();
    final list = employeeBox.values.toList().cast<Employee>();
    Employee? employee;
    for (var e in list) {
      if (e.user?.id == cashierId) {
        employee = e;
      }
    }
    return employee;
  }

  // static Employee? get getCurrentEmployee {
  //   final cashierId = Pref.getString(PrefKeys.cashierId, "not initialized");
  //   final employeeBox = HiveBoxes.getRoleEmployeesWithId();
  //   final list = employeeBox.values.toList().cast<RolePermissionsWithIDModel>();
  //   Employee? employee;
  //   for (var e in list) {
  //     if (e.id == cashierId) {
  //       employee = e;
  //     }
  //   }
  //   return employee;
  // }

  static Box<PrinterModel> getPrinters() =>
      Hive.box<PrinterModel>(HiveBoxNames.printers);

  static Box<CategoryData> getCategories() =>
      Hive.box<CategoryData>(HiveBoxNames.categories);

  static Box<LocalCategoryModel> getLocalCategories() =>
      Hive.box<LocalCategoryModel>(HiveBoxNames.localcategories);

  static Box<ItemModel> getProducts() =>
      Hive.box<ItemModel>(HiveBoxNames.items);

  static Box<LogModel> getLogs() => Hive.box<LogModel>(HiveBoxNames.logs);

  static Box<LogModel> getTelegramLogs() =>
      Hive.box<LogModel>(HiveBoxNames.tglogs);

  static Box<ShiftModelHive> getShifts() =>
      Hive.box<ShiftModelHive>(HiveBoxNames.shifts);

  static Box<FeedbackModel> getFeedBacks() =>
      Hive.box<FeedbackModel>(HiveBoxNames.feedbacks);

  static Box<dynamic> prefBox() => Hive.box(HiveBoxNames.prefs);

  // static Box<VatUnitModel> vatUnitBox() =>
  //     Hive.box<VatUnitModel>(HiveBoxNames.vatUnit);
  //
  // static Box<MesUnitModel> mesUnitBox() {
  //   return Hive.box<MesUnitModel>(HiveBoxNames.mesUnit);
  // }
  static Box<SoliqMxikModel> markingProductsBox() {
    return Hive.box<SoliqMxikModel>(HiveBoxNames.markingProducts);
  }
  static Box<VatUnitModel> vatUnitBox() {
    if (!Hive.isBoxOpen(HiveBoxNames.vatUnit)) {
      Hive.openBox<VatUnitModel>(HiveBoxNames.vatUnit);
    }
    return Hive.box<VatUnitModel>(HiveBoxNames.vatUnit);
  }

  static Box<MesUnitModel> mesUnitBox() {
    if (!Hive.isBoxOpen(HiveBoxNames.mesUnit)) {
      Hive.openBox<MesUnitModel>(HiveBoxNames.mesUnit);
    }
    return Hive.box<MesUnitModel>(HiveBoxNames.mesUnit);
  }
}

class HiveBoxNames {
  static const String employees = 'employees';
  static const String employeesRolesWithId = 'employeesRolesWithId';
  static const String printers = 'printers';
  static const String categories = 'categories';
  static const String localcategories = 'local_categories';
  static const String items = 'items';
  static const String tglogs = 'tg_logs';
  static const String shifts = 'shifts';
  static const String feedbacks = 'feedbacks';
  static const String prefs = 'prefs';
  static const String logs = 'logs';
  static const String vatUnit = 'vatunit';
  static const String mesUnit = 'mesunit';
  static const String discounts = 'discounts';
  static const String markingProducts = 'marking_products';

}
