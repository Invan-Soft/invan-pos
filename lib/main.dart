import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app/app.dart';
import 'package:invan2/changes/models/epay/e_pay_model.dart';
import 'package:invan2/changes/models/feedback_model.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/models/product/soliq_mxik_model.dart';
import 'package:invan2/changes/models/receipt/receipt_model.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/changes/providers/settings_provider.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/get_discounts/model/discounts_response.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invan2/features/home/bloc/invoice/invoice_bloc.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:invan2/features/features.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'changes/dialogs/creat_product/model/mes_vat_unit_model/mes_unit.dart';
import 'changes/services/log_service.dart';
import 'features/home/bloc/home_bloc/home_bloc.dart';

class MyWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    if (kDebugMode) {
      print("Foydalanuvchi ilovani yopdi!");
    }
    await Pref.setString(PrefKeys.appClosedTime,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
    await Pref.setBool(PrefKeys.isFirstTime, true);
    await hiveClose();
    await windowManager.destroy();
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {

    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  
  PackageInfo.fromPlatform();
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  windowManager.addListener(MyWindowListener());
  // await Prefs.init();
  await MyObjectbox.init();
  await _hiveInit();
  await hiveOpen();
  // birinchi kirishda ofd
  // await Pref.setBool(PrefKeys.withOFD, true);
  // Printer required
  // await Pref.setBool(PrefKeys.printerRequired, true);

  ///////////////////  Aliceni o'chirish /////////////////////
  if (kReleaseMode) {
    await Pref.setBool(PrefKeys.isDevAlice, true);
  } else {
    await Pref.setBool(PrefKeys.isDevAlice, true);
  }
  // await Pref.setBool(PrefKeys.isDevAlice, false);
  ///////////////////  Aliceni o'chirish /////////////////////

  {
    await Pref.setInt(PrefKeys.autoSyncInterval, 1);
    await Pref.setBool(PrefKeys.isAutoSyncActive, true);
    await Pref.setBool(PrefKeys.orgINITIALIZED, true);
    await Pref.setInt(PrefKeys.selectedIntervalIndexOfAutoSync, 0);
  }

  await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
  await Pref.setBool(PrefKeys.debtClick, false);
  await Pref.setBool(PrefKeys.isSendToTelegram, true);

  await Pref.setString(
      PrefKeys.version, await LogService.getAppVersion() ?? '');
  await Pref.setBool(PrefKeys.withINCOM, false);

  try {
    await ItemsSingleton.storeProducts();
  } catch (e) {}

  // ClientsSingleton.init();
  CategorySingleton.init();
  await OrganizationSingleton.setOtherPayments();
  await SettingsInnerSingleton().intiDeviceData();

  runApp(
    MultiProvider(
      providers: [
        BlocProvider(create: (context) => HomeBloc()),
        BlocProvider(create: (context) => InvoiceBloc()),

      ],
      child: const App(),
    ),
  );
  doWhenWindowReady(() async {
    final win = appWindow;
    win.maximize();
    win.title = "InVan 2";
    win.show();
  });
}

Future<void> hiveClose() async {
  await Hive.close();
}

Future<void> _hiveInit() async {
  await Hive.initFlutter();
  Hive.registerAdapter(EmployeeAdapter()); // 0
  // Hive.registerAdapter(EmployeeUiLanguageAdapter()); // 1
  Hive.registerAdapter(EmployeeAccessAdapter()); // 2
  Hive.registerAdapter(PrinterModelAdapter()); // 5
  Hive.registerAdapter(CategoryDataAdapter()); // 9
  Hive.registerAdapter(LocalCategoryModelAdapter()); // 10
  Hive.registerAdapter(LocalCategoryItemModelAdapter()); // 22
  Hive.registerAdapter(ItemModelAdapter()); //23
  Hive.registerAdapter(ReceiptModelAdapter()); // 24
  Hive.registerAdapter(ParamsAdapter()); // 25
  Hive.registerAdapter(DiscountCardAdapter()); // 26
  Hive.registerAdapter(LogModelAdapter()); // 27
  // Hive.registerAdapter(PriceAdapter()); //29
  ////  PriceAdapter   ////
  Hive.registerAdapter(ShiftModelHiveAdapter()); // ShiftModelHive 30
  Hive.registerAdapter(CashDrawerHiveAdapter()); // CashDrawer 31
  Hive.registerAdapter(SalesSummaryHiveAdapter()); //  SalesSummary 32
  Hive.registerAdapter(PaysHiveAdapter()); // Pays 33
  Hive.registerAdapter(FeedbackModelAdapter()); // Pays 34
  Hive.registerAdapter(OrganizationModelAdapter()); // 35
  // Hive.registerAdapter(CashBackAdapter()); // 36
  Hive.registerAdapter(PaymentAdapter()); // 37
  Hive.registerAdapter(EPayModelAdapter()); // 38
  Hive.registerAdapter(EPayEnumAdapter()); // 39
  Hive.registerAdapter(EmployeeUserAdapter()); // 101
  Hive.registerAdapter(EmployeeRoleAdapter()); // 102
  Hive.registerAdapter(RoleWithPermissionAdapter()); //106
  Hive.registerAdapter(ModulesAdapter()); //107
  Hive.registerAdapter(SectionsAdapter()); //105
  Hive.registerAdapter(PermissionsAdapter()); //104
  Hive.registerAdapter(SubCategoryModelAdapter()); //108
  Hive.registerAdapter(ShopPricesAdapter()); //109
  Hive.registerAdapter(ShIDAdapter()); //110
  Hive.registerAdapter(ShopPriceTiersAdapter()); //123
  Hive.registerAdapter(CategoriesFromProductsAdapter()); //111
  Hive.registerAdapter(MeasurementUnitAdapter()); //112
  Hive.registerAdapter(VatAdapter()); //113
  Hive.registerAdapter(VatUnitModelAdapter()); //114
  Hive.registerAdapter(MesUnitModelAdapter()); //115
  Hive.registerAdapter(DiscountItemAdapter()); // 117
  Hive.registerAdapter(DiscountTypeAdapter()); // 118
  Hive.registerAdapter(DiscountGroupTypeAdapter()); // 119
  Hive.registerAdapter(DiscountSchedulesAdapter()); // 120
  Hive.registerAdapter(ProductIdsAdapter()); // 121
  Hive.registerAdapter(CategoryIdsAdapter()); // 122
  Hive.registerAdapter(CustomerGroupsAdapter()); // 124
  Hive.registerAdapter(ShopIdsAdapter()); // 125
  Hive.registerAdapter(BuyXGetYAdapter()); // 126
  Hive.registerAdapter(ProductsToBuyAdapter()); // 127
  Hive.registerAdapter(ProductsToGetAdapter()); // 128
  Hive.registerAdapter(GiftsAdapter()); // 129
  Hive.registerAdapter(BuyXGetXAdapter()); //30
  Hive.registerAdapter(SoliqMxikModelAdapter()); //31


  /////////////////////////
}

Future<void> hiveOpen() async {
  if (Platform.isWindows) {
    const basePath = r"C:\ProgramData\InVanPos2\cache\";
    await Future.wait([
      Hive.openBox<FeedbackModel>("feedbacks", path: "${basePath}feedbacks\\"),
      Hive.openBox<Employee>("employees", path: "${basePath}employee\\"),
      Hive.openBox<PrinterModel>("printers", path: "${basePath}printers\\"),
      Hive.openBox<CategoryData>("categories", path: "${basePath}category\\"),
      Hive.openBox<LocalCategoryModel>("local_categories",
          path: "${basePath}local_category\\"),
      Hive.openBox<ItemModel>("items", path: "${basePath}items\\"),
      Hive.openBox<LogModel>("logs", path: "${basePath}logs\\"),
      Hive.openBox<LogModel>("tg_logs", path: "${basePath}tg_logs\\"),
      Hive.openBox<ShiftModelHive>("shifts", path: "${basePath}shifts\\"),
      Hive.openBox<dynamic>("prefs", path: "${basePath}prefs\\"),
      Hive.openBox<EPayModel>('epay', path: "${basePath}epay\\"),
      Hive.openBox<VatUnitModel>('vatunit', path: "${basePath}vatunit\\"),
      Hive.openBox<MesUnitModel>('mesunit', path: "${basePath}mesunit\\"),
      Hive.openBox<DiscountItem>("discounts", path: "${basePath}discounts\\"),
      Hive.openBox<Payment>("other_payments",
          path: "${basePath}other_payments\\"),
      Hive.openBox<SoliqMxikModel>('marking_products', path: "${basePath}marking_products\\"),
    ]);
  } else {
    Directory directory = await pp.getApplicationSupportDirectory();
    final basePath = '${directory.path}/pos';
    await Hive.openBox<FeedbackModel>("feedbacks", path: "$basePath/feedbacks");
    await Hive.openBox<Employee>("employees", path: "${basePath}employee");
    await Hive.openBox<PrinterModel>("printers", path: "${basePath}printers");
    await Hive.openBox<CategoryData>("categories", path: "${basePath}category");
    await Hive.openBox<LocalCategoryModel>("local_categories",
        path: "$basePath/local_category");
    await Hive.openBox<ItemModel>("items", path: "$basePath/items");
    await Hive.openBox<LogModel>("logs", path: "$basePath/logs");
    await Hive.openBox<LogModel>("tg_logs", path: "$basePath/tg_logs");
    // await Hive.openBox<ShiftModelHive>("shifts");
    await Hive.openBox<ShiftModelHive>("shifts", path: "$basePath/shifts");
    await Hive.openBox<dynamic>("prefs", path: "$basePath/prefs");
    await Hive.openBox<EPayModel>('epay', path: "$basePath/epay");
    await Hive.openBox<VatUnitModel>('vatunit', path: "$basePath/vatunit");
    await Hive.openBox<MesUnitModel>('mesunit', path: "$basePath/mesunit");
    await Hive.openBox<DiscountItem>("discounts", path: "${basePath}discounts");
    await Hive.openBox<Payment>("other_payments",
        path: "$basePath/other_payments");
    await Hive.openBox<SoliqMxikModel>('marking_products', path: "$basePath/marking_products");
  }
}
/**
 * requirements of simple version
 * 1. switch the _ofd, _simple to _simple
 * 2. parol 4lik
 *     - change in pin_bloc page if pin.lengt 6 to 4
 *     - comment two line on lock_dots page
 */

/// flutter packages pub run build_runner watch --use-polling-watcher --delete-conflicting-outputs
/// 7773014999814534249960512649993255599652
///   flutter pub run easy_localization:generate -S "assets/translations" -O "lib/translations" -o "locale_keys.g.dart" -f keys
///

/// git checkout master
/// git reset --hard dev
/// git push origin master --force
