// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:intl/intl.dart';
import 'package:invan2/changes/bloc/supplier_search/supplier_search_bloc.dart';
import 'package:invan2/changes/services/web_socket_service/category/categories_ws_service.dart';
import 'package:invan2/changes/services/web_socket_service/discount/discount_ws_service.dart';
import 'package:invan2/app/theme_bloc/theme_mode_bloc.dart';
import 'package:invan2/app/wrapper/wrapper.dart';
import 'package:invan2/changes/bloc/network/network_bloc.dart';
import 'package:invan2/changes/providers/language_provider.dart';
import 'package:invan2/changes/providers/provider_of_with_cash_dialog.dart';
import 'package:invan2/changes/providers/settings_provider.dart';
import 'package:invan2/changes/providers/shift_closed_provider.dart';
import 'package:invan2/changes/services/customer_service.dart';
import 'package:invan2/changes/services/file_receipt_service.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/features/authentication/bloc/auth_bloc/auth_bloc.dart';
import 'package:invan2/features/checks/features/checks_app_bar/bloc/usr_bloc.dart';
import 'package:invan2/features/checks/features/checks_list/bloc/check_f_bloc.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart';
import 'package:invan2/features/drawer/features/update/sync/bloc/sync_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/product_search/dialog/bloc/serch_dialog_bloc.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/add_client/bloc/addclient_bloc.dart';
import 'package:provider/provider.dart';
import '../app_navigation.dart';
import '../changes/bloc/client_search/client_search_bloc.dart';
import '../changes/bloc/payme/payme_bloc.dart';
import '../changes/dialogs/creat_product/bloc/get_mxik_from_soliq_bloc.dart';
import '../changes/providers/ordering_provider_4.dart';
import '../changes/services/shift_api_4.dart';
import '../changes/services/web_socket_service/web_socket_options/bloc/connect_bloc.dart';
import '../changes/services/web_socket_service/web_socket_options/ws_service.dart';
import '../features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart';
import '../features/checks/features/check_view/bloc/re_update_bloc.dart';
import '../features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import '../features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import '../features/home/features/home_orders/order_list/bloc/order_items_select_bloc.dart';
import '../features/payment/right/complete_button/complete_bloc/comlete_bloc.dart';
import '../features/payment/right/complete_button/pre_complete_bloc/per_comlete_bloc.dart';
import '../features/payment/right/dilogs/add_client/group_type_bloc/group_type_bloc.dart';
import '../features/payment/right/dilogs/click/bloc/click_bloc.dart';
import '../features/payment/right/dilogs/paynet/bloc/paynet_bloc.dart';
import '../features/payment/right/dilogs/transfer/set_driver/set_driver_bloc.dart';
import '../idle_service.dart';
import '../objectbox.g.dart';
import '../utils/constants/pref_keys.dart';
import '../utils/helpers/prefs.dart';
import '../utils/themes.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  String startTime = Pref.getString(PrefKeys.appClosedTime,
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
  String endTime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc());

  @override
  void initState() {
    _checkFirstTime();
    super.initState();
  }

  // @override
  // void didChangeDependencies()async {
  //   // String currentVersion = await getCurrentVersion();
  //   // print(currentVersion);
  //   super.didChangeDependencies();
  // }

  @override
  void dispose() {
    _hiveClose();
    super.dispose();
  }

  Future<void> _checkFirstTime() async {
    if (Pref.getBool(PrefKeys.isFirstTime, true)) {
      if (kDebugMode) {
        print("Foydalanuvchi ilk bor kirdi!");
      }
      startTime = Pref.getString(PrefKeys.appClosedTime,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
      endTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc());
      await Pref.setBool(PrefKeys.isFirstTime, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Box<ShiftModelHive> box = HiveBoxes.getShifts();
    // box.clear();
    // print(startTime);
    // print(endTime);
    // print('ggggggggggggggggggggggggggggggggggg');
    // print(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
    // print(Pref.getString(PrefKeys.token, "not initialized"));
    // print(Pref.getString(PrefKeys.storeId, "not initialized"));
    // print(Pref.getString(PrefKeys.activatedPosId, "not initialized"));
    // print(Pref.getString(PrefKeys.acceptService, "not initialized"));
    // print(Pref.getString(PrefKeys.userId, "not initialized"));
    List<ReceiptModel4> checksList =
        MyObjectbox.saleStore.box<ReceiptModel4>().getAll().reversed.toList();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PagingProvider()),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(
            Pref.getInt(PrefKeys.language, 0),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OpenShiftProvider(
              isShiftOpened: Pref.getBool(PrefKeys.shiftsOpened, false)),
        ),
        ChangeNotifierProvider(create: (_) => LocalCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ReturnProvider()),
        ChangeNotifierProvider(create: (_) => OrderingProvider4()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
        ChangeNotifierProvider(create: (_) => WithCashProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ShiftClosedProvider()),
      ],
      builder: (context, child) {
        final LanguageProvider languageProvider =
            Provider.of<LanguageProvider>(context);
        bool autoSyncActiv = Pref.getBool(PrefKeys.isAutoSyncActive, false);
        bool orgINITIALIZED = Pref.getBool(PrefKeys.orgINITIALIZED, false);

        return InAppNotification(
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => ThemeModeBloc()),
              BlocProvider(create: (_) => NetworkBloc()),
              BlocProvider(create: (_) => PaymeBloc()),
              BlocProvider(create: (_) => ClientBloc()),
              BlocProvider(create: (_) => GetMxikFromSoliqBloc()),
              BlocProvider(create: (_) => SyncBloc()),
              BlocProvider(create: (_) => CmtBBloc()),
              BlocProvider(create: (context) => GroupTypeBloc()),
              BlocProvider(create: (_) => AuthBloc()),
              BlocProvider(create: (_) => AccessBloc(0)),
              BlocProvider(create: (_) => BlBloc()),
              BlocProvider(create: (_) => PreCmtBBloc()),
              BlocProvider(create: (_) => ReUpdateBloc()),
              BlocProvider(create: (_) => ClickBloc()),
              BlocProvider(create: (_) => PaynetBloc()),
              BlocProvider(create: (_) => ReturnBloc()),
              BlocProvider(create: (_) => CheckFBloc(checksList: checksList)),
              BlocProvider(create: (_) => UsrBloc()),
              BlocProvider(create: (_) => AddClientBloc()),
              BlocProvider(create: (_) => OrderItemsSelectBloc()),
              BlocProvider(create: (_) => SDbloc()),
              BlocProvider(create: (_) => SetDriverBloc()),
              BlocProvider(create: (_) => ConnectBloc()),
              BlocProvider(create: (_) => PreOfdBloc()),
              BlocProvider(create: (_) => SupplierBloc()),

            ],
            child: BlocConsumer<NetworkBloc, NetworkState>(
              listener: (ctx, state) async {
                if (state is NetworkFailure) {
                  startTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(
                      DateTime.now().toUtc().subtract(Duration(minutes: 2)));
                  await WsService.disconnect(context);
                }
                if (state is NetworkSuccess) {
                  endTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(DateTime.now().toUtc());
                  FileService.logsToTxt();
                  FileService.receiptsToJson();
                  CustomerSupportService.sendUnsendMessages();
                  ClickService.sendUnsentReceipts();

                  /// Check the shift ///
                  ///
                  {
                    if (_isBoxEmpty()) {
                      //////////////   CLOSE SHIFT   ///////////////
                      if (Pref.getString(PrefKeys.closedDate, '').isNotEmpty &&
                          Pref.getInt(PrefKeys.closedCount, 0) == 1) {
                        if (kDebugMode) {
                          print('CLOSE SHIFT');
                        }
                        await ShiftApi4.closeShift();
                        await Pref.setInt(PrefKeys.closedCount, 0);
                        await Pref.setString(PrefKeys.closedDate, '');
                      }
                      //////////////   OPEN SHIFT   ///////////////
                      if (Pref.getString(PrefKeys.openedDate, '').isNotEmpty &&
                          Pref.getInt(PrefKeys.openedCount, 0) == 1) {
                        if (kDebugMode) {
                          print('OPEN SHIFT');
                        }
                        await ShiftApi4.openShift();
                        await Pref.setInt(PrefKeys.openedCount, 0);
                        await Pref.setString(PrefKeys.openedDate, '');
                      }
                    }
                  }

                  {
                    /// Get Notifications ///
                    ///
                    await CategoriesWsService.getReceivedWS(
                        mounted, context, startTime, endTime);
                    await DiscountWsService.getReceivedWS(
                        mounted, context, startTime, endTime);

                    /// Update every minute ///
                    ///
                    {
                      DateTime endTimer =
                          DateFormat('yyyy-MM-dd HH:mm:ss').parseUtc(endTime);
                      int endTimeMillis = endTimer.millisecondsSinceEpoch;
                      await Pref.setInt(PrefKeys.lastSyncTime, endTimeMillis);

                      if (autoSyncActiv && orgINITIALIZED) {
                        Provider.of<UpdateProvider>(context, listen: false)
                            .autoUpdate(context, mounted);
                      }
                    }
                  }
                }
              },
              builder: (ctx, state) {
                return BlocBuilder<ThemeModeBloc, ThemeModeState>(
                  builder: (context, state) {
                    return MaterialApp(
                      builder: (context, child) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          IdleService().start(context);
                        });

                        return child ?? const SizedBox.shrink();
                      },
                      navigatorKey: AppNavigation.navigatorKey,
                      title: 'InVan POS',
                      debugShowCheckedModeBanner: false,
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      locale: AppLocalizations
                          .supportedLocales[languageProvider.getLanguage],
                      theme: state.isDark
                          ? MyThemes.darkThemeData(context)
                          : MyThemes.lightThemeData(context),
                      home: const Wrapper(),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _hiveClose() async => await Hive.close();

  static bool _isBoxEmpty() {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final query = box
        .query(ReceiptModel4_.uploaded.equals(false) &
            ReceiptModel4_.rejected.equals(false))
        .build();
    final isEmpty = query.find().isEmpty;
    query.close();
    return isEmpty;
  }
}

/*{
                    Future.delayed(Duration(seconds: 5), () async {
                      if (kDebugMode) {
                        print(isWebSocketConnected);
                        print('===================================');
                      }
                      if (!isWebSocketConnected) {
                        await CategoriesWsService.getReceivedWS(
                            mounted, context, startTime, endTime);
                        await ProductsWsService.getReceivedWS(
                            mounted, context, startTime, endTime);
                        await DiscountWsService.getReceivedWS(
                            mounted, context, startTime, endTime);

                        {
                          DateTime endTimer = DateFormat('yyyy-MM-dd HH:mm:ss')
                              .parseUtc(endTime);
                          int endTimeMillis = endTimer.millisecondsSinceEpoch;
                          await Pref.setInt(
                              PrefKeys.lastSyncTime, endTimeMillis);
                        }

                        await WsService.connectWebSocket(mounted, context);
                        isWebSocketConnected = true;
                      }
                    });
                  }*/
