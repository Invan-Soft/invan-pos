// ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/mxik_updates.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/product_price_edit_response.dart';
import 'package:invan2/changes/services/web_socket_service/urls/urls.dart';
import 'package:provider/provider.dart';

import '../../../../alice_service.dart';
import '../../../../features/features.dart';
import '../../../../features/get_products/singletons/items_singleton.dart';
import '../../../../features/get_products/soliq/tasnif_service.dart';
import '../../../../features/hive_repository/hive_boxes.dart';
import '../../../../utils/constants/constants.dart';
import '../../../../utils/helpers/helpers.dart';
import '../../../models/organization_model.dart';
import '../../../models/product/item_model.dart';
import '../../../providers/ordering_provider_4.dart';
import '../../../singletons/organization_singleton.dart';
import '../../api/result_http_model.dart';
import '../../get_items_service.dart';

class ProductsWsService {
  ProductsWsService._();

  /*static sendReceivedWS(List<String> ids) async {
    final token = Pref.getString(PrefKeys.token, 'not initialized');

    if (token.isEmpty || token == 'not initialized') {
      return;
    }

    final headers = <String, String>{
      "timezone": "-300",
      "Vary": "Origin",
      "Strict-Transport-Security": "Strict-Transport-Security",
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Authorization": "Bearer $token"
    };

    final body = jsonEncode({"ids": ids});

    http.Response response = await http
        .delete(
          Uri.parse("${Urls.baseNotificationUrl}notifications"),
          body: body,
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));
    alice.onHttpResponse(response);
    await Pref.setInt(
        PrefKeys.lastSyncTime, DateTime.now().millisecondsSinceEpoch);
    await Pref.setBool(PrefKeys.lastSyncTimeChanged, true);
  }*/

  static Future<void> getReceivedWS(bool mounted, BuildContext context,
      String startDate, String endDate) async {
   
    final token = Pref.getString(PrefKeys.token, 'not initialized');

    if (token.isEmpty || token == 'not initialized') {
      return;
    }

    String comId = Pref.getString(PrefKeys.orgID, "");
    final headers = <String, String>{
      "timezone": "-300",
      "Vary": "Origin",
      "Strict-Transport-Security": "Strict-Transport-Security",
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Authorization": "Bearer $token"
    };
    http.Response response = await http
        .get(
          Uri.parse(
              "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=1000&offset=1&type=1,2,3,0,6,13,20,21,40&is_read=false&start_date=$startDate&end_date=$endDate"),
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));
    await LogHelper.logRequest(
        method: "GET",
        path:
            "${Urls.baseNotificationUrl}notifications?company_id=$comId&limit=1000&offset=1&type=1,2,3,0,6,13,20,21,40&is_read=false&start_date=$startDate&end_date=$endDate",
        statusCode: response.statusCode,
        response: response.body);

    alice.onHttpResponse(response);
    if (kDebugMode) {
      print(
          '☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️ - Product  Get - ☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️☑️');
    }
    if (response.statusCode == 200) {
      if (jsonDecode(utf8.decode(response.bodyBytes))['notifications'] !=
          null) {
        List<String> deleteIds = [];
        List notification =
            jsonDecode(utf8.decode(response.bodyBytes))['notifications'];

        for (var ws in notification) {
    
          if (ws['id'] != null) {
            if (ws['type'] == 21) {
              await ItemsSingleton.deleteMxik(ws['data']['mxik_codes']);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 20) {
              await ItemsSingleton.editMxik(
                  MxikUpdates.fromJson(ws['data']).mxikCodes ?? []);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 13) {
              await ItemsSingleton.editItem(ProductPriceEdit.fromJson(ws));
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 0) {
              bool isSuccess = await import(context);
              if (isSuccess) {
                deleteIds.add(ws['id']);
              }
            }
            if (ws['type'] == 2) {
              ItemModel item = ItemModel.fromWebSocketJsonUpdate(ws['data']);
              if ((ws['data']['category_ids'] as List<dynamic>).isNotEmpty) {
                item.categories ??=
                    getCategories(ws['data']['category_ids'][0]);
              }
              await ItemsSingleton.putItems([item]);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 1) {
              ItemModel item = ItemModel.fromWebSocketJson(ws['data']);
              if ((ws['data']['category_ids'] as List<dynamic>).isNotEmpty) {
                item.categories ??=
                    getCategories(ws['data']['category_ids'][0]);
              }
              await ItemsSingleton.putItems([item]);
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 3) {
              if (ws['data']['ids'] != null) {
                // await ItemsSingleton.deleteProduct(
                //   ws['data']['ids'].cast<String?>());
                await ItemsSingleton.deleteProduct(
                  (ws['data']['ids'] as List<dynamic>)
                      .map((e) => e.toString())
                      .toList(),
                );
              }
              await ItemsSingleton.storeProducts();
              CategorySingleton.init();
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 6) {
              deleteIds.add(ws['id']);
            }
            if (ws['type'] == 40) {
              final data = ws['data'];
              final String name = data['name'];
              final bool isUsed = data['is_used'];
              final String id = data['id'];

              if (name == 'CLICK') {
                await Pref.setBool(PrefKeys.clickEnable, isUsed);
                await Pref.setString(PrefKeys.clickId, id);
              } else if (name == 'UZUM') {
                await Pref.setBool(PrefKeys.uzumEnable, isUsed);
                await Pref.setString(PrefKeys.uzumId, id);
              } else if (name == 'PAYME') {
                await Pref.setBool(PrefKeys.paymeEnable, isUsed);
                await Pref.setString(PrefKeys.paymeId, id);
              }

              final box = await Hive.openBox<Payment>('other_payments');
              final payments = box.values.toList();
              for (int i = 0; i < payments.length; i++) {
                if (payments[i].name == name) {
                  payments[i].isAdded = isUsed;
                  await box.putAt(i, payments[i]);
                  break;
                }
              }

              await OrganizationSingleton.setOtherPayments();
              if (mounted) {
                Provider.of<OrderingProvider4>(context, listen: false).notifyListeners();
              }
            }
          }
        }
        if (deleteIds.isNotEmpty) {
          // await sendReceivedWS(deleteIds);
          deleteIds = [];
        }
      }
    }
  }

  static Future<bool> import(BuildContext context) async {
    DateTime time = DateTime.now();
    List<ItemModel> allProducts = [];
    await TasnifService.setPackageCode();

    HttpResult httpResult = await OrdersService.getItems();

    if (httpResult.isSuccess) {
      try {
        var decodedJson = json.decode(httpResult.result);

        if (decodedJson is List) {
          List<ItemModel> i = List<ItemModel>.from(
            decodedJson.map((e) {
              return ItemModel.fromJson(e);
            }),
          ).toList();
          i = ItemsSingleton.addPackageCodeAndMxikCode(
            i,
            Pref.getString(PrefKeys.mxikCode, ''),
            Pref.getString(PrefKeys.packageCode, ''),
          );
          allProducts.addAll(i);
          i.clear();
        } else {
          return false;
        }
      } catch (e) {
        return false;
      }
    }

    await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
    if (allProducts.isNotEmpty) {
      await ItemsSingleton.clearAndPutItems(allProducts);
      CategorySingleton.init();
      await ItemsSingleton.storeProducts();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
      });
      allProducts.clear();
      return true;
    }
    return false;
  }

  static List<CategoriesFromProducts>? getCategories(dynamic message) {
    List<CategoriesFromProducts> categories = [];
    final Box<CategoryData> categoriesModel = HiveBoxes.getCategories();
    CategoryData categoryData = CategoryData();
    for (CategoryData c in categoriesModel.values.toList()) {
      if (c.id != null && c.id == message) {
        categoryData = c;
        break;
      }
    }
    categories.add(
        CategoriesFromProducts(id: categoryData.id, name: categoryData.name));
    if (categoryData.id == null || categoryData.id!.isEmpty) {
      return null;
    }
    return categories;
  }
}
