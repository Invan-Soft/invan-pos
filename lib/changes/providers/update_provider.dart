import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:invan2/features/home/bloc/home_bloc/home_bloc.dart';
import 'package:invan2/utils/util_functions.dart';
import 'package:invan2/utils/utils.dart';
import 'package:flutter/material.dart';
import '../services/web_socket_service/category/categories_ws_service.dart';
import '../services/web_socket_service/discount/discount_ws_service.dart';
import '../services/web_socket_service/product/products_ws_service.dart';

class UpdateProvider extends ChangeNotifier {
  Future<void> autoUpdate(BuildContext context, bool mounted) async {
    int interval = Pref.getInt(PrefKeys.autoSyncInterval, 1000000000000000000);

    await Future.delayed(Duration(minutes: interval));
    do {
      await startPeriodicRequest(context, mounted);
      await Future.delayed(Duration(minutes: interval));
    } while (true);
  }

  Future<void> autoUpdate2(BuildContext context, bool mounted) async {
    await Future.delayed(Duration(minutes: 60));
    do {
      await startPeriodicRequest2(context, mounted);
      await Future.delayed(Duration(minutes: 60));
    } while (true);
  }

  Future<void> startPeriodicRequest(BuildContext context, bool mounted) async {
    int? lastSyncMillis = Pref.getInt(PrefKeys.lastSyncTime, 0);

    DateTime lastSyncTime =
        DateTime.fromMillisecondsSinceEpoch(lastSyncMillis, isUtc: true);
    DateTime minus30Sec = lastSyncTime.subtract(Duration(minutes: 5));
    String startTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(minus30Sec);

    String endTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc());

    if ((await Connectivity().checkConnectivity()) != ConnectivityResult.none &&
        mounted) {
      await ProductsWsService.getReceivedWS(
          mounted, context, startTime, endTime);

      DateTime endTimer = DateFormat('yyyy-MM-dd HH:mm:ss').parseUtc(endTime);
      int endTimeMillis = endTimer.millisecondsSinceEpoch;
      await Pref.setInt(PrefKeys.lastSyncTime, endTimeMillis);

      context.read<HomeBloc>().add(HomeSyncEvent());
    }
  }

  Future<void> startPeriodicRequest2(BuildContext context, bool mounted) async {
    String endTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc());

    String startTime = DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.now().toUtc().subtract(const Duration(minutes: 65)));

    if ((await Connectivity().checkConnectivity()) != ConnectivityResult.none &&
        mounted) {
      await CategoriesWsService.getReceivedWS(
          mounted, context, startTime, endTime);
      await ProductsWsService.getReceivedWS(
          mounted, context, startTime, endTime);
      await DiscountWsService.getReceivedWS(
          mounted, context, startTime, endTime);
    }
  }

  Future<String?> fullUpdateItems() async =>
      await UtilFunctions.fullUpdateProduct();

  Future<String?> fullUpdateEmployee() async =>
      await UtilFunctions.fullUpdateEmployee();
}
